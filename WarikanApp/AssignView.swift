import SwiftUI

// 画面④ 品目割り当て（STEP 3 / 3・誰が食べた？）
struct AssignView: View {
    @EnvironmentObject var flow: FlowModel

    var body: some View {
        ZStack(alignment: .top) {
            Theme.page.ignoresSafeArea()
            TopWash(height: 240)

            VStack(spacing: 0) {
                header
                cards
                footer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                BackButton { flow.path.removeLast() }
                VStack(alignment: .leading, spacing: 2) {
                    StepBadge(step: 3)
                    Text("誰が食べた？")
                        .font(Rounded.font(23, .heavy))
                        .foregroundStyle(Theme.ink)
                }
            }
            Text("食べた人をタップして選んでね。複数人なら均等割り。")
                .font(Rounded.font(14, .medium))
                .foregroundStyle(Theme.mute)
                .padding(.leading, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var cards: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(flow.items) { item in card(item) }
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 10)
        }
    }

    private func card(_ item: ReceiptItem) -> some View {
        let count = flow.selectedCount(item)
        return VStack(spacing: 14) {
            // name + total
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous).fill(item.tone.opacity(0.12))
                    Circle().fill(item.tone).frame(width: 14, height: 14)
                }
                .frame(width: 40, height: 40)
                Text(item.name).font(Rounded.font(17, .bold)).foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(yen(item.total)).font(Rounded.font(17, .heavy)).foregroundStyle(Theme.ink)
                    .monospacedDigit()
            }

            // avatars
            HStack(spacing: 12) {
                ForEach(flow.members) { member in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { flow.toggle(item, member) }
                    } label: {
                        InitialAvatar(initial: member.initial, color: member.color, size: 46,
                                      selected: flow.isSelected(item, member), showCheck: true)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }

            // per-person + share-all
            HStack {
                perLabel(item, count: count)
                Spacer()
                shareAllButton(item)
            }

            // rounding unit + remainder payer (only when split among 2+ people)
            if count >= 2 {
                HStack(spacing: 10) {
                    roundingMenu(item)
                    payerMenu(item)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
                .shadow(color: Theme.ink.opacity(0.05), radius: 11, x: 0, y: 8)
        )
    }

    @ViewBuilder
    private func perLabel(_ item: ReceiptItem, count: Int) -> some View {
        if count == 0 {
            Text("未選択").font(Rounded.font(15, .bold)).foregroundStyle(Theme.mute)
        } else if count == 1 {
            (Text("1人 ").font(Rounded.font(13, .bold)).foregroundStyle(Theme.mute)
             + Text(yen(item.total)).font(Rounded.font(16, .heavy)).foregroundStyle(Theme.primary))
                .monospacedDigit()
        } else {
            (Text("各自 ").font(Rounded.font(13, .bold)).foregroundStyle(Theme.mute)
             + Text(yen(flow.perPerson(item))).font(Rounded.font(16, .heavy)).foregroundStyle(Theme.primary))
                .monospacedDigit()
        }
    }

    private func roundingMenu(_ item: ReceiptItem) -> some View {
        let unit = max(1, item.roundingUnit)
        return Menu {
            ForEach([1, 10, 100], id: \.self) { u in
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { flow.setRoundingUnit(item, u) }
                } label: {
                    Text("\(u)円")
                    if unit == u { Image(systemName: "checkmark") }
                }
            }
        } label: {
            adjustChip(label: "丸め \(unit)円", active: unit != 1)
        }
        .buttonStyle(.plain)
    }

    private func payerMenu(_ item: ReceiptItem) -> some View {
        let ids = flow.assignments[item.id] ?? []
        let candidates = flow.members.filter { ids.contains($0.id) }
        let current = flow.payer(for: item)
        return Menu {
            ForEach(candidates) { m in
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { flow.setPayer(item, m.id) }
                } label: {
                    Text(m.name)
                    if current?.id == m.id { Image(systemName: "checkmark") }
                }
            }
        } label: {
            adjustChip(label: "端数 \(current?.name ?? "")", active: item.payerID != nil)
        }
        .buttonStyle(.plain)
    }

    private func adjustChip(label: String, active: Bool) -> some View {
        HStack(spacing: 6) {
            Text(label).font(Rounded.font(13, .bold))
            Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(active ? Theme.primary : Theme.mute)
        .padding(.horizontal, 14).frame(height: 38)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(active ? Theme.primary.opacity(0.10) : .clear)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(active ? .clear : Theme.ink.opacity(0.10), lineWidth: 1.5))
        )
    }

    private func shareAllButton(_ item: ReceiptItem) -> some View {
        let all = flow.isShareAll(item)
        return Button { withAnimation(.easeOut(duration: 0.15)) { flow.shareAll(item) } } label: {
            HStack(spacing: 6) {
                Image(systemName: CatIcon.users).font(.system(size: 13, weight: .bold))
                Text("全員でシェア").font(Rounded.font(13, .bold))
            }
            .foregroundStyle(all ? Theme.primary : Theme.mute)
            .padding(.horizontal, 14).frame(height: 38)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(all ? Theme.primary.opacity(0.10) : .clear)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(all ? .clear : Theme.ink.opacity(0.10), lineWidth: 1.5))
            )
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        PrimaryCTA(title: "計算する", leadingSystem: CatIcon.sparkle) {
            flow.path.append(.result)
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 26)
        .background(
            Theme.page
                .overlay(Rectangle().fill(Theme.ink.opacity(0.07)).frame(height: 1), alignment: .top)
                .shadow(color: Theme.ink.opacity(0.05), radius: 12, x: 0, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

#Preview {
    AssignView().environmentObject(FlowModel())
}
