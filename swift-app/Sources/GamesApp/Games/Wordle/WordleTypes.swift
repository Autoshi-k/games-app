import Foundation

enum LetterState: String, Equatable, Codable {
    case correct
    case present
    case absent
}

struct GuessRow: Identifiable {
    let id = UUID()
    let word: String
    let feedback: [LetterState]
}

struct WordlePuzzle {
    let wordLength: Int
    let maxGuesses: Int
    let date: String       // display string, e.g. "May 22, 2026"
    let dateKey: String    // ISO key "yyyy-MM-dd" used for progress storage
}

struct WordleSolution {
    let word: String
}
