import SwiftUI

struct StatsView: View {
    @StateObject private var vm: StatsViewModel
    @Environment(\.dismiss) private var dismiss

    init(store: any ScoreStoring) {
        _vm = StateObject(wrappedValue: StatsViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.totalWins == 0 {
                    emptyState
                } else {
                    statsList
                }
            }
            .navigationTitle("Your Stats")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear { vm.refresh() }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "trophy")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("No wins yet")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Complete a game to see your stats here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Stats list

    private var statsList: some View {
        List {
            Section {
                HStack {
                    Label("Total wins", systemImage: "trophy.fill")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(vm.totalWins)")
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }
            }

            ForEach(vm.groups) { group in
                Section {
                    ForEach(group.stats) { stat in
                        StatRow(stat: stat)
                    }
                } header: {
                    HStack {
                        Text(group.gameName)
                        Spacer()
                        Text("\(group.totalPlays) \(group.totalPlays == 1 ? "win" : "wins") total")
                            .font(.caption)
                            .textCase(nil)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Row

private struct StatRow: View {
    let stat: GameStat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(stat.difficulty)
                    .font(.headline)
                Spacer()
                Text("\(stat.playCount) \(stat.playCount == 1 ? "win" : "wins")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let best = stat.bestMoves {
                HStack(spacing: 16) {
                    Label("Best \(best) moves", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    if let avg = stat.averageMoves {
                        Label("Avg \(Int(avg.rounded())) moves", systemImage: "chart.bar.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let last = stat.lastPlayed {
                Text(lastPlayedText(last))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private func lastPlayedText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Last played \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}
