import Foundation

final class GameCatalog {
    private let games: [any Game]

    init(games: [any Game]) {
        self.games = games
    }

    var metadata: [GameMetadata] {
        games.map(\.metadata)
    }

    func game(withID id: String) -> (any Game)? {
        games.first { $0.metadata.id == id }
    }

    func createGame(gameID: String, config: [String: String]) throws -> GameSession {
        guard let game = game(withID: gameID) else {
            throw GameError.gameNotFound
        }

        return try game.createGame(config: config)
    }

    func checkResult(session: GameSession, answer: GameAnswer) throws -> GameResult {
        guard let game = game(withID: session.gameID) else {
            throw GameError.gameNotFound
        }

        return try game.checkResult(session: session, answer: answer)
    }

    func hint(session: GameSession, level: Int) throws -> HintResult {
        guard let game = game(withID: session.gameID) else {
            throw GameError.gameNotFound
        }

        return try game.hint(session: session, level: level)
    }
}
