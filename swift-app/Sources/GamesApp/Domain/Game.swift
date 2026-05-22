import Foundation

enum GameError: Error, Equatable {
    case gameNotFound
    case invalidSession
    case invalidAnswer
}

enum InputFieldType: String, Equatable {
    case select
    case number
    case text
}

struct InputField: Identifiable, Equatable {
    let id: String
    let label: String
    let type: InputFieldType
    let required: Bool
    let options: [String]
    let placeholder: String
}

struct GameMetadata: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let tags: [String]
    let difficulty: String
    let viewKind: String
    let inputSchema: [InputField]
    let defaults: [String: String]
}

struct GameSession: Identifiable {
    let id: String
    let gameID: String
    let title: String
    let prompt: String
    let state: GameState
    let privateState: PrivateGameState
    let createdAt: Date
}

enum GameState {
    case battleships(BattleshipsPuzzle)
    case wordle(WordlePuzzle)
    case memory(MemoryPuzzle)
}

enum PrivateGameState {
    case battleships(BattleshipsSolution)
    case wordle(WordleSolution)
    case memory(MemorySolution)
}

enum GameAnswer {
    case battleships(shipCoordinates: [String])
    case wordle(guess: String)
    case memory(firstIndex: Int, secondIndex: Int)
}

struct GameResult: Equatable {
    let id = UUID()
    let correct: Bool
    let message: String
    let score: Int
    let expected: [String]?

    static func == (lhs: GameResult, rhs: GameResult) -> Bool {
        lhs.id == rhs.id
    }
}

struct HintResult {
    let message: String
    let cost: Int
}

protocol Game {
    var metadata: GameMetadata { get }

    func createGame(config: [String: String]) throws -> GameSession
    func validate(session: GameSession) throws
    func checkResult(session: GameSession, answer: GameAnswer) throws -> GameResult
    func hint(session: GameSession, level: Int) throws -> HintResult
}
