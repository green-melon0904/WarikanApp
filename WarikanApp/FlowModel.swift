import SwiftUI

// Navigation routes pushed onto the NavigationStack.
enum Route: Hashable {
    case participants
    case receipt
    case assign
    case result
    case history
}

// ─────────────────────────────────────────────────────────────
// FlowModel — shared state across all screens + the split math.
// Seeded with the design's sample data so the flow is demoable
// end-to-end while remaining fully editable.
// ─────────────────────────────────────────────────────────────
final class FlowModel: ObservableObject {
    @Published var path: [Route] = []

    @Published var members: [Member] = []
    @Published var items: [ReceiptItem] = []
    /// itemID → set of memberIDs who share that item.
    @Published var assignments: [UUID: Set<UUID>] = [:]

    @Published var history: [HistoryItem] = [] {
        didSet { saveHistory() }
    }

    /// id of the split currently in progress, so its result is recorded once
    /// (and updated, not duplicated, if the user edits and returns).
    private var currentSplitID: UUID?

    /// UserDefaults key for this device/user's saved history.
    /// (v2: drops the old seeded sample data.)
    private let historyKey = "sakuwari.history.v2"

    init() {
        loadHistory()
    }

    // ── History persistence (per user, on-device) ──
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let saved = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            history = saved
        }
        // otherwise start empty — no sample data.
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    /// Remove a saved split from history (also persists the change).
    func removeHistory(_ item: HistoryItem) {
        history.removeAll { $0.id == item.id }
    }

    // ── Members ──
    func addMember(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        members.append(Member(name: trimmed, color: Palette.avatar(members.count)))
    }

    func removeMember(_ member: Member) {
        members.removeAll { $0.id == member.id }
        for key in assignments.keys { assignments[key]?.remove(member.id) }
    }

    // ── Items ──
    func addItem(name: String, price: Int, qty: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, price > 0, qty > 0 else { return }
        let idx = items.count
        let item = ReceiptItem(name: trimmed, price: price, qty: qty,
                               tone: Palette.itemTone(idx))
        items.append(item)
        assignments[item.id] = []
    }

    func removeItem(_ item: ReceiptItem) {
        items.removeAll { $0.id == item.id }
        assignments[item.id] = nil
    }

    var itemsTotal: Int { items.reduce(0) { $0 + $1.total } }

    // ── Assignment ──
    func isSelected(_ item: ReceiptItem, _ member: Member) -> Bool {
        assignments[item.id]?.contains(member.id) ?? false
    }

    func toggle(_ item: ReceiptItem, _ member: Member) {
        var set = assignments[item.id] ?? []
        if set.contains(member.id) {
            set.remove(member.id)
            if let idx = items.firstIndex(where: { $0.id == item.id }), items[idx].payerID == member.id {
                items[idx].payerID = nil
            }
        } else {
            set.insert(member.id)
        }
        assignments[item.id] = set
    }

    func selectedCount(_ item: ReceiptItem) -> Int { assignments[item.id]?.count ?? 0 }

    func isShareAll(_ item: ReceiptItem) -> Bool {
        !members.isEmpty && selectedCount(item) == members.count
    }

    func shareAll(_ item: ReceiptItem) {
        assignments[item.id] = Set(members.map(\.id))
    }

    /// Per-person amount preview for a single item (floor split).
    func perPerson(_ item: ReceiptItem) -> Int {
        let c = selectedCount(item)
        return c > 0 ? item.total / c : 0
    }

    // ── Calculation ──
    /// Splits each item among its members. Each member's share is floored to the
    /// item's rounding unit, and the remainder is absorbed by the item's payer
    /// (so the per-item sum always stays exact), then totals per member.
    func computeResults() -> [SplitResult] {
        var totals: [UUID: Int] = [:]
        for item in items {
            guard let ids = assignments[item.id], !ids.isEmpty else { continue }
            let ordered = members.filter { ids.contains($0.id) }
            guard !ordered.isEmpty else { continue }
            let unit  = max(1, item.roundingUnit)
            let payer = ordered.first { $0.id == item.payerID } ?? ordered.first!
            let base  = item.total / ordered.count
            var assigned = 0
            for m in ordered where m.id != payer.id {
                let share = (base / unit) * unit
                totals[m.id, default: 0] += share
                assigned += share
            }
            totals[payer.id, default: 0] += item.total - assigned
        }
        return members.map { SplitResult(member: $0, amount: totals[$0.id] ?? 0) }
    }

    /// The member who absorbs this item's rounding remainder: the selected
    /// payer if still part of the item's assignment, otherwise the first
    /// assigned member (default). Returns nil if nobody is assigned.
    func payer(for item: ReceiptItem) -> Member? {
        guard let ids = assignments[item.id], !ids.isEmpty else { return nil }
        let ordered = members.filter { ids.contains($0.id) }
        guard !ordered.isEmpty else { return nil }
        return ordered.first { $0.id == item.payerID } ?? ordered.first
    }

    /// Sets the rounding unit (1 / 10 / 100 yen) for a given item.
    func setRoundingUnit(_ item: ReceiptItem, _ unit: Int) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].roundingUnit = unit
    }

    /// Sets the member who absorbs this item's rounding remainder.
    func setPayer(_ item: ReceiptItem, _ id: UUID?) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].payerID = id
    }

    var resultsTotal: Int { computeResults().reduce(0) { $0 + $1.amount } }

    // ── Lifecycle ──
    func start() {
        currentSplitID = nil   // a brand-new split
        path = [.participants]
    }

    /// Saves the current split to history the moment the result screen is shown,
    /// so it's always recorded even if the user just closes the app afterwards.
    /// Called repeatedly (e.g. on every appear) but records/updates exactly one entry.
    func recordCurrentSplit() {
        let total = resultsTotal
        guard total > 0 else { return }

        let f = DateFormatter(); f.dateFormat = "MM/dd"
        let breakdown = computeResults().map { HistoryEntry(name: $0.member.name, amount: $0.amount) }
        let entry = HistoryItem(
            id: currentSplitID ?? UUID(),
            title: "割り勘", date: f.string(from: Date()),
            people: members.count, total: total,
            icon: CatIcon.utensils, toneHex: Theme.coralHex,
            breakdown: breakdown
        )

        if let id = currentSplitID, let idx = history.firstIndex(where: { $0.id == id }) {
            history[idx] = entry          // update the in-progress split's record
        } else {
            history.insert(entry, at: 0)  // first time we reach the result
            currentSplitID = entry.id
        }
    }

    /// Clears the worksheet and returns home (the split is already recorded).
    /// Members are cleared too, so the next split starts from an empty roster.
    func finishAndReset() {
        currentSplitID = nil
        members.removeAll()
        items.removeAll()
        assignments.removeAll()
        path = []
    }

    /// Plain-text summary for sharing.
    func shareText() -> String {
        let results = computeResults().filter { $0.amount > 0 }
        var lines = ["【サクワリ精算結果】"]
        for r in results { lines.append("\(r.member.name)：\(yen(r.amount))") }
        lines.append("合計：\(yen(resultsTotal))")
        return lines.joined(separator: "\n")
    }
}
