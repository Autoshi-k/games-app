import Foundation
import Combine
import SwiftUI

@MainActor
final class WordleViewModel: ObservableObject {
    @Published var currentInput: [Character] = []
    @Published var guessHistory: [GuessRow] = []
    @Published var keyboardState: [Character: LetterState] = [:]
    @Published var gameOver = false
    @Published var won = false
    @Published var targetWord: String?
    @Published var toastMessage: String?

    private let maxGuesses: Int
    private let wordLength: Int
    private let dateKey: String
    var onStateChanged: ((WordleDayProgress) -> Void)?

    init(puzzle: WordlePuzzle, savedProgress: WordleDayProgress? = nil) {
        self.maxGuesses = puzzle.maxGuesses
        self.wordLength = puzzle.wordLength
        self.dateKey = puzzle.dateKey

        if let progress = savedProgress {
            guessHistory = progress.guesses.map { GuessRow(word: $0.word, feedback: $0.feedback) }
            won = progress.won
            gameOver = progress.gameOver
            targetWord = progress.revealedWord
            for row in guessHistory { updateKeyboard(row) }
        }
    }

    var canSubmit: Bool {
        currentInput.count == wordLength && !gameOver
    }

    func appendLetter(_ letter: Character) {
        guard currentInput.count < wordLength, !gameOver else { return }
        currentInput.append(letter)
    }

    func deleteLetter() {
        guard !currentInput.isEmpty else { return }
        currentInput.removeLast()
    }

    func submitWord(onCheck: (GameAnswer) -> Void) {
        guard canSubmit else { return }
        onCheck(.wordle(guess: String(currentInput)))
    }

    func handleResult(_ result: GameResult?) {
        guard let result else { return }
        guard !currentInput.isEmpty else { return }

        let guess = String(currentInput)
        let feedback = parseFeedback(result.message)
        guard feedback.count == wordLength else { return }

        let row = GuessRow(word: guess, feedback: feedback)
        guessHistory.append(row)
        updateKeyboard(row)
        currentInput = []

        if result.correct {
            won = true
            gameOver = true
        } else if guessHistory.count >= maxGuesses {
            targetWord = result.expected?.first
            gameOver = true
        }

        notifyStateChanged()
    }

    func showToast(_ message: String) {
        withAnimation(.spring(duration: 0.2)) {
            toastMessage = message
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.25)) {
                toastMessage = nil
            }
        }
    }

    // MARK: - Private

    private func notifyStateChanged() {
        onStateChanged?(WordleDayProgress(
            dateKey: dateKey,
            guesses: guessHistory.map { WordleGuess(word: $0.word, feedback: $0.feedback) },
            won: won,
            gameOver: gameOver,
            revealedWord: targetWord
        ))
    }

    private func parseFeedback(_ message: String) -> [LetterState] {
        message.map { char in
            switch char {
            case "C": return .correct
            case "P": return .present
            default:  return .absent
            }
        }
    }

    private func updateKeyboard(_ row: GuessRow) {
        for (letter, state) in zip(row.word, row.feedback) {
            let existing = keyboardState[letter]
            if existing == .correct { continue }
            if existing == .present && state == .absent { continue }
            keyboardState[letter] = state
        }
    }
}
