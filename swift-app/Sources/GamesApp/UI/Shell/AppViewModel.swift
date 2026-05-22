import Foundation
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    let catalog: GameCatalog
    let games: [GameMetadata]

    @Published var selectedGameID: String
    @Published var config: [String: String]
    @Published var session: GameSession?
    @Published var result: GameResult?
    @Published var hintText = ""
    @Published var errorText = ""
    @Published var isShowingGame = false
    @Published var currentGameName = ""

    var selectedGame: GameMetadata? {
        games.first { $0.id == selectedGameID }
    }

    init(catalog: GameCatalog) {
        self.catalog = catalog
        self.games = catalog.metadata
        self.selectedGameID = games.first?.id ?? ""
        self.config = games.first?.defaults ?? [:]
    }

    func startGame(id: String, name: String, config: [String: String]) {
        selectedGameID = id
        currentGameName = name
        self.config = config
        session = nil
        result = nil
        hintText = ""
        errorText = ""
        createGame()
        if session != nil {
            isShowingGame = true
        }
    }

    func createGame() {
        guard let selectedGame else { return }
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
        guard let session else { return }
        errorText = ""
        do {
            result = try catalog.checkResult(session: session, answer: answer)
        } catch {
            let message = String(describing: error)
            // Defer the error assignment so it arrives as a distinct @Published change,
            // allowing repeated invalid guesses to each trigger onChange in the view.
            Task { self.errorText = message }
        }
    }

    func requestHint() {
        guard let session else { return }
        do {
            errorText = ""
            let hint = try catalog.hint(session: session, level: hintText.isEmpty ? 1 : 2)
            hintText = "\(hint.message) (\(hint.cost) points)"
        } catch {
            errorText = String(describing: error)
        }
    }
}
