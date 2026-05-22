import SwiftUI

struct WordleView: View {
    let session: GameSession
    let puzzle: WordlePuzzle
    let result: GameResult?
    let errorText: String
    let onCheck: (GameAnswer) -> Void

    @StateObject private var vm: WordleViewModel

    init(
        session: GameSession,
        puzzle: WordlePuzzle,
        result: GameResult?,
        errorText: String,
        onCheck: @escaping (GameAnswer) -> Void
    ) {
        self.session = session
        self.puzzle = puzzle
        self.result = result
        self.errorText = errorText
        self.onCheck = onCheck
        _vm = StateObject(wrappedValue: WordleViewModel(puzzle: puzzle))
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(puzzle.date.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer()

            WordleGridView(
                guessHistory: vm.guessHistory,
                currentInput: vm.currentInput,
                wordLength: puzzle.wordLength,
                maxGuesses: puzzle.maxGuesses
            )
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            ZStack {
                if vm.gameOver {
                    gameOverMessage
                }
                if let toast = vm.toastMessage {
                    WordleToastView(message: toast)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .frame(height: 50)
            .padding(.bottom, 6)

            WordleKeyboardView(
                keyboardState: vm.keyboardState,
                onLetter: vm.appendLetter,
                onDelete: vm.deleteLetter,
                onSubmit: { vm.submitWord(onCheck: onCheck) }
            )
            .padding(.bottom, 20)
        }
        .onChange(of: result) { newResult in
            vm.handleResult(newResult)
        }
        .onChange(of: errorText) { error in
            if !error.isEmpty {
                vm.showToast("Not in word list")
            }
        }
    }

    @ViewBuilder
    private var gameOverMessage: some View {
        if vm.won {
            Text("Well done!")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.green)
        } else {
            VStack(spacing: 2) {
                Text("Better luck tomorrow!")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
                if let word = vm.targetWord {
                    Text("The word was \(word.uppercased())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct WordleToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.callout)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.82))
            .clipShape(Capsule())
    }
}

// MARK: - Grid

struct WordleGridView: View {
    let guessHistory: [GuessRow]
    let currentInput: [Character]
    let wordLength: Int
    let maxGuesses: Int

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<maxGuesses, id: \.self) { rowIndex in
                if rowIndex < guessHistory.count {
                    CompletedRowView(row: guessHistory[rowIndex])
                } else if rowIndex == guessHistory.count {
                    ActiveRowView(input: currentInput, wordLength: wordLength)
                } else {
                    EmptyRowView(wordLength: wordLength)
                }
            }
        }
    }
}

struct CompletedRowView: View {
    let row: GuessRow

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(row.word.uppercased().enumerated()), id: \.offset) { index, letter in
                WordleTile(letter: String(letter), state: .filled(row.feedback[index]))
            }
        }
    }
}

struct ActiveRowView: View {
    let input: [Character]
    let wordLength: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<wordLength, id: \.self) { i in
                let letter = i < input.count ? String(input[i]).uppercased() : ""
                WordleTile(letter: letter, state: .active)
            }
        }
    }
}

struct EmptyRowView: View {
    let wordLength: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<wordLength, id: \.self) { _ in
                WordleTile(letter: "", state: .empty)
            }
        }
    }
}

enum WordleTileState {
    case empty
    case active
    case filled(LetterState)
}

struct WordleTile: View {
    let letter: String
    let state: WordleTileState

    var body: some View {
        Text(letter)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(textColor)
            .frame(width: 52, height: 52)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor, lineWidth: 2)
            )
    }

    private var backgroundColor: Color {
        switch state {
        case .empty, .active:
            return .clear
        case .filled(let ls):
            switch ls {
            case .correct: return Color(red: 0.38, green: 0.67, blue: 0.38)
            case .present: return Color(red: 0.79, green: 0.65, blue: 0.22)
            case .absent:  return Color(red: 0.47, green: 0.47, blue: 0.47)
            }
        }
    }

    private var textColor: Color {
        switch state {
        case .empty:  return .clear
        case .active: return .primary
        case .filled: return .white
        }
    }

    private var borderColor: Color {
        switch state {
        case .empty:  return Color.gray.opacity(0.3)
        case .active: return Color.gray.opacity(0.6)
        case .filled: return .clear
        }
    }
}

// MARK: - Keyboard

struct WordleKeyboardView: View {
    let keyboardState: [Character: LetterState]
    let onLetter: (Character) -> Void
    let onDelete: () -> Void
    let onSubmit: () -> Void

    private let rows: [[String]] = [
        ["Q","W","E","R","T","Y","U","I","O","P"],
        ["A","S","D","F","G","H","J","K","L"],
        ["Enter","Z","X","C","V","B","N","M","⌫"]
    ]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 5) {
                    ForEach(row, id: \.self) { key in
                        WordleKeyButton(
                            label: key,
                            state: keyState(for: key),
                            action: { handleKey(key) }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private func keyState(for key: String) -> LetterState? {
        guard key.count == 1, let char = key.lowercased().first else { return nil }
        return keyboardState[char]
    }

    private func handleKey(_ key: String) {
        switch key {
        case "Enter": onSubmit()
        case "⌫":    onDelete()
        default:
            if let char = key.lowercased().first {
                onLetter(char)
            }
        }
    }
}

struct WordleKeyButton: View {
    let label: String
    let state: LetterState?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(state == nil ? Color.primary : Color.white)
                .frame(width: label.count > 1 ? 52 : 34, height: 44)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch state {
        case .correct: return Color(red: 0.38, green: 0.67, blue: 0.38)
        case .present: return Color(red: 0.79, green: 0.65, blue: 0.22)
        case .absent:  return Color(red: 0.47, green: 0.47, blue: 0.47)
        case nil:      return Color.gray.opacity(0.2)
        }
    }
}
