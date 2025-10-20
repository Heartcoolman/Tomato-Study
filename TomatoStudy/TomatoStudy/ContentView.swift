import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarItem? = .timer

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.title, systemImage: item.icon)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .navigationTitle("Tomato Study")
        } detail: {
            switch selection ?? .timer {
            case .timer:
                TimerView()
            case .history:
                HistoryView()
            case .settings:
                SettingsView()
            }
        }
    }
}

private enum SidebarItem: Hashable, CaseIterable {
    case timer
    case history
    case settings

    var title: String {
        switch self {
        case .timer: return NSLocalizedString("Timer", comment: "Sidebar timer")
        case .history: return NSLocalizedString("History", comment: "Sidebar history")
        case .settings: return NSLocalizedString("Settings", comment: "Sidebar settings")
        }
    }

    var icon: String {
        switch self {
        case .timer: return "clock.fill"
        case .history: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
        .environmentObject(SettingsStore.shared)
        .environmentObject(StatsStore.shared)
}
