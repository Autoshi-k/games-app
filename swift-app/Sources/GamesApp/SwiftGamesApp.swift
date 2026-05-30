import SwiftUI

@main
struct SwiftGamesApp: App {
    @StateObject private var model = AppViewModel(
        catalog: GameCatalog(games: [
            BattleshipsGame(),
            WordleGame(),
            MemoryGame()
        ]),
        scoreStore: ScoreRepository()
    )

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }
}
