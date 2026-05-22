import Foundation

struct MemoryGame: Game {
    var metadata: GameMetadata {
        GameMetadata(
            id: "memory",
            name: "Memory",
            description: "Flip cards to find matching pairs.",
            tags: ["memory", "card"],
            difficulty: "Normal",
            viewKind: "memory",
            inputSchema: [],
            defaults: ["style": "numbers", "size": "4x4"]
        )
    }

    func createGame(config: [String: String]) throws -> GameSession {
        let gridSize = MemoryGridSize(rawValue: config["size"] ?? "4x4") ?? .small
        let style = MemoryCardStyle(rawValue: config["style"] ?? "numbers") ?? .numbers

        let labels: [String] = style == .numbers
            ? generateNumbers(pairCount: gridSize.pairCount)
            : generateImageNames(pairCount: gridSize.pairCount)

        var flat: [(pairID: Int, label: String)] = []
        for (i, label) in labels.enumerated() {
            flat.append((i, label))
            flat.append((i, label))
        }

        let shuffled = flat.shuffled()
        let cards = shuffled.enumerated().map { idx, pair in
            MemoryCard(id: idx, pairID: pair.pairID, label: pair.label)
        }

        let puzzle = MemoryPuzzle(gridSize: gridSize, style: style, cards: cards)
        let diffName = gridSize == .small ? "Normal" : "Hard"

        return GameSession(
            id: UUID().uuidString,
            gameID: "memory",
            title: "Memory — \(diffName)",
            prompt: "Flip cards to find all \(gridSize.pairCount) matching pairs.",
            state: .memory(puzzle),
            privateState: .memory(MemorySolution()),
            createdAt: Date()
        )
    }

    func validate(session: GameSession) throws {
        guard case .memory = session.state else { throw GameError.invalidSession }
    }

    func checkResult(session: GameSession, answer: GameAnswer) throws -> GameResult {
        guard case let .memory(puzzle) = session.state,
              case let .memory(firstIndex: a, secondIndex: b) = answer
        else { throw GameError.invalidAnswer }

        guard a < puzzle.cards.count, b < puzzle.cards.count else { throw GameError.invalidAnswer }

        let matched = puzzle.cards[a].pairID == puzzle.cards[b].pairID
        return GameResult(
            correct: matched,
            message: matched ? "Match!" : "No match",
            score: matched ? 10 : 0,
            expected: nil
        )
    }

    func hint(session: GameSession, level: Int) throws -> HintResult {
        HintResult(message: "No hints in Memory", cost: 0)
    }

    // MARK: - Number generation

    private func generateNumbers(pairCount: Int) -> [String] {
        let theme = Int.random(in: 0...9)
        var seenNonTheme: Set<Int> = []
        var used = Set<String>()
        var results: [String] = []
        var attempts = 0

        while results.count < pairCount, attempts < 10_000 {
            attempts += 1
            let number = makeNumber(theme: theme, seenNonTheme: seenNonTheme)
            guard !used.contains(number) else { continue }
            used.insert(number)
            results.append(number)
            for ch in number {
                if let d = ch.wholeNumberValue, d != theme {
                    seenNonTheme.insert(d)
                }
            }
        }

        return results
    }

    private func makeNumber(theme: Int, seenNonTheme: Set<Int>) -> String {
        let length = Bool.random() ? 3 : 4
        return (0..<length).map { _ in String(weightedDigit(theme: theme, seenNonTheme: seenNonTheme)) }.joined()
    }

    // Theme digit → 50 %. Already-seen non-theme → share 40 % equally.
    // Unseen digits → share the remaining 10 % (or 50 % if no seen non-theme yet).
    private func weightedDigit(theme: Int, seenNonTheme: Set<Int>) -> Int {
        let unseen = Set(0...9).subtracting(seenNonTheme).subtracting([theme])
        var weights: [(Int, Double)] = [(theme, 50.0)]

        if !seenNonTheme.isEmpty {
            let each = 40.0 / Double(seenNonTheme.count)
            for d in seenNonTheme { weights.append((d, each)) }
        }

        let unseenPool = seenNonTheme.isEmpty ? 50.0 : 10.0
        if !unseen.isEmpty {
            let each = unseenPool / Double(unseen.count)
            for d in unseen { weights.append((d, each)) }
        }

        let total = weights.reduce(0.0) { $0 + $1.1 }
        let roll = Double.random(in: 0..<total)
        var cursor = 0.0
        for (digit, w) in weights {
            cursor += w
            if roll < cursor { return digit }
        }
        return theme
    }

    // MARK: - Image name generation

    private func generateImageNames(pairCount: Int) -> [String] {
        (0..<pairCount).map { String(format: "memory_card_%02d", $0 + 1) }
    }
}
