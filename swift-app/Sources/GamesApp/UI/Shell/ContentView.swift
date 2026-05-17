import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CatalogView(model: model)

                Divider()

                WorkspaceView(model: model)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(AppColors.windowBackground)
    }
}

struct CatalogView: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Games App")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text("Generated games")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }

            VStack(spacing: 10) {
                ForEach(model.games) { game in
                    Button(action: {
                        model.chooseGame(game)
                    }) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(game.name)
                                .fontWeight(.semibold)
                            Text(game.description)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                            Text(game.difficulty)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(cardBackground(for: game))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(24)
        .background(AppColors.controlBackground)
    }

    private func cardBackground(for game: GameMetadata) -> Color {
        game.id == model.selectedGameID ? Color.teal.opacity(0.18) : Color.white
    }
}

struct WorkspaceView: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if let selectedGame = model.selectedGame {
                WorkspaceHeader(game: selectedGame)
                ConfigView(model: model, game: selectedGame)

                if let session = model.session {
                    GameSessionView(
                        session: session,
                        result: model.result,
                        hintText: model.hintText,
                        onCheck: model.check,
                        onHint: model.requestHint
                    )
                }

                if !model.errorText.isEmpty {
                    Text(model.errorText)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WorkspaceHeader: View {
    let game: GameMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(game.viewKind)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(game.name)
                    .font(.title)
                    .fontWeight(.bold)
            }

            HStack {
                ForEach(game.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.14))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

struct ConfigView: View {
    @ObservedObject var model: AppViewModel
    let game: GameMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(game.inputSchema) { field in
                VStack(alignment: .leading, spacing: 6) {
                    Text(field.label)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    switch field.type {
                    case .select:
                        Picker(field.label, selection: configBinding(for: field.id)) {
                            ForEach(field.options, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 160)
                    case .number, .text:
                        TextField(field.placeholder, text: configBinding(for: field.id))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                    }
                }
            }

            Button("Create game") {
                model.createGame()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func configBinding(for key: String) -> Binding<String> {
        Binding {
            model.config[key] ?? ""
        } set: { value in
            model.config[key] = value
        }
    }
}

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
        }
    }
}

enum AppColors {
    static var windowBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(.systemBackground)
        #endif
    }

    static var controlBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(.secondarySystemBackground)
        #endif
    }
}
