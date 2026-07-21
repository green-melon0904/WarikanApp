import SwiftUI

// 全履歴一覧（ホームの「すべて見る」から遷移）。保存済みの精算をすべて表示。
struct HistoryListView: View {
    @EnvironmentObject var flow: FlowModel
    @State private var detailItem: HistoryItem?

    var body: some View {
        ZStack(alignment: .top) {
            Theme.page.ignoresSafeArea()
            TopWash(height: 240)

            VStack(spacing: 0) {
                header
                if flow.history.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .sheet(item: $detailItem) { item in
            HistoryDetailView(item: item)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            BackButton { flow.path.removeLast() }
            VStack(alignment: .leading, spacing: 2) {
                Text("過去の精算")
                    .font(Rounded.font(23, .heavy))
                    .foregroundStyle(Theme.ink)
                Text("\(flow.history.count)件の記録")
                    .font(Rounded.font(13, .bold))
                    .foregroundStyle(Theme.mute)
            }
            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var list: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(flow.history) { item in
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
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            ZStack {
                Circle().fill(Theme.primary.opacity(0.10))
                ReceiptMark(size: 34, bodyColor: Theme.primary, lineColor: .white)
            }
            .frame(width: 76, height: 76)
            Text("まだ記録がありません")
                .font(Rounded.font(17, .bold)).foregroundStyle(Theme.ink)
            Text("割り勘を完了すると、ここに残ります。")
                .font(Rounded.font(14, .medium)).foregroundStyle(Theme.mute)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HistoryListView().environmentObject(FlowModel())
}
