import Foundation

enum MemoryGridSize: String, Equatable {
    case small = "4x4"
    case large = "6x6"

    var columns: Int { self == .small ? 4 : 6 }
    var cardCount: Int { columns * columns }
    var pairCount: Int { cardCount / 2 }
}

enum MemoryCardStyle: String, Equatable {
    case numbers
    case images
}

struct MemoryCard: Identifiable, Equatable {
    let id: Int      // grid index (0-based)
    let pairID: Int  // cards with the same pairID are a matching pair
    let label: String
}

struct MemoryPuzzle: Equatable {
    let gridSize: MemoryGridSize
    let style: MemoryCardStyle
    let cards: [MemoryCard]
}

struct MemorySolution: Equatable {}
