import SwiftUI

// ─────────────────────────────────────────────────────────────
// Domain models for the warikan (bill-split) flow.
// ─────────────────────────────────────────────────────────────

/// A person taking part in the split.
struct Member: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var color: Color

    var initial: String { name.isEmpty ? "?" : String(name.prefix(1)) }
}

/// A line item from the receipt.
struct ReceiptItem: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var price: Int
    var qty: Int
    var tone: Color
    var roundingUnit: Int = 1
    var payerID: UUID? = nil

    var total: Int { price * qty }
}

/// One person's final amount.
struct SplitResult: Identifiable {
    var id: UUID { member.id }
    let member: Member
    let amount: Int
}

// Avatar palette — brand trio + two harmonious extras (from the design).
enum Palette {
    static let avatars: [Color] = [
        Color(hex: 0xFF6B6B), // coral
        Color(hex: 0x34B27A), // mint
        Color(hex: 0x4D96FF), // sky
        Color(hex: 0x8B7BF0), // violet
        Color(hex: 0xF2994A), // orange
    ]
    static func avatar(_ i: Int) -> Color { avatars[i % avatars.count] }

    // Item icon-chip tones, cycled like the receipt screen.
    static let itemTones: [Color] = [Theme.coral, Theme.sky, Theme.mint, Color(hex: 0x8B7BF0), Color(hex: 0xF2994A)]
    static func itemTone(_ i: Int) -> Color { itemTones[i % itemTones.count] }
}
