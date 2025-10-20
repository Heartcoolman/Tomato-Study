import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var stats: StatsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            List {
                Section(header: Text("This Week")) {
                    HStack {
                        Text("Minutes")
                        Spacer()
                        Text("\(stats.weekTotalMinutes())")
                    }
                }

                Section(header: Text("Daily")) {
                    ForEach(stats.summaries.sorted { $0.date > $1.date }) { summary in
                        HStack {
                            Text(summary.date, style: .date)
                            Spacer()
                            Text("\(summary.pomodoros) • \(summary.minutes) min")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.clear)

            ShareLink(item: CSVDocument(csv: stats.exportCSV())) {
                Label("Export CSV", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(red: 0.976, green: 0.976, blue: 0.960).ignoresSafeArea())
        .navigationTitle("History")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Focus journey")
                .font(.largeTitle.bold())
            Text("Track your daily and weekly progress at a glance.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(StatsStore.shared)
}
