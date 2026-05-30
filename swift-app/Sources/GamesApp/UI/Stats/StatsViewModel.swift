import Foundation

struct GameStat: Identifiable {
    var id: String { "\(gameID)-\(difficulty)" }
    let gameID: String
    let gameName: String
    let difficulty: String
    let playCount: Int
    let bestMoves: Int?
    let averageMoves: Double?
    let lastPlayed: Date?
}

struct GameGroup: Identifiable {
    var id: String { gameName }
    let gameName: String
    let totalPlays: Int
    let stats: [GameStat]   // one entry per difficulty, sorted
}

@MainActor
final class StatsViewModel: ObservableObject {
    private let store: any ScoreStoring

    @Published private(set) var groups: [GameGroup] = []
    @Published private(set) var totalWins: Int = 0

    init(store: any ScoreStoring) {
        self.store = store
        refresh()
    }

    func refresh() {
        let all = store.allScores()
        totalWins = all.count

        let byName = Dictionary(grouping: all) { $0.gameName }
        groups = byName.map { name, scores in
            let byDiff = Dictionary(grouping: scores) { $0.difficulty }
            let stats = byDiff.map { diff, diffScores -> GameStat in
                let moves = diffScores.compactMap { $0.moves }
                let avg = moves.isEmpty ? nil as Double? : Double(moves.reduce(0, +)) / Double(moves.count)
                return GameStat(
                    gameID: diffScores[0].gameID,
                    gameName: name,
                    difficulty: diff,
                    playCount: diffScores.count,
                    bestMoves: moves.min(),
                    averageMoves: avg,
                    lastPlayed: diffScores.map { $0.completedAt }.max()
                )
            }.sorted { $0.difficulty < $1.difficulty }

            return GameGroup(gameName: name, totalPlays: scores.count, stats: stats)
        }.sorted { $0.gameName < $1.gameName }
    }
}
