import SwiftUI

// ─────────────────────────────────────────────────────────────
// Shared building blocks used across the flow screens.
// ─────────────────────────────────────────────────────────────

/// The large rounded primary button (h:64, r:24) with soft shadow + inner shine.
struct PrimaryCTA: View {
    var title: String
    var leadingSystem: String? = nil
    var trailingSystem: String? = nil
    var color: Color = Theme.primary
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let s = leadingSystem {
                    Image(systemName: s).font(.system(size: 21, weight: .semibold))
                }
                Text(title).font(Rounded.font(19, .bold)).tracking(0.3)
                if let s = trailingSystem {
                    Image(systemName: s).font(.system(size: 20, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(color)
                    .shadow(color: color.opacity(0.35), radius: 13, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    .blendMode(.overlay)
            )
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0.45)
        .disabled(!enabled)
    }
}

/// Round 44pt back button — white circle, soft shadow, chevron.
struct BackButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: CatIcon.back)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white)
                    .shadow(color: Theme.ink.opacity(0.08), radius: 4, x: 0, y: 2))
        }
        .buttonStyle(.plain)
    }
}

/// Coloured initial avatar; vivid when selected, muted grey when not.
struct InitialAvatar: View {
    let initial: String
    var color: Color
    var size: CGFloat = 46
    var selected: Bool = true
    var showCheck: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle().fill(selected ? color : Theme.ink.opacity(0.06))
                Text(initial)
                    .font(Rounded.font(size * 0.40, .heavy))
                    .foregroundStyle(selected ? .white : Color(hex: 0xB6B2AA))
            }
            .frame(width: size, height: size)
            .shadow(color: selected ? color.opacity(0.30) : .clear, radius: 7, x: 0, y: 5)

            if showCheck && selected {
                ZStack {
                    Circle().fill(Color.white)
                        .shadow(color: Theme.ink.opacity(0.2), radius: 2, x: 0, y: 1)
                    Image(systemName: CatIcon.check)
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(color)
                }
                .frame(width: 19, height: 19)
                .offset(x: 3, y: 3)
            }
        }
    }
}

/// The soft coral radial wash used at the top of every screen.
struct TopWash: View {
    var height: CGFloat = 300
    var body: some View {
        RadialGradient(
            colors: [Theme.wash, .clear],
            center: UnitPoint(x: 0.5, y: -0.12),
            startRadius: 0, endRadius: height
        )
        .frame(height: height)
        .frame(maxWidth: .infinity, alignment: .top)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }
}

/// Small step badge ("STEP 1 / 3").
struct StepBadge: View {
    let step: Int
    var body: some View {
        Text("STEP \(step) / 3")
            .font(Rounded.font(12, .bold))
            .tracking(1)
            .foregroundStyle(Theme.primary)
    }
}
