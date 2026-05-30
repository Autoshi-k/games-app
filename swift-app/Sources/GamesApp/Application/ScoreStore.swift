import Foundation

struct GameScore: Codable, Identifiable {
    var id = UUID()
    let gameID: String
    let gameName: String
    let difficulty: String
    let completedAt: Date
    let moves: Int?
}

protocol ScoreStoring {
    func record(_ score: GameScore)
    func allScores() -> [GameScore]
}
