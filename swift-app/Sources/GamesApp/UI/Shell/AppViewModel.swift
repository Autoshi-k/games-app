import Foundation
import Combine

final class AppViewModel: ObservableObject {
    let catalog: GameCatalog
    let games: [GameMetadata]

    @Published var selectedGameID: String
    @Published var config: [String: String]
    @Published var session: GameSession?
    @Published var result: GameResult?
    @Published var hintText = ""
    @Published var errorText = ""

    var selectedGame: GameMetadata? {
        games.first { $0.id == selectedGameID }
    }

    init(catalog: GameCatalog) {
        self.catalog = catalog
        self.games = catalog.metadata
        self.selectedGameID = games.first?.id ?? ""
        self.config = games.first?.defaults ?? [:]
    }

    func chooseGame(_ game: GameMetadata) {
        selectedGameID = game.id
        config = game.defaults
        session = nil
        result = nil
        hintText = ""
        errorText = ""
    }

    func createGame() {
        guard let selectedGame else {
            return
        }

        do {
            errorText = ""
            result = nil
            hintText = ""
            session = try catalog.createGame(gameID: selectedGame.id, config: config)
        } catch {
            errorText = String(describing: error)
        }
    }

    func check(answer: GameAnswer) {
        guard let session else {
            return
        }

        do {
            errorText = ""
            result = try catalog.checkResult(session: session, answer: answer)
        } catch {
            errorText = String(describing: error)
        }
    }

    func requestHint() {
        guard let session else {
            return
        }

        do {
            errorText = ""
            let hint = try catalog.hint(session: session, level: hintText.isEmpty ? 1 : 2)
            hintText = "\(hint.message) (\(hint.cost) points)"
        } catch {
            errorText = String(describing: error)
        }
    }
}
