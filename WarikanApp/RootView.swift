import SwiftUI

// Hosts the NavigationStack and routes each step of the flow.
struct RootView: View {
    @StateObject private var flow = FlowModel()

    var body: some View {
        NavigationStack(path: $flow.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .participants: ParticipantsView()
                    case .receipt:      ReceiptView()
                    case .assign:       AssignView()
                    case .result:       ResultView()
                    case .history:      HistoryListView()
                    }
                }
        }
        .environmentObject(flow)
        .tint(Theme.primary)
    }
}

#Preview {
    RootView()
}
