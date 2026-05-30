import SwiftUI

// MARK: - Root

struct ContentView: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        NavigationStack {
            CatalogScreen(model: model)
                .navigationDestination(isPresented: $model.isShowingGame) {
                    GameSessionScreen(model: model)
                }
        }
    }
}

// MARK: - Catalog data

struct DifficultyOption {
    let label: String
    let config: [String: String]
}

struct GameEntry: Identifiable {
    let id = UUID()
    let gameID: String
    let name: String
    let description: String
    let difficulty: String       // static badge; overridden by selection when difficulties != nil
    let accentColor: Color
    let iconName: String
    let config: [String: String] // used when difficulties is nil
    let difficulties: [DifficultyOption]?
}

let allGameEntries: [GameEntry] = [
    GameEntry(
        gameID: "battleships",
        name: "Battleships",
        description: "Locate a hidden fleet on a 10×10 grid using row and column ship counts.",
        difficulty: "Normal",
        accentColor: .blue,
        iconName: "mappin.and.ellipse",
        config: ["difficulty": "medium"],
        difficulties: [
            DifficultyOption(label: "Normal", config: ["difficulty": "medium"]),
            DifficultyOption(label: "Hard",   config: ["difficulty": "hard"])
        ]
    ),
    GameEntry(
        gameID: "wordle",
        name: "Wordle",
        description: "Guess the 5-letter word in 6 tries. A new word every day.",
        difficulty: "Daily",
        accentColor: .green,
        iconName: "textformat.abc",
        config: [:],
        difficulties: nil
    ),
    GameEntry(
        gameID: "memory",
        name: "Memory — Numbers",
        description: "Flip cards to find matching number pairs. A themed digit shapes every number.",
        difficulty: "Normal",
        accentColor: .purple,
        iconName: "number.square.fill",
        config: ["style": "numbers", "size": "4x4"],
        difficulties: [
            DifficultyOption(label: "Normal", config: ["style": "numbers", "size": "4x4"]),
            DifficultyOption(label: "Hard",   config: ["style": "numbers", "size": "6x6"])
        ]
    ),
    GameEntry(
        gameID: "memory",
        name: "Memory — Images",
        description: "Flip cards to match image pairs.",
        difficulty: "Normal",
        accentColor: .orange,
        iconName: "photo.on.rectangle",
        config: ["style": "images", "size": "4x4"],
        difficulties: [
            DifficultyOption(label: "Normal", config: ["style": "images", "size": "4x4"]),
            DifficultyOption(label: "Hard",   config: ["style": "images", "size": "6x6"])
        ]
    ),
]

// MARK: - Catalog Screen

struct CatalogScreen: View {
    @ObservedObject var model: AppViewModel
    @State private var selectedDifficulties: [UUID: Int] = [:]
    @State private var showStats = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Games")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Tap a game to start playing")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { showStats = true } label: {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.orange)
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 8)

                VStack(spacing: 16) {
                    ForEach(allGameEntries) { entry in
                        let selIdx = selectedDifficulties[entry.id] ?? 0
                        GameEntryRow(
                            entry: entry,
                            selectedDifficultyIndex: Binding(
                                get: { selectedDifficulties[entry.id] ?? 0 },
                                set: { selectedDifficulties[entry.id] = $0 }
                            ),
                            onTap: {
                                let config = entry.difficulties?[selIdx].config ?? entry.config
                                model.startGame(id: entry.gameID, name: entry.name, config: config)
                            }
                        )
                    }
                }
            }
            .padding(20)
        }
        .navigationBarHidden(true)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showStats) {
            StatsView(store: model.scoreStore)
        }
    }
}

// MARK: - Entry Row (card + optional difficulty picker)

struct GameEntryRow: View {
    let entry: GameEntry
    @Binding var selectedDifficultyIndex: Int
    let onTap: () -> Void

    private var badgeText: String {
        entry.difficulties?[selectedDifficultyIndex].label ?? entry.difficulty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GameEntryCard(entry: entry, badgeText: badgeText, onTap: onTap)

            if let difficulties = entry.difficulties {
                HStack(spacing: 8) {
                    ForEach(Array(difficulties.enumerated()), id: \.offset) { idx, diff in
                        Button(action: { selectedDifficultyIndex = idx }) {
                            Text(diff.label)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    idx == selectedDifficultyIndex
                                        ? entry.accentColor.opacity(0.12)
                                        : Color.clear
                                )
                                .foregroundStyle(
                                    idx == selectedDifficultyIndex
                                        ? entry.accentColor
                                        : Color.secondary
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().strokeBorder(
                                        idx == selectedDifficultyIndex
                                            ? entry.accentColor.opacity(0.4)
                                            : Color.secondary.opacity(0.25),
                                        lineWidth: 1
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                        .opacity(idx == selectedDifficultyIndex ? 1 : 0.45)
                        .animation(.easeInOut(duration: 0.15), value: selectedDifficultyIndex)
                        .padding(.leading, idx == 0 ? 75 : 0)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Entry Card

struct GameEntryCard: View {
    let entry: GameEntry
    let badgeText: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(entry.accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: entry.iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(entry.accentColor)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(entry.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(badgeText)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(entry.accentColor.opacity(0.12))
                            .foregroundStyle(entry.accentColor)
                            .clipShape(Capsule())
                    }

                    Text(entry.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Game Session Screen

struct GameSessionScreen: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        Group {
            if let session = model.session {
                if case let .wordle(puzzle) = session.state {
                    WordleView(
                        session: session,
                        puzzle: puzzle,
                        result: model.result,
                        errorText: model.errorText,
                        onCheck: model.check,
                        onGameWon: { guesses in model.recordGameWin(moves: guesses) },
                        savedProgress: model.todaysWordleProgress,
                        onStateChanged: model.saveWordleProgress
                    )
                    .id(session.id)
                } else if case let .memory(puzzle) = session.state {
                    MemoryView(
                        session: session,
                        puzzle: puzzle,
                        result: model.result,
                        onCheck: model.check,
                        onPlayAgain: model.createGame,
                        onGameWon: { moves in model.recordGameWin(moves: moves) }
                    )
                    .id(session.id)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            GameSessionView(
                                session: session,
                                result: model.result,
                                hintText: model.hintText,
                                onCheck: model.check,
                                onHint: model.requestHint
                            )
                            .padding(20)

                            if !model.errorText.isEmpty {
                                Text(model.errorText)
                                    .font(.callout)
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(model.currentGameName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

// MARK: - Game Session Router (Battleships fallback)

struct GameSessionView: View {
    let session: GameSession
    let result: GameResult?
    let hintText: String
    let onCheck: (GameAnswer) -> Void
    let onHint: () -> Void

    var body: some View {
        switch session.state {
        case let .battleships(puzzle):
            BattleshipsView(
                session: session,
                puzzle: puzzle,
                result: result,
                hintText: hintText,
                onCheck: onCheck,
                onHint: onHint
            )
            .id(session.id)
        case let .wordle(puzzle):
            WordleView(
                session: session,
                puzzle: puzzle,
                result: result,
                errorText: "",
                onCheck: onCheck
            )
            .id(session.id)
        case let .memory(puzzle):
            MemoryView(
                session: session,
                puzzle: puzzle,
                result: result,
                onCheck: onCheck,
                onPlayAgain: {}
            )
            .id(session.id)
        }
    }
}

// MARK: - Colors

enum AppColors {
    static let windowBackground = Color(.systemBackground)
    static let controlBackground = Color(.secondarySystemBackground)
}
