import Foundation

final class ScoreRepository: ScoreStoring, @unchecked Sendable {
    private let key = "com.swiftgames.scores.v1"

    func record(_ score: GameScore) {
        var all = allScores()
        all.append(score)
        guard let data = try? JSONEncoder().encode(all) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func allScores() -> [GameScore] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let scores = try? JSONDecoder().decode([GameScore].self, from: data)
        else { return [] }
        return scores
    }
}
