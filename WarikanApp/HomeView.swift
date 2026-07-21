import SwiftUI

struct HomeView: View {
    @EnvironmentObject var flow: FlowModel
    @State private var detailItem: HistoryItem?

    var body: some View {
        ZStack(alignment: .top) {
            Theme.page.ignoresSafeArea()
            TopWash(height: 320)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    hero
                    cta
                    historySection
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(item: $detailItem) { item in
            HistoryDetailView(item: item)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
        }
    }

    // ── Hero ──
    private var hero: some View {
        VStack(spacing: 0) {
            Image("AppLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                .shadow(color: Theme.primary.opacity(0.33), radius: 10, x: 0, y: 8)

            Text("サクワリ")
                .font(Rounded.font(38, .heavy))
                .foregroundStyle(Theme.ink)
                .tracking(0.5)
                .padding(.top, 16)

            Text("レシートを撮るだけ。\nみんなの支払いを自動で計算。")
                .font(Rounded.font(15, .medium))
                .foregroundStyle(Theme.mute)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 12)
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
    }

    // ── Primary CTA ──
    private var cta: some View {
        Button(action: { flow.start() }) {
            HStack(spacing: 11) {
                StrokeIcon(kind: .scan, size: 23, lineWidth: 2.2, color: .white)
                    .offset(y: 1.5)
                Text("割り勘をはじめる")
                    .font(Rounded.font(19, .bold))
                    .tracking(0.3)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.primary)
                    .shadow(color: Theme.primary.opacity(0.35), radius: 13, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    .blendMode(.overlay)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.top, 30)
    }

    // ── History ──
    private var historySection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("過去の精算")
                    .font(Rounded.font(18, .heavy))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if flow.history.count > 3 {
                    Button {
                        flow.path.append(.history)
                    } label: {
                        HStack(spacing: 2) {
                            Text("すべて見る")
                                .font(Rounded.font(14, .bold))
                            Image(systemName: CatIcon.chevron)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(Theme.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 2)

            ForEach(flow.history.prefix(3)) { item in
                Button { detailItem = item } label: {
                    HistoryCard(item: item)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        flow.removeHistory(item)
                    } label: {
                        Label("削除", systemImage: CatIcon.xmark)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 34)
        .padding(.bottom, 28)
    }
}

#Preview {
    HomeView().environmentObject(FlowModel())
}
