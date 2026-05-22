import Foundation

@MainActor
final class MemoryViewModel: ObservableObject {
    let puzzle: MemoryPuzzle

    @Published var faceUpIndices: Set<Int> = []
    @Published var matchedPairIDs: Set<Int> = []
    @Published var isLocked = false
    @Published var moves = 0
    @Published var isComplete = false

    private var pendingFirst: Int? = nil
    private var lastPair: (Int, Int)? = nil

    init(puzzle: MemoryPuzzle) {
        self.puzzle = puzzle
    }

    func isFaceUp(_ index: Int) -> Bool {
        faceUpIndices.contains(index) || isMatched(index)
    }

    func isMatched(_ index: Int) -> Bool {
        guard index < puzzle.cards.count else { return false }
        return matchedPairIDs.contains(puzzle.cards[index].pairID)
    }

    func tap(index: Int, onCheck: (GameAnswer) -> Void) {
        guard !isLocked, !isMatched(index), !faceUpIndices.contains(index) else { return }

        if let first = pendingFirst {
            faceUpIndices.insert(index)
            moves += 1
            isLocked = true
            lastPair = (first, index)
            pendingFirst = nil
            onCheck(.memory(firstIndex: first, secondIndex: index))
        } else {
            faceUpIndices.insert(index)
            pendingFirst = index
        }
    }

    func handleResult(_ result: GameResult?) {
        guard let result, let (first, second) = lastPair else { return }
        lastPair = nil

        if result.correct {
            matchedPairIDs.insert(puzzle.cards[first].pairID)
            faceUpIndices.remove(first)
            faceUpIndices.remove(second)
            isLocked = false
            isComplete = matchedPairIDs.count == puzzle.gridSize.pairCount
        } else {
            Task {
                try? await Task.sleep(for: .seconds(0.8))
                faceUpIndices.remove(first)
                faceUpIndices.remove(second)
                isLocked = false
            }
        }
    }
}
