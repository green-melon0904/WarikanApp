import SwiftUI

// 履歴の内訳（誰がいくら）を表示する読み取り専用シート。
// ホーム／全履歴のカードをタップすると開く。
struct HistoryDetailView: View {
    let item: HistoryItem
    @Environment(\.dismiss) private var dismiss

    private var entries: [HistoryEntry] { item.breakdown ?? [] }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.page.ignoresSafeArea()
            TopWash(height: 220)

            VStack(spacing: 0) {
                grabber
                header
                if entries.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var grabber: some View {
        Capsule().fill(Theme.ink.opacity(0.12))
            .frame(width: 40, height: 5)
            .padding(.top, 10)
    }

    private var header: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(item.tone.opacity(0.12))
                Image(systemName: item.icon)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(item.tone)
            }
            .frame(width: 52, height: 52)

            Text("\(item.title)  \(item.date)")
                .font(Rounded.font(15, .bold)).foregroundStyle(Theme.mute)
                .padding(.top, 10)
            Text(yen(item.total))
                .font(Rounded.font(34, .heavy)).foregroundStyle(Theme.ink)
                .monospacedDigit()
            Text("\(item.people)人で割り勘")
                .font(Rounded.font(13, .medium)).foregroundStyle(Theme.mute)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    private var list: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                ForEach(Array(entries.enumerated()), id: \.offset) { i, entry in
                    row(entry, index: i)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
    }

    private func row(_ entry: HistoryEntry, index: Int) -> some View {
        HStack(spacing: 14) {
            InitialAvatar(initial: entry.name.isEmpty ? "?" : String(entry.name.prefix(1)),
                          color: Palette.avatar(index), size: 44)
            Text(entry.name).font(Rounded.font(16, .bold)).foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(yen(entry.amount)).font(Rounded.font(22, .heavy)).foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
        .padding(.init(top: 12, leading: 16, bottom: 12, trailing: 18))
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: Theme.ink.opacity(0.05), radius: 10, x: 0, y: 7)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Text("内訳は記録されていません")
                .font(Rounded.font(16, .bold)).foregroundStyle(Theme.ink)
            Text("この精算より前の記録には\n個別の金額が残っていません。")
                .font(Rounded.font(13, .medium)).foregroundStyle(Theme.mute)
                .multilineTextAlignment(.center).lineSpacing(3)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 40)
    }
}

#Preview {
    HistoryDetailView(item: HistoryItem(
        title: "割り勘", date: "06/06", people: 4, total: 6200,
        icon: CatIcon.utensils, toneHex: Theme.coralHex,
        breakdown: [.init(name: "ゆうた", amount: 1550), .init(name: "さくら", amount: 1550),
                    .init(name: "みく", amount: 1550), .init(name: "けんと", amount: 1550)]
    ))
}
