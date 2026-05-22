import Foundation

struct WordleGame: Game {
    var metadata: GameMetadata {
        GameMetadata(
            id: "wordle",
            name: "Wordle",
            description: "Guess the 5-letter word in 6 tries. A new word every day.",
            tags: ["word", "daily"],
            difficulty: "Medium",
            viewKind: "wordle",
            inputSchema: [],
            defaults: [:]
        )
    }

    func createGame(config: [String: String]) throws -> GameSession {
        let word = try todaysWord()

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: Date())

        let puzzle = WordlePuzzle(wordLength: 5, maxGuesses: 6, date: dateString)
        let solution = WordleSolution(word: word)

        return GameSession(
            id: UUID().uuidString,
            gameID: "wordle",
            title: "Daily Wordle — \(dateString)",
            prompt: "Guess the 5-letter word in 6 tries.",
            state: .wordle(puzzle),
            privateState: .wordle(solution),
            createdAt: Date()
        )
    }

    func validate(session: GameSession) throws {
        guard case .wordle = session.state else {
            throw GameError.invalidSession
        }
    }

    func checkResult(session: GameSession, answer: GameAnswer) throws -> GameResult {
        guard case let .wordle(solution) = session.privateState,
              case let .wordle(guess: guessWord) = answer
        else {
            throw GameError.invalidAnswer
        }

        let guess = guessWord.lowercased()
        let target = solution.word.lowercased()

        guard guess.count == 5 else {
            throw GameError.invalidAnswer
        }

        let validWords = try loadWords()
        guard validWords.contains(guess) else {
            throw GameError.invalidAnswer
        }

        let feedback = computeFeedback(guess: guess, target: target)
        let isCorrect = feedback.allSatisfy { $0 == .correct }
        let feedbackString = feedback.map { state -> String in
            switch state {
            case .correct: return "C"
            case .present: return "P"
            case .absent: return "A"
            }
        }.joined()

        return GameResult(
            correct: isCorrect,
            message: feedbackString,
            score: isCorrect ? 100 : 0,
            expected: isCorrect ? nil : [target]
        )
    }

    func hint(session: GameSession, level: Int) throws -> HintResult {
        guard case let .wordle(solution) = session.privateState else {
            throw GameError.invalidSession
        }

        let word = solution.word
        let index = min(level - 1, word.count - 1)
        let letter = String(word[word.index(word.startIndex, offsetBy: index)])

        return HintResult(
            message: "Letter \(index + 1) is '\(letter.uppercased())'",
            cost: level * 10
        )
    }

    // MARK: - Private

    private func todaysWord() throws -> String {
        let words = try loadWords()
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let today = calendar.startOfDay(for: Date())
        let dayIndex = calendar.dateComponents([.day], from: referenceDate, to: today).day ?? 0
        return words[abs(dayIndex) % words.count]
    }

    private func loadWords() throws -> [String] {
        guard let url = Bundle.main.url(forResource: "words", withExtension: "json") else {
            throw GameError.gameNotFound
        }
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode([String: [String]].self, from: data)
        guard let words = decoded["words"] else { throw GameError.gameNotFound }
        // Sort alphabetically so every device picks the same daily answer.
        return words.sorted()
    }

    private func computeFeedback(guess: String, target: String) -> [LetterState] {
        var result = Array(repeating: LetterState.absent, count: 5)
        var targetChars = Array(target)
        let guessChars = Array(guess)

        // First pass: exact matches
        for i in 0..<5 {
            if guessChars[i] == targetChars[i] {
                result[i] = .correct
                targetChars[i] = " "
            }
        }

        // Second pass: present-but-wrong-position
        for i in 0..<5 {
            guard result[i] != .correct else { continue }
            if let j = targetChars.firstIndex(of: guessChars[i]) {
                result[i] = .present
                targetChars[j] = " "
            }
        }

        return result
    }
}
