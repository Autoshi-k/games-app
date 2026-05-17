import SwiftUI

@main
struct SwiftGamesApp: App {
    @StateObject private var model = AppViewModel(
        catalog: GameCatalog(games: [
            BattleshipsGame()
        ])
    )

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }
}
