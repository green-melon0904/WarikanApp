import SwiftUI
import UIKit

// 画面② 参加者登録（STEP 1 / 3）
struct ParticipantsView: View {
    @EnvironmentObject var flow: FlowModel
    @State private var newName: String = ""
    @State private var focused: Bool = false
    @State private var proxy = FieldProxy()
    private let bottomID = "members-bottom"
    // Non-overshooting curve, shared by add/remove/scroll so the row slide,
    // the bottom-pinned reflow and the scroll all move as one — no bounce.
    private let addAnim = Animation.easeOut(duration: 0.26)

    var body: some View {
        ZStack(alignment: .top) {
            Theme.page.ignoresSafeArea()
            TopWash(height: 260)

            VStack(spacing: 0) {
                header
                countBar
                list
                bottomBar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackButton { flow.path.removeLast() }
            VStack(alignment: .leading, spacing: 6) {
                StepBadge(step: 1)
                Text("みんなを追加しよう")
                    .font(Rounded.font(27, .heavy))
                    .foregroundStyle(Theme.ink)
                Text("割り勘するメンバーを登録してね。")
                    .font(Rounded.font(14, .medium))
                    .foregroundStyle(Theme.mute)
                    .padding(.top, 1)
            }
            .padding(.top, 20)
            .padding(.leading, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.top, 12)
    }

    // Pinned member count — always visible no matter how far the list scrolls.
    private var countBar: some View {
        HStack(spacing: 6) {
            Image(systemName: CatIcon.users)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.primary)
            Text("メンバー ")
                .font(Rounded.font(14, .bold))
                .foregroundStyle(Theme.mute)
            + Text("\(flow.members.count)")
                .font(Rounded.font(14, .heavy))
                .foregroundStyle(Theme.ink)
            + Text("人")
                .font(Rounded.font(14, .bold))
                .foregroundStyle(Theme.mute)
            Spacer()
        }
        .monospacedDigit()
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white)
                .shadow(color: Theme.ink.opacity(0.05), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, 26)
        .padding(.top, 18)
        .padding(.bottom, 4)
    }

    private var list: some View {
        ScrollViewReader { proxy in
            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if flow.members.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 10) {
                                ForEach(flow.members) { member in
                                    row(member)
                                        .id(member.id)
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                            }
                            .animation(addAnim, value: flow.members.count)
                            .padding(.horizontal, 22)
                            // anchor so we can scroll past the last row to the very
                            // bottom; its height is the breathing room kept between the
                            // newest row and the input bar so the row is never buried.
                            Color.clear.frame(height: 14).id(bottomID)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    // Fill at least the viewport and pin content to the BOTTOM, so
                    // rows sit snug above the input bar; slack moves up under the header.
                    .frame(minHeight: geo.size.height,
                           alignment: flow.members.isEmpty ? .center : .bottom)
                    .padding(.vertical, 12)
                }
                .mask(
                    // soften only the TOP edge, so the newest row (bottom) stays crisp.
                    LinearGradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black, location: 0.05),
                        .init(color: .black, location: 1.0),
                    ], startPoint: .top, endPoint: .bottom)
                )
                .onChange(of: flow.members.count) { old, new in
                    guard new > old else { return }   // only on add
                    withAnimation(addAnim) {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
                // The keyboard opening/closing changes the bottom bar's height
                // (次へ appears/disappears), shrinking the list from the bottom.
                // Re-pin to the newest row so it never gets clipped by the bar.
                .onChange(of: focused) { _, _ in
                    withAnimation(addAnim) {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.primary.opacity(0.08))
                Image(systemName: CatIcon.users)
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(Theme.primary.opacity(0.7))
            }
            .frame(width: 76, height: 76)

            Text("まだメンバーがいません")
                .font(Rounded.font(16, .bold)).foregroundStyle(Theme.ink)
            Text("下の欄から名前を追加してね。")
                .font(Rounded.font(13, .medium)).foregroundStyle(Theme.mute)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
        .padding(.bottom, 24)
    }

    private func row(_ member: Member) -> some View {
        HStack(spacing: 14) {
            InitialAvatar(initial: member.initial, color: member.color, size: 46)
            Text(member.name)
                .font(Rounded.font(17, .bold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                withAnimation(addAnim) {
                    flow.removeMember(member)
                }
            } label: {
                Image(systemName: CatIcon.xmark)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.mute)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.ink.opacity(0.05)))
            }
            .buttonStyle(.plain)
        }
        .padding(.init(top: 11, leading: 14, bottom: 11, trailing: 12))
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Theme.ink.opacity(0.07), radius: 11, x: 0, y: 8)
        )
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            MemberTextField(text: $newName,
                            placeholder: "名前を入力",
                            proxy: proxy,
                            onFocusChange: { focused = $0 },
                            onReturn: add)
                .frame(height: 54)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Theme.ink.opacity(0.08), lineWidth: 1.5))
                )

            // While typing, explain the keyboard-only flow (no buttons on screen):
            // Enter adds; an extra Enter on an empty field finishes (closes the keyboard).
            if focused {
                Text("Enter で追加・空欄でもう一度押すと完了")
                    .font(Rounded.font(12, .medium))
                    .foregroundStyle(Theme.mute)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
            }

            // Hidden while typing (out of the way); an empty-field Enter closes the
            // keyboard, which clears focus and brings this back so it can be tapped.
            if !focused {
                PrimaryCTA(title: "次へ", trailingSystem: CatIcon.arrow,
                           enabled: flow.members.count >= 1) {
                    flow.path.append(.receipt)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: focused)
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .padding(.bottom, 26)
        // Lift the bar as a distinct surface above the scrolling list, so the
        // input / 追加 / 次へ stay legible even when the newest row sits right above.
        .background(
            Theme.page
                .shadow(color: Theme.ink.opacity(0.06), radius: 10, x: 0, y: -3)
        )
    }

    private func add() {
        // Commit any in-progress IME composition *in place* (the field stays first
        // responder, so the keyboard never closes/reopens), then read the finished
        // name. This replaces the old focus-toggle, which caused the keyboard flicker.
        let name = proxy.commit?() ?? newName
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        // Enter on an empty field = "finish": close the keyboard so 次へ appears.
        guard !trimmed.isEmpty else {
            proxy.dismiss?()
            return
        }
        let before = flow.members.count
        flow.addMember(name)
        guard flow.members.count > before else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        newName = ""        // clears the field via the binding; keyboard stays up
    }
}

// ─────────────────────────────────────────────────────────────
// MemberTextField — a thin UITextField wrapper whose only reason to
// exist (over SwiftUI's TextField) is `commitMarkedText()`: it calls
// `unmarkText()` to commit in-progress Japanese IME composition WITHOUT
// resigning first responder, so adding a member never dismisses the
// keyboard. Styled to match the rest of the app's rounded system typography.
// ─────────────────────────────────────────────────────────────
final class FieldProxy {
    /// Commits any marked (uncommitted) IME text in place and returns the
    /// full, finished string. Keyboard stays up. nil until the field exists.
    var commit: (() -> String)? = nil
    /// Resigns first responder — closes the keyboard. nil until the field exists.
    var dismiss: (() -> Void)? = nil
}

struct MemberTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var proxy: FieldProxy
    var onFocusChange: (Bool) -> Void
    var onReturn: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.delegate = context.coordinator
        tf.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        tf.textColor = UIColor(Theme.ink)
        tf.tintColor = UIColor(Theme.primary)
        tf.returnKeyType = .done
        tf.autocorrectionType = .no
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor(Theme.mute),
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            ])
        tf.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tf.addTarget(context.coordinator,
                     action: #selector(Coordinator.editingChanged(_:)),
                     for: .editingChanged)

        context.coordinator.textField = tf
        proxy.commit = { [weak c = context.coordinator] in c?.commitMarkedText() ?? "" }
        proxy.dismiss = { [weak c = context.coordinator] in c?.dismissKeyboard() }
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        if uiView.text != text { uiView.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: MemberTextField
        weak var textField: UITextField?

        init(_ parent: MemberTextField) { self.parent = parent }

        @objc func editingChanged(_ tf: UITextField) {
            parent.text = tf.text ?? ""
        }

        func textFieldDidBeginEditing(_ tf: UITextField) { parent.onFocusChange(true) }
        func textFieldDidEndEditing(_ tf: UITextField) { parent.onFocusChange(false) }

        func textFieldShouldReturn(_ tf: UITextField) -> Bool {
            parent.onReturn()
            return false                 // keep the keyboard up after Done
        }

        @objc func dismissKeyboard() { textField?.resignFirstResponder() }

        /// Commit marked IME text without resigning, sync the binding, return the text.
        func commitMarkedText() -> String {
            textField?.unmarkText()
            let t = textField?.text ?? ""
            parent.text = t
            return t
        }
    }
}

#Preview {
    ParticipantsView().environmentObject(FlowModel())
}
