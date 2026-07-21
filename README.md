# ワリカン！ — Bill-Split App (SwiftUI)

A faithful, **fully working** SwiftUI implementation of the **ワリカン！** design from
the Claude Design handoff bundle (`swiftui-maneyapp`). Coral is the confirmed brand
palette. No emoji anywhere — only rounded stroke / SF Symbol line icons, soft
rounded shape language throughout.

## The flow (all functional)
1. **ホーム** — start a new split; 「過去の精算」history (finished splits get prepended).
2. **参加者登録 (STEP 1/3)** — add / remove members; coloured initial avatars.
3. **レシート入力 (STEP 2/3)** — **カメラ/写真からレシートをOCR読み取り**（Apple Vision,
   日本語）→ 品目名・金額を自動抽出して確認画面で修正・取り込み。手動入力も可。live 合計.
4. **品目割り当て (STEP 3/3)** — tap avatars to pick who ate each item; per-person
   amount updates live; 「全員でシェア」selects everyone.
5. **精算結果** — each member's amount + total, computed from the assignments;
   「LINEでシェア」opens the share sheet; 「もう一度やり直す」records to history & resets.

State lives in `FlowModel` (`ObservableObject`), navigation via `NavigationStack`.
The split math floor-divides each item among its members and distributes the
remainder yen so per-item sums stay exact; amounts are then totalled per member.

## Design fidelity
- Tokens ported 1:1 from the mock: coral `#FF6B6B`, page `#FFFCFB`, ink `#2B2A28`,
  mute `#9C988F`; brand trio coral/mint/sky for tints.
- **Rounded system typography**: uses iOS's native rounded type design, avoiding
  bundled font assets and keeping the app package small.
- The iPhone bezel / status bar / home indicator are provided by the real device,
  so they are intentionally not redrawn.

## Run
Open `WarikanApp.xcodeproj` in Xcode and run on an iPhone simulator (portrait).

> Note: this app targets iOS 17+. It type-checks and compiles cleanly against the
> iOS Simulator SDK. In a CLI-only environment without a matching simulator runtime
> installed (e.g. Xcode 26.5 SDK with only an iOS 17.5 runtime present), `xcodebuild`
> can't resolve a simulator destination — install the matching iOS platform via
> Xcode ▸ Settings ▸ Components (or `xcodebuild -downloadPlatform iOS`) to run it.

## Structure
```
WarikanApp/
  WarikanApp.swift     – @main App
  RootView.swift       – NavigationStack + routing
  FlowModel.swift      – shared state + split calculation
  Models.swift         – Member / ReceiptItem / SplitResult + palettes
  HomeView.swift       – hero / CTA / history
  ParticipantsView.swift / ReceiptView.swift / AssignView.swift / ResultView.swift
  HistoryCard.swift    – history card; HistoryItem.swift – history model
  Components.swift      – PrimaryCTA, BackButton, InitialAvatar, TopWash, StepBadge
  Icons.swift          – custom receipt/scan shapes + SF Symbol mapping
  DesignSystem.swift   – colors, typography (Mochiy Pop One + Zen Maru Gothic)
  Assets.xcassets      – AppIcon, AccentColor (coral)
Info.plist             – UIAppFonts, scene manifest
```
