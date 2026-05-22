import Foundation

enum LetterState: Equatable {
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
    let date: String
}

struct WordleSolution {
    let word: String
}
