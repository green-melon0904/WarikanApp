import SwiftUI

// White card, r:22, soft double shadow. Icon chip + title/meta + amount.
struct HistoryCard: View {
    let item: HistoryItem

    var body: some View {
        HStack(spacing: 14) {
            // category icon chip
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(item.tone.opacity(0.10))
                Image(systemName: item.icon)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(item.tone)
            }
            .frame(width: 46, height: 46)

            // title + meta
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(Rounded.font(17, .bold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 7) {
                    Text(item.date)
                        .font(Rounded.font(13, .medium))
                        .foregroundStyle(Theme.mute)
                        .monospacedDigit()
                    Circle()
                        .fill(Theme.mute.opacity(0.6))
                        .frame(width: 3, height: 3)
                    HStack(spacing: 3) {
                        Image(systemName: CatIcon.users)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.mute)
                        Text("\(item.people)人")
                            .font(Rounded.font(13, .medium))
                            .foregroundStyle(Theme.mute)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(yen(item.total))
                    .font(Rounded.font(17, .heavy))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                Text("1人 \(yen(item.perPerson))")
                    .font(Rounded.font(12, .medium))
                    .foregroundStyle(Theme.mute)
                    .monospacedDigit()
                    .fixedSize()
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
                .shadow(color: Theme.ink.opacity(0.04), radius: 1, x: 0, y: 1)
                .shadow(color: Theme.ink.opacity(0.06), radius: 11, x: 0, y: 8)
        )
    }
}
