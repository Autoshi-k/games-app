import SwiftUI

// MARK: - Root

struct MemoryView: View {
    let session: GameSession
    let puzzle: MemoryPuzzle
    let result: GameResult?
    let onCheck: (GameAnswer) -> Void
    let onPlayAgain: () -> Void
    let onGameWon: (Int) -> Void

    @StateObject private var vm: MemoryViewModel

    init(
        session: GameSession,
        puzzle: MemoryPuzzle,
        result: GameResult?,
        onCheck: @escaping (GameAnswer) -> Void,
        onPlayAgain: @escaping () -> Void,
        onGameWon: @escaping (Int) -> Void = { _ in }
    ) {
        self.session = session
        self.puzzle = puzzle
        self.result = result
        self.onCheck = onCheck
        self.onPlayAgain = onPlayAgain
        self.onGameWon = onGameWon
        _vm = StateObject(wrappedValue: MemoryViewModel(puzzle: puzzle))
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: puzzle.gridSize.columns)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    statsBar
                    LazyVGrid(columns: gridColumns, spacing: 8) {
                        ForEach(puzzle.cards) { card in
                            MemoryCardView(
                                card: card,
                                style: puzzle.style,
                                gridSize: puzzle.gridSize,
                                isFaceUp: vm.isFaceUp(card.id),
                                isMatched: vm.isMatched(card.id)
                            )
                            .aspectRatio(1, contentMode: .fit)
                            .onTapGesture { vm.tap(index: card.id, onCheck: onCheck) }
                        }
                    }
                }
                .padding(16)
            }

            if vm.isComplete {
                MemoryWinOverlay(
                    moves: vm.moves,
                    pairCount: puzzle.gridSize.pairCount,
                    onPlayAgain: onPlayAgain
                )
            }
        }
        .onChange(of: result) { newResult in
            vm.handleResult(newResult)
        }
        .onChange(of: vm.isComplete) { isComplete in
            if isComplete { onGameWon(vm.moves) }
        }
    }

    private var statsBar: some View {
        HStack {
            Label("\(vm.moves) moves", systemImage: "hand.tap")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(vm.matchedPairIDs.count) / \(puzzle.gridSize.pairCount) pairs")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Card View

private let placeholderSymbols: [String] = [
    "star.fill", "heart.fill", "circle.fill", "triangle.fill",
    "square.fill", "diamond.fill", "bolt.fill", "flame.fill",
    "leaf.fill", "moon.fill", "sun.max.fill", "cloud.fill",
    "drop.fill", "snowflake", "wind", "tornado",
    "ant.fill", "ladybug.fill"
]

struct MemoryCardView: View {
    let card: MemoryCard
    let style: MemoryCardStyle
    let gridSize: MemoryGridSize
    let isFaceUp: Bool
    let isMatched: Bool

    var body: some View {
        ZStack {
            // Card back
            RoundedRectangle(cornerRadius: 12)
                .fill(isMatched ? Color.green.opacity(0.25) : Color.indigo.opacity(0.75))
                .overlay(
                    Image(systemName: "questionmark")
                        .font(.system(size: gridSize == .small ? 20 : 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .opacity(isMatched ? 0 : 1)
                )
                .opacity(isFaceUp ? 0 : 1)
                .rotation3DEffect(.degrees(isFaceUp ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.4)

            // Card front — hidden when face-down so content never bleeds through
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isMatched ? Color.green.opacity(0.55) : Color.clear, lineWidth: 2)
                )
                .overlay(frontContent)
                .opacity(isFaceUp ? 1 : 0)
                .rotation3DEffect(.degrees(isFaceUp ? 0 : -180), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isFaceUp)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isMatched)
    }

    @ViewBuilder
    private var frontContent: some View {
        switch style {
        case .numbers:
            Text(card.label)
                .font(.system(
                    size: gridSize == .small ? 16 : 11,
                    weight: .bold,
                    design: .monospaced
                ))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(6)

        case .images:
            Group {
                if UIImage(named: card.label) != nil {
                    Image(card.label)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    Image(systemName: placeholderSymbols[card.pairID % placeholderSymbols.count])
                        .font(.system(size: gridSize == .small ? 28 : 18))
                        .foregroundStyle(.indigo)
                }
            }
        }
    }
}

// MARK: - Win Overlay

struct MemoryWinOverlay: View {
    let moves: Int
    let pairCount: Int
    let onPlayAgain: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).opacity(0.82)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 56))

                VStack(spacing: 8) {
                    Text("All pairs found!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(pairCount) pairs · \(moves) moves")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button(action: onPlayAgain) {
                    Text("Play Again")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.indigo)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 4)
            }
            .padding(28)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
            .padding(40)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
