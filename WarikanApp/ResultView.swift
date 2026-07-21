import SwiftUI

// 画面⑤ 結果表示（精算完了！）
struct ResultView: View {
    @EnvironmentObject var flow: FlowModel

    private var results: [SplitResult] { flow.computeResults() }
    private var total: Int { results.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.page.ignoresSafeArea()
            TopWash(height: 280)
            Confetti().frame(height: 170).padding(.top, 50)

            VStack(spacing: 0) {
                header
                cards
                footer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .onAppear { flow.recordCurrentSplit() }
    }

    private var header: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().fill(Theme.primary)
                    .shadow(color: Theme.primary.opacity(0.36), radius: 12, x: 0, y: 10)
                Image(systemName: CatIcon.check)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
            }
            .frame(width: 66, height: 66)

            Text("精算完了！")
                .font(Rounded.font(30, .heavy)).foregroundStyle(Theme.ink)
                .padding(.top, 16)
            Text("おつかれさま。各自の金額が出たよ。")
                .font(Rounded.font(14, .medium)).foregroundStyle(Theme.mute)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
    }

    private var cards: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 11) {
                ForEach(results) { resultCard($0) }

                // total
                HStack {
                    Text("合計").font(Rounded.font(16, .bold)).foregroundStyle(Theme.ink)
                    Spacer()
                    Text(yen(total)).font(Rounded.font(28, .heavy)).foregroundStyle(Theme.primary)
                        .monospacedDigit()
                }
                .padding(.init(top: 16, leading: 20, bottom: 16, trailing: 20))
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.primary.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Theme.primary.opacity(0.18), lineWidth: 1.5))
                )
                .padding(.top, 5)
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 10)
        }
    }

    private func resultCard(_ r: SplitResult) -> some View {
        HStack(spacing: 14) {
            InitialAvatar(initial: r.member.initial, color: r.member.color, size: 48)
            Text(r.member.name).font(Rounded.font(17, .bold)).foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(yen(r.amount)).font(Rounded.font(30, .heavy)).foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
        .padding(.init(top: 14, leading: 18, bottom: 14, trailing: 18))
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Theme.ink.opacity(0.05), radius: 11, x: 0, y: 8)
        )
    }

    private var footer: some View {
        VStack(spacing: 4) {
            ShareLink(item: flow.shareText()) {
                HStack(spacing: 10) {
                    Image(systemName: CatIcon.share).font(.system(size: 20, weight: .semibold))
                    Text("LINEでシェア").font(Rounded.font(19, .bold)).tracking(0.3)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Theme.mint)
                        .shadow(color: Theme.mint.opacity(0.35), radius: 13, x: 0, y: 10)
                )
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1).blendMode(.overlay))
            }

            Button { flow.finishAndReset() } label: {
                Text("閉じる")
                    .font(Rounded.font(15, .bold)).foregroundStyle(Theme.mute)
                    .frame(maxWidth: .infinity).frame(height: 52)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
}

// Scattered geometric confetti — circles, diamonds, sparkles. No emoji.
private struct Confetti: View {
    struct Piece { let x: CGFloat; let y: CGFloat; let color: Color; let kind: Kind; let size: CGFloat
        enum Kind { case circle, diamond, sparkle } }

    private let pieces: [Piece] = [
        .init(x: 0.12, y: 14, color: Theme.coral,        kind: .circle,  size: 8),
        .init(x: 0.26, y: 46, color: Theme.sky,          kind: .diamond, size: 9),
        .init(x: 0.44, y: 8,  color: Color(hex: 0xF2994A), kind: .sparkle, size: 17),
        .init(x: 0.62, y: 40, color: Theme.mint,         kind: .circle,  size: 7),
        .init(x: 0.80, y: 18, color: Color(hex: 0x8B7BF0), kind: .diamond, size: 10),
        .init(x: 0.90, y: 56, color: Theme.coral,        kind: .sparkle, size: 15),
        .init(x: 0.06, y: 64, color: Theme.mint,         kind: .diamond, size: 8),
        .init(x: 0.36, y: 70, color: Color(hex: 0x8B7BF0), kind: .circle,  size: 6),
        .init(x: 0.72, y: 74, color: Theme.sky,          kind: .sparkle, size: 14),
        .init(x: 0.18, y: 96, color: Color(hex: 0xF2994A), kind: .circle,  size: 7),
        .init(x: 0.54, y: 100, color: Theme.coral,       kind: .diamond, size: 9),
        .init(x: 0.84, y: 104, color: Theme.mint,        kind: .circle,  size: 8),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(Array(pieces.enumerated()), id: \.offset) { _, p in
                    shape(p)
                        .position(x: p.x * geo.size.width, y: p.y)
                }
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func shape(_ p: Piece) -> some View {
        switch p.kind {
        case .circle:
            Circle().fill(p.color).frame(width: p.size, height: p.size)
        case .diamond:
            RoundedRectangle(cornerRadius: 2).fill(p.color)
                .frame(width: p.size, height: p.size).rotationEffect(.degrees(45))
        case .sparkle:
            Image(systemName: CatIcon.sparkle)
                .font(.system(size: p.size, weight: .regular))
                .foregroundStyle(p.color)
        }
    }
}

#Preview {
    ResultView().environmentObject(FlowModel())
}
