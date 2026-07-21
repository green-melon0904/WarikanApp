import Vision
import UIKit

/// One parsed line from a receipt, editable before import.
struct ScanItem: Identifiable {
    let id = UUID()
    var name: String
    var price: Int          // 単価
    var qty: Int = 1
    var include: Bool = true

    var total: Int { price * qty }
}

// ─────────────────────────────────────────────────────────────
// ReceiptScanner — runs Vision text recognition (ja/en) over a
// receipt photo and heuristically extracts (item name, price) rows.
// ─────────────────────────────────────────────────────────────
enum ReceiptScanner {

    static func scan(_ image: UIImage, completion: @escaping ([ScanItem]) -> Void) {
        guard let cg = image.cgImage else { completion([]); return }

        let request = VNRecognizeTextRequest { req, _ in
            let obs = (req.results as? [VNRecognizedTextObservation]) ?? []
            let items = parse(obs)
            DispatchQueue.main.async { completion(items) }
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ja-JP", "en-US"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cg, orientation: cgOrientation(image.imageOrientation))
        DispatchQueue.global(qos: .userInitiated).async {
            do { try handler.perform([request]) }
            catch { DispatchQueue.main.async { completion([]) } }
        }
    }

    // ── Parsing ──

    // Lines containing these are totals/metadata, not purchasable items.
    private static let skip = [
        "合計", "小計", "計", "金額", "税", "消費税", "内税", "外税", "対象",
        "お預", "預り", "釣", "おつり", "現金", "クレジット", "カード",
        "ポイント", "point", "残高", "枚数", "点数", "個数",
        "領収", "レシート", "売上", "登録番号", "登録", "番号", "TEL", "電話",
        "住所", "店", "様", "円玉", "割引", "値引", "クーポン",
        "レジ", "責", "事業者", "営業", "年月日", "日時", "明細", "区分",
        "支払", "票", "利用", "会員", "伝票", "承認", "毎度", "ありがとう",
        "express", "american", "visa", "jcb", "丁目",
    ]

    /// Date / time / phone / registration-number patterns — never item lines.
    private static let junkPatterns = [
        "[0-9]{4}年", "[0-9]{1,2}月[0-9]{1,2}日", "[0-9]{1,2}:[0-9]{2}",
        "T[0-9]{8,}", "[0-9]{2,4}-[0-9]{2,4}-[0-9]{3,4}",
    ]

    private struct Tok { let text: String; let y: CGFloat; let x: CGFloat }
    private struct Row { let name: String; let marked: Int?; let rightPrice: Int?; let rightX: CGFloat; let qty: (unit: Int, count: Int)? }

    static func parse(_ obs: [VNRecognizedTextObservation]) -> [ScanItem] {
        let toks: [Tok] = obs.compactMap { o in
            guard let c = o.topCandidates(1).first else { return nil }
            let b = o.boundingBox
            return Tok(text: c.string, y: b.midY, x: b.midX)
        }
        guard !toks.isEmpty else { return [] }

        // Group tokens into rows by similar vertical position (Vision y is bottom-up).
        let sorted = toks.sorted { $0.y > $1.y }
        var rows: [[Tok]] = []
        let yTol: CGFloat = 0.014
        for t in sorted {
            if let ly = rows.last?.first?.y, abs(ly - t.y) < yTol {
                rows[rows.count - 1].append(t)
            } else {
                rows.append([t])
            }
        }

        // Flatten each token-row into a Line (keeping the rightmost token's x for
        // the price-column check), then fold "@単価 ×個数 ＊小計" detail lines into
        // the product-name line just above them, so multi-quantity items aren't
        // lost (the detail line carries no product name of its own).
        let rawLines: [Line] = rows.map { row in
            let ordered = row.sorted { $0.x < $1.x }
            let right = ordered.last
            return Line(text: ordered.map(\.text).joined(separator: " "),
                        rightToken: right?.text ?? "",
                        rightX: right?.x ?? 0)
        }
        let lines = mergeQuantityLines(rawLines)

        // Turn each merged line into a candidate, discarding obvious metadata.
        var candidates: [Row] = []
        for line in lines {
            if shouldSkip(line.text) { continue }
            let name = cleanName(line.text)
            guard isMeaningfulName(name) else { continue }
            candidates.append(Row(
                name: name,
                marked: markedPrice(line.text),
                rightPrice: extractPrice(line.rightToken),
                rightX: line.rightX,
                qty: extractQty(line.text)
            ))
        }

        // Pass 1 — prices with an explicit marker (¥ ￥ ＊ *). High precision:
        // junk like an address or register number never carries one.
        let marked = candidates.compactMap { c -> ScanItem? in
            guard let p = c.marked, valid(p) else { return nil }
            return item(name: c.name, marked: p, qty: c.qty)
        }
        if marked.count >= 2 { return marked }

        // Pass 2 — fallback for receipts without markers: take the rightmost
        // number, but only when it's a real right-aligned price column.
        return candidates.compactMap { c -> ScanItem? in
            if let p = c.marked, valid(p) { return item(name: c.name, marked: p, qty: c.qty) }
            guard let p = c.rightPrice, p >= 10, valid(p), c.rightX > 0.45 else { return nil }
            return item(name: c.name, marked: p, qty: c.qty)
        }
    }

    /// Builds a ScanItem, applying quantity (@単価 ×個数) when present.
    /// Stores the unit price + count so `total` (= price × qty) matches the
    /// receipt's line subtotal; falls back to the marked price at qty 1.
    private static func item(name: String, marked: Int, qty: (unit: Int, count: Int)?) -> ScanItem? {
        if let q = qty, q.count >= 2, valid(q.unit) {
            // Trust the explicit unit price; the marked value is usually the
            // subtotal (unit × count) which we reconstruct via `total`.
            return ScanItem(name: name, price: q.unit, qty: q.count)
        }
        return ScanItem(name: name, price: marked, qty: 1)
    }

    private struct Line { let text: String; let rightToken: String; let rightX: CGFloat }

    /// A "@単価 ×個数" quantity detail line carries no product name. Fold each one
    /// into the preceding name-bearing line so the item (and its count) survives.
    /// The merged line inherits the detail line's right token (its price column).
    private static func mergeQuantityLines(_ raw: [Line]) -> [Line] {
        var out: [Line] = []
        for line in raw {
            let isQtyDetail = extractQty(line.text) != nil
                && !isMeaningfulName(cleanName(line.text))
            if isQtyDetail, let last = out.last,
               markedPrice(last.text) == nil,            // previous line had no price yet
               isMeaningfulName(cleanName(last.text)) {   // …but did have a product name
                out[out.count - 1] = Line(text: last.text + " " + line.text,
                                          rightToken: line.rightToken,
                                          rightX: line.rightX)
            } else {
                out.append(line)
            }
        }
        return out
    }

    /// Extracts "@単価 ×個数" → (unit, count). Requires an explicit ×/x marker so a
    /// plain price like "298" never looks like a quantity.
    static func extractQty(_ s: String) -> (unit: Int, count: Int)? {
        let pattern = "[＠@]?[ 　]?([0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)[ 　]?[×xX][ 　]?([0-9]{1,3})"
        guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = s as NSString
        guard let m = re.firstMatch(in: s, range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges > 2 else { return nil }
        let unit = Int(ns.substring(with: m.range(at: 1)).replacingOccurrences(of: ",", with: ""))
        let count = Int(ns.substring(with: m.range(at: 2)))
        guard let u = unit, let c = count, c >= 1, c <= 999 else { return nil }
        return (u, c)
    }

    private static func valid(_ p: Int) -> Bool { p >= 1 && p <= 1_000_000 }

    /// A real item name has any Japanese character (so single-kanji foods like
    /// 卵・餅・茶 survive) or at least two latin letters — this still kills stray
    /// fragments like a lone "x" left over from a quantity line.
    private static func isMeaningfulName(_ s: String) -> Bool {
        if s.unicodeScalars.contains(where: isJapanese) { return true }
        return s.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count >= 2
    }

    private static func isJapanese(_ u: Unicode.Scalar) -> Bool {
        switch u.value {
        case 0x3040...0x30FF,   // hiragana + katakana
             0x4E00...0x9FFF,   // CJK ideographs (kanji)
             0xFF66...0xFF9D:   // half-width katakana
            return true
        default:
            return false
        }
    }

    private static func shouldSkip(_ s: String) -> Bool {
        if skip.contains(where: { s.localizedCaseInsensitiveContains($0) }) { return true }
        return junkPatterns.contains { p in
            s.range(of: p, options: .regularExpression) != nil
        }
    }

    /// Price that directly follows a currency / item marker (¥ ￥ ＊ *), rightmost wins.
    static func markedPrice(_ s: String) -> Int? {
        let pattern = "[¥￥＊*][ 　]?([0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)"
        guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = s as NSString
        let matches = re.matches(in: s, range: NSRange(location: 0, length: ns.length))
        guard let last = matches.last, last.numberOfRanges > 1 else { return nil }
        let token = ns.substring(with: last.range(at: 1)).replacingOccurrences(of: ",", with: "")
        return Int(token)
    }

    /// Rightmost number on the line (commas allowed) — typically the price.
    static func extractPrice(_ s: String) -> Int? {
        let pattern = "[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+"
        guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = s as NSString
        let matches = re.matches(in: s, range: NSRange(location: 0, length: ns.length))
        guard let last = matches.last else { return nil }
        let token = ns.substring(with: last.range).replacingOccurrences(of: ",", with: "")
        return Int(token)
    }

    /// Item name = the line with currency, digits and quantity markers stripped.
    static func cleanName(_ s: String) -> String {
        var t = s
        let patterns = [
            // full "単価 ×個数" quantity blocks first (e.g. "238x 2", "238 ×2")
            "[＠@]?[ 　]?[0-9]{1,3}(?:,[0-9]{3})*[ 　]?[×xX][ 　]?[0-9]+",
            "[¥￥＊]", "円", "[xX×*＊][0-9]+", "[0-9]{1,3}(?:,[0-9]{3})+", "[0-9]+",
            "[#＃*※＠@]", "\\([^)]*\\)", "（[^）]*）",
        ]
        for p in patterns {
            t = t.replacingOccurrences(of: p, with: " ", options: .regularExpression)
        }
        while t.contains("  ") { t = t.replacingOccurrences(of: "  ", with: " ") }
        return t.trimmingCharacters(in: CharacterSet(charactersIn: " 　・.-*/:：¥￥＊＠@"))
    }

    private static func cgOrientation(_ o: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch o {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
