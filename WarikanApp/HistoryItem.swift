import SwiftUI

// One person's share within a saved split (name + amount), for the detail sheet.
struct HistoryEntry: Codable, Equatable {
    let name: String
    let amount: Int
}

// A finished split record shown under 「過去の精算」.
// Codable so it can be persisted per-user on the device (see FlowModel).
struct HistoryItem: Identifiable, Codable {
    var id = UUID()
    let title: String
    let date: String
    let people: Int
    let total: Int
    let icon: String      // SF Symbol name
    let toneHex: UInt32   // category tint, stored as hex so it's Codable
    // 誰がいくら（詳細シート用）。後から追加したので、旧データには無く nil になる。
    var breakdown: [HistoryEntry]? = nil

    var tone: Color { Color(hex: toneHex) }
    var perPerson: Int { Int((Double(total) / Double(people)).rounded()) }
}
