import SwiftUI

// ─────────────────────────────────────────────────────────────
// Design tokens — ported 1:1 from the "ワリカン！" home-screen mock.
// Coral is the confirmed brand palette.
// ─────────────────────────────────────────────────────────────
enum Theme {
    // Brand
    static let primary = Color(hex: 0xFF6B6B)          // coral
    static let page    = Color(hex: 0xFFFCFB)          // warm off-white page
    static let wash    = Color(hex: 0xFF6B6B, alpha: 0.08)

    // Brand trio (history category tints)
    static let coralHex: UInt32 = 0xFF6B6B
    static let mintHex:  UInt32 = 0x34B27A
    static let skyHex:   UInt32 = 0x4D96FF
    static let coral = Color(hex: coralHex)
    static let mint  = Color(hex: mintHex)
    static let sky   = Color(hex: skyHex)

    // Neutrals
    static let ink  = Color(hex: 0x2B2A28)
    static let mute = Color(hex: 0x9C988F)
    static let line = Color(hex: 0x2B2A28, alpha: 0.07)
}

// ─────────────────────────────────────────────────────────────
// Typography — iOS's rounded system design keeps the friendly tone without
// bundling large custom font files in the application.
// ─────────────────────────────────────────────────────────────
enum Rounded {
    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Heaviest weight for display headings.
    static func pop(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
}

// ─────────────────────────────────────────────────────────────
// Color hex helper
// ─────────────────────────────────────────────────────────────
extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// Yen formatting with grouped thousands, matching toLocaleString('ja-JP').
func yen(_ n: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.groupingSeparator = ","
    return "¥" + (f.string(from: NSNumber(value: n)) ?? "\(n)")
}
