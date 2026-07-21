import SwiftUI

// ─────────────────────────────────────────────────────────────
// Icons — no emoji anywhere (per spec). Distinctive marks (receipt,
// scan) are reproduced from the mock's SVG paths; category/UI marks
// use matching SF Symbols rendered as thin rounded line icons.
// ─────────────────────────────────────────────────────────────

/// Receipt mark — zig-zag top & bottom edge with three text lines.
/// Ported from: M4 3.2v17.6l2-1 2 1 … V3.2l-2 1 … Z  +  M8 8h8 / M8 12h8 / M8 16h5
struct ReceiptShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
        var path = Path()

        // outline
        path.move(to: p(4, 3.2))
        path.addLine(to: p(4, 20.8))
        let bottom: [(CGFloat, CGFloat)] = [(6,19.8),(8,20.8),(10,19.8),(12,20.8),(14,19.8),(16,20.8)]
        bottom.forEach { path.addLine(to: p($0.0, $0.1)) }
        path.addLine(to: p(16, 3.2))
        let top: [(CGFloat, CGFloat)] = [(14,4.2),(12,3.2),(10,4.2),(8,3.2),(6,4.2)]
        top.forEach { path.addLine(to: p($0.0, $0.1)) }
        path.closeSubpath()

        // text lines
        path.move(to: p(8, 8));  path.addLine(to: p(16, 8))
        path.move(to: p(8, 12)); path.addLine(to: p(16, 12))
        path.move(to: p(8, 16)); path.addLine(to: p(13, 16))
        return path
    }
}

/// Scan mark — four rounded corner brackets + a center scan line.
/// Ported from the four corner arcs + M7 12h10.
struct ScanShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
        var path = Path()
        let r: CGFloat = 2.5 * s

        // top-left
        path.move(to: p(3, 7))
        path.addLine(to: p(3, 5.5))
        path.addArc(center: p(5.5, 5.5), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        // top-right
        path.move(to: p(17, 3))
        path.addLine(to: p(18.5, 3))
        path.addArc(center: p(18.5, 5.5), radius: r, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        // bottom-right
        path.move(to: p(21, 17))
        path.addLine(to: p(21, 18.5))
        path.addArc(center: p(18.5, 18.5), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        // bottom-left
        path.move(to: p(7, 21))
        path.addLine(to: p(5.5, 21))
        path.addArc(center: p(5.5, 18.5), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        // center line
        path.move(to: p(7, 12)); path.addLine(to: p(17, 12))
        return path
    }
}

/// Stroke-icon wrapper giving the rounded caps/joins the mock uses.
struct StrokeIcon: View {
    enum Kind { case receipt, scan }
    let kind: Kind
    var size: CGFloat = 24
    var lineWidth: CGFloat = 2
    var color: Color = .white

    private var shape: AnyShape {
        switch kind {
        case .receipt: return AnyShape(ReceiptShape())
        case .scan:    return AnyShape(ScanShape())
        }
    }

    var body: some View {
        shape
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

// ─────────────────────────────────────────────────────────────
// Filled receipt mark — white body + tinted detail lines, matching the
// app icon. Centered within its frame (grid shifted so x spans 6…18).
// ─────────────────────────────────────────────────────────────
private struct ReceiptBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
        var path = Path()
        path.move(to: p(6, 3.2))
        path.addLine(to: p(6, 20.8))
        for q in [(8,19.8),(10,20.8),(12,19.8),(14,20.8),(16,19.8),(18,20.8)] {
            path.addLine(to: p(CGFloat(q.0), CGFloat(q.1)))
        }
        path.addLine(to: p(18, 3.2))
        for q in [(16,4.2),(14,3.2),(12,4.2),(10,3.2),(8,4.2)] {
            path.addLine(to: p(CGFloat(q.0), CGFloat(q.1)))
        }
        path.closeSubpath()
        return path
    }
}

private struct ReceiptLinesShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
        var path = Path()
        path.move(to: p(10, 8));  path.addLine(to: p(18, 8))
        path.move(to: p(10, 12)); path.addLine(to: p(18, 12))
        path.move(to: p(10, 16)); path.addLine(to: p(15, 16))
        return path
    }
}

/// Solid receipt mark used in the hero chip — reads stronger than a thin outline
/// and stays consistent with the app icon.
struct ReceiptMark: View {
    var size: CGFloat
    var bodyColor: Color = .white
    var lineColor: Color = Theme.primary

    var body: some View {
        ZStack {
            ReceiptBodyShape().fill(bodyColor)
            ReceiptLinesShape().stroke(
                lineColor,
                style: StrokeStyle(lineWidth: size * 0.052, lineCap: .round)
            )
        }
        .frame(width: size, height: size)
    }
}

/// Category / UI icons via SF Symbols, matched to the Lucide marks in the mock.
enum CatIcon {
    // category
    static let wine     = "wineglass"
    static let flame    = "flame"
    static let utensils = "fork.knife"
    static let coffee   = "cup.and.saucer"
    static let leaf     = "leaf"
    // ui
    static let users    = "person.2"
    static let chevron  = "chevron.right"
    static let back     = "chevron.left"
    static let xmark     = "xmark"
    static let plus     = "plus"
    static let minus    = "minus"
    static let arrow    = "arrow.right"
    static let camera   = "camera"
    static let photo    = "photo"
    static let pencil   = "pencil"
    static let check    = "checkmark"
    static let sparkle  = "sparkles"
    static let share    = "square.and.arrow.up"
}
