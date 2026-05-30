import Foundation

struct WordleGuess: Codable {
    let word: String
    let feedback: [LetterState]
}

struct WordleDayProgress: Codable {
    let dateKey: String     // "yyyy-MM-dd" — stale data from other days is ignored
    let guesses: [WordleGuess]
    let won: Bool
    let gameOver: Bool
    let revealedWord: String?
}

final class WordleProgressRepository {
    private let key = "com.swiftgames.wordle.progress"

    func load(forDate dateKey: String) -> WordleDayProgress? {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let progress = try? JSONDecoder().decode(WordleDayProgress.self, from: data),
            progress.dateKey == dateKey
        else { return nil }
        return progress
    }

    func save(_ progress: WordleDayProgress) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
