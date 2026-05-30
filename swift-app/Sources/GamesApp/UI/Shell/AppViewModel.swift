import Foundation
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    let catalog: GameCatalog
    let scoreStore: ScoreRepository
    private let wordleProgress: WordleProgressRepository
    let games: [GameMetadata]

    @Published var selectedGameID: String
    @Published var config: [String: String]
    @Published var session: GameSession?
    @Published var result: GameResult?
    @Published var hintText = ""
    @Published var errorText = ""
    @Published var isShowingGame = false
    @Published var currentGameName = ""
    @Published private(set) var todaysWordleProgress: WordleDayProgress?

    var selectedGame: GameMetadata? {
        games.first { $0.id == selectedGameID }
    }

    init(catalog: GameCatalog, scoreStore: ScoreRepository) {
        self.catalog = catalog
        self.scoreStore = scoreStore
        self.wordleProgress = WordleProgressRepository()
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
        if id == "wordle", let session, case let .wordle(puzzle) = session.state {
            todaysWordleProgress = wordleProgress.load(forDate: puzzle.dateKey)
        } else {
            todaysWordleProgress = nil
        }
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
            if result?.correct == true, case .battleships = answer {
                recordGameWin(moves: nil)
            }
        } catch {
            let message = String(describing: error)
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

    func saveWordleProgress(_ progress: WordleDayProgress) {
        wordleProgress.save(progress)
        todaysWordleProgress = progress
    }

    func recordGameWin(moves: Int?) {
        guard let session else { return }
        scoreStore.record(GameScore(
            gameID: session.gameID,
            gameName: currentGameName,
            difficulty: currentDifficulty(),
            completedAt: Date(),
            moves: moves
        ))
    }

    // MARK: - Private

    private func currentDifficulty() -> String {
        if let d = config["difficulty"] { return d.capitalized }
        if let size = config["size"] { return size == "6x6" ? "Hard" : "Normal" }
        return "Normal"
    }
}
