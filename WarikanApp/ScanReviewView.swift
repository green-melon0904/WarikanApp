import SwiftUI

// Review & edit the items parsed from a receipt photo before importing them.
struct ScanReviewView: View {
    @EnvironmentObject var flow: FlowModel
    @Environment(\.dismiss) private var dismiss
    @State var items: [ScanItem]

    private var includedCount: Int { items.filter(\.include).count }

    var body: some View {
        ZStack {
            Theme.page.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                if items.isEmpty {
                    empty
                } else {
                    list
                    footer
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Theme.ink.opacity(0.15))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            ZStack {
                Text("読み取り結果")
                    .font(Rounded.font(17, .heavy)).foregroundStyle(Theme.ink)

                HStack {
                    Button { dismiss() } label: {
                        Text("閉じる")
                            .font(Rounded.font(15, .bold)).foregroundStyle(Theme.mute)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 12)
        .background(
            Theme.page
                .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .bottom)
        )
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Theme.mute)
            Text("品目を読み取れませんでした")
                .font(Rounded.font(17, .bold)).foregroundStyle(Theme.ink)
            Text("明るい場所で、レシート全体がまっすぐ写るように\nもう一度撮影してみてください。")
                .font(Rounded.font(14, .medium)).foregroundStyle(Theme.mute)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryCTA(title: "閉じる") { dismiss() }
                .padding(.horizontal, 22).padding(.bottom, 24)
        }
    }

    private var list: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                Text("品目と金額を確認・修正してね。不要な行はオフに。")
                    .font(Rounded.font(13, .medium)).foregroundStyle(Theme.mute)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 2)

                ForEach($items) { $item in
                    row($item)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
    }

    private func row(_ item: Binding<ScanItem>) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    item.wrappedValue.include.toggle()
                } label: {
                    Image(systemName: item.wrappedValue.include ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(item.wrappedValue.include ? Theme.primary : Theme.mute.opacity(0.5))
                }
                .buttonStyle(.plain)

                TextField("品目名", text: item.name)
                    .font(Rounded.font(16, .bold)).foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 2) {
                    Text("¥").font(Rounded.font(14, .bold)).foregroundStyle(Theme.mute)
                    TextField("0", value: item.price, format: .number)
                        .font(Rounded.font(16, .heavy)).foregroundStyle(Theme.ink)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 72)
                }
            }

            // quantity + subtotal — indented to line up under the name.
            HStack(spacing: 12) {
                Color.clear.frame(width: 24)   // align with the check circle
                qtyStepper(item.qty)
                Spacer()
                if item.wrappedValue.qty > 1 {
                    Text("小計 \(yen(item.wrappedValue.price * item.wrappedValue.qty))")
                        .font(Rounded.font(13, .bold)).foregroundStyle(Theme.mute)
                        .monospacedDigit()
                }
            }
        }
        .padding(.init(top: 12, leading: 14, bottom: 12, trailing: 14))
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: Theme.ink.opacity(0.05), radius: 8, x: 0, y: 5)
        )
        .opacity(item.wrappedValue.include ? 1 : 0.5)
    }

    private func qtyStepper(_ qty: Binding<Int>) -> some View {
        HStack(spacing: 10) {
            qtyButton(CatIcon.minus, tint: Theme.ink, bg: Theme.ink.opacity(0.05)) {
                if qty.wrappedValue > 1 { qty.wrappedValue -= 1 }
            }
            HStack(spacing: 1) {
                Text("×").font(Rounded.font(13, .bold)).foregroundStyle(Theme.mute)
                Text("\(qty.wrappedValue)").font(Rounded.font(16, .heavy)).foregroundStyle(Theme.ink)
                    .monospacedDigit().frame(minWidth: 18)
            }
            qtyButton(CatIcon.plus, tint: Theme.primary, bg: Theme.primary.opacity(0.10)) {
                qty.wrappedValue += 1
            }
        }
    }

    private func qtyButton(_ icon: String, tint: Color, bg: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 14, weight: .heavy))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(bg))
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        PrimaryCTA(title: includedCount > 0 ? "\(includedCount)品を追加" : "追加",
                   leadingSystem: CatIcon.plus,
                   enabled: includedCount > 0) {
            for item in items where item.include && !item.name.isEmpty && item.price > 0 {
                flow.addItem(name: item.name, price: item.price, qty: max(1, item.qty))
            }
            dismiss()
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
}
