import SwiftUI

// 画面③ レシート入力（STEP 2 / 3・手動入力タブ）
struct ReceiptView: View {
    @EnvironmentObject var flow: FlowModel
    @State private var name = ""
    @State private var priceText = ""
    @State private var qty = 1
    // Enum focus (not a shared Bool) so moving 品目名 → 金額 goes straight from
    // .name to .price without passing through "no focus" — otherwise the footer
    // would flash back in for that one frame between the two fields.
    private enum Field { case name, price }
    @FocusState private var focusedField: Field?

    // camera / OCR flow
    @State private var showSourceDialog = false
    @State private var pickerSource: UIImagePickerController.SourceType?
    @State private var isScanning = false
    @State private var scanItems: [ScanItem] = []
    @State private var showReview = false

    var body: some View {
        ZStack(alignment: .top) {
            Theme.page.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                scrollArea
                if focusedField == nil {
                    footer
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: focusedField == nil)

            if isScanning { scanningOverlay }

            if showSourceDialog { sourceSheet }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // A tap anywhere outside the keyboard (and outside the text fields)
        // closes it — see DismissKeyboardOnTap.
        .background(DismissKeyboardOnTap { focusedField = nil })
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(item: $pickerSource) { source in
            CameraPicker(sourceType: source) { image in
                pickerSource = nil
                guard let image else { return }
                isScanning = true
                ReceiptScanner.scan(image) { items in
                    isScanning = false
                    scanItems = items
                    showReview = true
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showReview) {
            ScanReviewView(items: scanItems).environmentObject(flow)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    private var scanningOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView().controlSize(.large).tint(Theme.primary)
                Text("レシートを読み取り中…")
                    .font(Rounded.font(15, .bold)).foregroundStyle(Theme.ink)
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
        }
    }

    // ── Custom "read receipt" sheet (matches the app's coral/rounded style) ──
    private var sourceSheet: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.32).ignoresSafeArea()
                .onTapGesture { dismissSource() }

            VStack(spacing: 0) {
                Capsule().fill(Theme.ink.opacity(0.12))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10).padding(.bottom, 20)

                VStack(spacing: 6) {
                    Text("レシートを読み取る")
                        .font(Rounded.font(20, .heavy)).foregroundStyle(Theme.ink)
                    Text("撮影するか、写真から選んでね。")
                        .font(Rounded.font(13, .medium)).foregroundStyle(Theme.mute)
                }
                .padding(.bottom, 22)

                VStack(spacing: 12) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        sourceButton(icon: CatIcon.camera, title: "カメラで撮影",
                                     subtitle: "その場でレシートを撮る", filled: true) {
                            chooseSource(.camera)
                        }
                    }
                    sourceButton(icon: CatIcon.photo, title: "写真から選ぶ",
                                 subtitle: "保存済みの画像を使う", filled: false) {
                        chooseSource(.photoLibrary)
                    }
                }

                Button { dismissSource() } label: {
                    Text("キャンセル")
                        .font(Rounded.font(16, .bold)).foregroundStyle(Theme.mute)
                        .frame(maxWidth: .infinity).frame(height: 52)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30, style: .continuous)
                    .fill(Theme.page)
                    .shadow(color: Theme.ink.opacity(0.12), radius: 24, x: 0, y: -6)
                    .ignoresSafeArea(edges: .bottom)
            )
            .transition(.move(edge: .bottom))
        }
        .transition(.opacity)
        .zIndex(10)
    }

    private func sourceButton(icon: String, title: String, subtitle: String,
                              filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(filled ? Color.white.opacity(0.22) : Theme.primary.opacity(0.10))
                    Image(systemName: icon).font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(filled ? .white : Theme.primary)
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Rounded.font(16, .bold))
                        .foregroundStyle(filled ? .white : Theme.ink)
                    Text(subtitle).font(Rounded.font(12, .medium))
                        .foregroundStyle(filled ? Color.white.opacity(0.85) : Theme.mute)
                }
                Spacer()
                Image(systemName: CatIcon.chevron).font(.system(size: 14, weight: .bold))
                    .foregroundStyle(filled ? Color.white.opacity(0.85) : Theme.mute)
            }
            .padding(.horizontal, 16)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(filled ? Theme.primary : Color.white)
                    .shadow(color: (filled ? Theme.primary : Theme.ink).opacity(filled ? 0.30 : 0.06),
                            radius: filled ? 12 : 9, x: 0, y: filled ? 9 : 6)
            )
        }
        .buttonStyle(.plain)
    }

    private func chooseSource(_ source: UIImagePickerController.SourceType) {
        withAnimation(.easeIn(duration: 0.18)) { showSourceDialog = false }
        // let the sheet finish dismissing before presenting the picker
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { pickerSource = source }
    }

    private func dismissSource() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) { showSourceDialog = false }
    }

    // ── Header + tabs ──
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                BackButton { flow.path.removeLast() }
                VStack(alignment: .leading, spacing: 2) {
                    StepBadge(step: 2)
                    Text("レシートを入力")
                        .font(Rounded.font(23, .heavy))
                        .foregroundStyle(Theme.ink)
                }
            }
            HStack(spacing: 4) {
                Button {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
                        showSourceDialog = true
                    }
                } label: {
                    tab(icon: CatIcon.camera, label: "カメラ", active: false)
                }
                .buttonStyle(.plain)
                tab(icon: CatIcon.pencil, label: "手動入力", active: true)
            }
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.ink.opacity(0.05)))
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func tab(icon: String, label: String, active: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold))
            Text(label).font(Rounded.font(15, .bold))
        }
        .foregroundStyle(active ? Theme.primary : Theme.mute)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(active ? Color.white : .clear)
                .shadow(color: active ? Theme.ink.opacity(0.10) : .clear, radius: 5, x: 0, y: 2)
        )
    }

    // ── Form + registered list ──
    private var scrollArea: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    formCard
                    HStack(spacing: 6) {
                        Text("登録済み").font(Rounded.font(14, .heavy)).foregroundStyle(Theme.ink)
                        Text("\(flow.items.count)品").font(Rounded.font(13, .bold)).foregroundStyle(Theme.mute)
                        Spacer()
                    }
                    .padding(.leading, 4)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                    VStack(spacing: 10) {
                        ForEach(flow.items) { item in itemRow(item) }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 10)
                // Keep filling the viewport so the form lays out from the top;
                // the keyboard-dismiss tap is handled window-wide (DismissKeyboardOnTap).
                .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .top)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            fieldLabel("品目名")
            TextField("例）唐揚げ", text: $name)
                .font(Rounded.font(16, .bold))
                .focused($focusedField, equals: .name)
                .padding(.horizontal, 14).frame(height: 50)
                .background(fieldBg)

            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    fieldLabel("金額")
                    HStack {
                        TextField("0", text: $priceText)
                            .font(Rounded.font(16, .bold))
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .price)
                        Text("円").font(Rounded.font(15, .bold)).foregroundStyle(Theme.mute)
                    }
                    .padding(.horizontal, 14).frame(height: 50)
                    .background(fieldBg)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 0) {
                    fieldLabel("数量")
                    HStack {
                        stepButton(CatIcon.minus, tint: Theme.ink, bg: Theme.ink.opacity(0.05)) {
                            if qty > 1 { qty -= 1 }
                        }
                        Spacer()
                        Text("\(qty)").font(Rounded.font(17, .heavy)).foregroundStyle(Theme.ink)
                            .monospacedDigit()
                        Spacer()
                        stepButton(CatIcon.plus, tint: Theme.primary, bg: Theme.primary.opacity(0.10)) {
                            qty += 1
                        }
                    }
                    .padding(.horizontal, 6).frame(height: 50)
                    .background(fieldBg)
                }
                .frame(width: 130)
            }
            .padding(.top, 14)

            Button(action: addItem) {
                HStack(spacing: 6) {
                    Image(systemName: CatIcon.plus).font(.system(size: 18, weight: .heavy))
                    Text("追加する").font(Rounded.font(16, .bold))
                }
                .foregroundStyle(Theme.primary)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Theme.primary.opacity(0.10)))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
                .shadow(color: Theme.ink.opacity(0.05), radius: 11, x: 0, y: 8)
        )
    }

    private func itemRow(_ item: ReceiptItem) -> some View {
        HStack(spacing: 13) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(Rounded.font(16, .bold)).foregroundStyle(Theme.ink)
                (Text("\(yen(item.price)) × \(item.qty) = ").foregroundStyle(Theme.mute)
                 + Text(yen(item.total)).foregroundStyle(Theme.ink))
                    .font(Rounded.font(13, .bold))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button { flow.removeItem(item) } label: {
                Image(systemName: CatIcon.xmark)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.mute)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.ink.opacity(0.05)))
            }
            .buttonStyle(.plain)
        }
        .padding(.init(top: 11, leading: 13, bottom: 11, trailing: 12))
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: Theme.ink.opacity(0.05), radius: 10, x: 0, y: 7)
        )
    }

    // ── Footer ──
    private var footer: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("合計").font(Rounded.font(15, .bold)).foregroundStyle(Theme.mute)
                Spacer()
                Text(yen(flow.itemsTotal))
                    .font(Rounded.font(26, .heavy)).foregroundStyle(Theme.ink)
                    .monospacedDigit()
            }
            .padding(.horizontal, 2)

            PrimaryCTA(title: "次へ", trailingSystem: CatIcon.arrow,
                       enabled: !flow.items.isEmpty) {
                flow.path.append(.assign)
            }
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

    // ── helpers ──
    private func fieldLabel(_ s: String) -> some View {
        Text(s).font(Rounded.font(13, .bold)).foregroundStyle(Theme.mute)
            .padding(.leading, 2).padding(.bottom, 6)
    }
    private var fieldBg: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Theme.ink.opacity(0.09), lineWidth: 1.5))
    }
    private func stepButton(_ icon: String, tint: Color, bg: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 16, weight: .heavy))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(bg))
        }
        .buttonStyle(.plain)
    }

    private func addItem() {
        flow.addItem(name: name, price: Int(priceText) ?? 0, qty: qty)
        name = ""; priceText = ""; qty = 1
        focusedField = nil   // 追加したらキーボードを閉じる（合計＋次へバーが戻る）
    }
}

#Preview {
    ReceiptView().environmentObject(FlowModel())
}
