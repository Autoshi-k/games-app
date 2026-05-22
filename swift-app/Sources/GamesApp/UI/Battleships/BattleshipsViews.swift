import SwiftUI

struct BattleshipsView: View {
    let session: GameSession
    let puzzle: BattleshipsPuzzle
    let result: GameResult?
    let hintText: String
    let onCheck: (GameAnswer) -> Void
    let onHint: () -> Void

    @StateObject private var board: BattleshipsBoardViewModel

    init(
        session: GameSession,
        puzzle: BattleshipsPuzzle,
        result: GameResult?,
        hintText: String,
        onCheck: @escaping (GameAnswer) -> Void,
        onHint: @escaping () -> Void
    ) {
        self.session = session
        self.puzzle = puzzle
        self.result = result
        self.hintText = hintText
        self.onCheck = onCheck
        self.onHint = onHint
        _board = StateObject(wrappedValue: BattleshipsBoardViewModel(puzzle: puzzle))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(session.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(session.prompt)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: 16) {
                BattleshipsBoardView(board: board)
                BattleshipsFleetView(fleet: puzzle.fleet)
            }

            HStack(spacing: 12) {
                Button("Check solution") {
                    onCheck(.battleships(shipCoordinates: board.markedShipCoordinates))
                }
                .buttonStyle(.borderedProminent)
                .disabled(!board.canSubmit)

                Button("Hint", action: onHint)
                    .buttonStyle(.bordered)
            }

            FeedbackView(result: result, hintText: hintText)
        }
    }
}

struct BattleshipsBoardView: View {
    @ObservedObject var board: BattleshipsBoardViewModel

    var body: some View {
        GeometryReader { geometry in
            let cellSize = boardCellSize(in: geometry.size)

            Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                GridRow {
                    ForEach(0..<board.puzzle.boardSize, id: \.self) { col in
                        CountCell(
                            value: board.puzzle.columnCounts[col],
                            isComplete: board.countShipsInColumn(col) == board.puzzle.columnCounts[col],
                            size: cellSize
                        )
                    }
                    Color.clear.frame(width: cellSize, height: cellSize)
                }

                ForEach(0..<board.puzzle.boardSize, id: \.self) { row in
                    GridRow {
                        ForEach(0..<board.puzzle.boardSize, id: \.self) { col in
                            let coordinate = board.coordinate(row: row, col: col)
                            BattleCell(
                                coordinate: coordinate,
                                mark: board.mark(at: coordinate),
                                isFixed: board.isFixed(coordinate),
                                isHoveredComponent: board.hoveredCoordinates.contains(coordinate),
                                showsLinkButton: board.linkButtonCoordinate == coordinate && !board.editableHoveredComponent.isEmpty,
                                isLinked: board.hoveredComponentIsLinked,
                                onCycle: { board.cycleCell(coordinate) },
                                onHover: { board.setHoveredShipIfNeeded(coordinate) },
                                onToggleLink: { board.toggleLinkedShip() },
                                size: cellSize
                            )
                        }

                        CountCell(
                            value: board.puzzle.rowCounts[row],
                            isComplete: board.countShipsInRow(row) == board.puzzle.rowCounts[row],
                            size: cellSize
                        )
                    }
                }
            }
            .frame(width: boardDimension(in: geometry.size), height: boardDimension(in: geometry.size), alignment: .topLeading)
            #if os(macOS)
            .onHover { isHovering in
                if !isHovering {
                    board.clearHoveredShip()
                }
            }
            #endif
        }
        .frame(maxWidth: 492)
        .aspectRatio(1, contentMode: .fit)
    }

    private func boardCellSize(in size: CGSize) -> CGFloat {
        let spacing: CGFloat = 3
        let columns = CGFloat(board.puzzle.boardSize + 1)
        let gaps = CGFloat(board.puzzle.boardSize) * spacing
        return min(42, max(24, (boardDimension(in: size) - gaps) / columns))
    }

    private func boardDimension(in size: CGSize) -> CGFloat {
        min(size.width, size.height)
    }
}

struct BattleCell: View {
    let coordinate: String
    let mark: CellMark?
    let isFixed: Bool
    let isHoveredComponent: Bool
    let showsLinkButton: Bool
    let isLinked: Bool
    let onCycle: () -> Void
    let onHover: () -> Void
    let onToggleLink: () -> Void
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderColor, lineWidth: isHoveredComponent ? 2 : 1)
                )

            if mark == .water {
                Image(systemName: "drop.fill")
                    .font(.system(size: max(10, size * 0.38)))
                    .foregroundStyle(.blue)
            } else if let mark, mark.isShip {
                ShipPartView(shape: mark.shipPartShape)
                    .frame(width: max(12, size * 0.52), height: max(12, size * 0.52))
            }

            if showsLinkButton {
                Button(action: onToggleLink) {
                    Image(systemName: "link")
                        .font(.system(size: max(8, size * 0.24), weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: max(16, size * 0.52), height: max(16, size * 0.52), alignment: .bottomTrailing)
                        .background(Circle().fill(Color.primary))
                }
                .buttonStyle(.plain)
                .offset(x: size * 0.18, y: size * 0.18)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isFixed {
                onCycle()
            }
        }
        .accessibilityLabel("\(coordinate) \(mark?.rawValue ?? "empty")")
        #if os(macOS)
        .onHover { isHovering in
            if isHovering {
                onHover()
            }
        }
        #endif
    }

    private var backgroundColor: Color {
        if isFixed { return AppColors.controlBackground }
        if mark == .water { return Color.blue.opacity(0.12) }
        if mark?.isShip == true { return Color.orange.opacity(0.12) }
        return Color.white
    }

    private var borderColor: Color {
        if isHoveredComponent { return Color.primary }
        if isFixed { return Color.gray }
        if mark == .water { return Color.blue.opacity(0.45) }
        if mark?.isShip == true { return Color.orange.opacity(0.45) }
        return Color.gray.opacity(0.35)
    }
}

struct CountCell: View {
    let value: Int
    let isComplete: Bool
    let size: CGFloat

    var body: some View {
        Text("\(value)")
            .font(.system(size: max(11, size * 0.36), weight: .bold))
            .fontWeight(.bold)
            .foregroundStyle(isComplete ? .white : .primary)
            .frame(width: size, height: size)
            .background(isComplete ? Color.teal : Color.gray.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

struct BattleshipsFleetView: View {
    let fleet: [FleetItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fleet")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(fleet) { item in
                    ForEach(0..<item.count, id: \.self) { index in
                        HStack(spacing: 0) {
                            ForEach(Array(fleetShapes(size: item.size).enumerated()), id: \.offset) { _, shape in
                                ShipPartView(shape: shape)
                                    .frame(width: 16, height: 16)
                            }
                        }
                        .frame(height: 22)
                        .padding(.horizontal, 6)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .id("\(item.size)-\(index)")
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.25)))
    }
}

struct ShipPartView: View {
    let shape: ShipPartShape

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Color.primary)
    }

    private var radius: CGFloat {
        switch shape {
        case .single:
            return 999
        case .middle:
            return 4
        case .up, .right, .down, .left:
            return 10
        }
    }
}

struct FeedbackView: View {
    let result: GameResult?
    let hintText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let result {
                Text(result.message)
                    .fontWeight(.semibold)
                    .foregroundStyle(result.correct ? .green : .orange)
                Text("Score: \(result.score)")
                    .foregroundStyle(.secondary)
            }

            if !hintText.isEmpty {
                Text(hintText)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

enum ShipPartShape {
    case single
    case middle
    case up
    case right
    case down
    case left
}

extension CellMark {
    var shipPartShape: ShipPartShape {
        switch self {
        case .shipSingle:
            return .single
        case .shipMiddle:
            return .middle
        case .shipUp:
            return .up
        case .shipRight:
            return .right
        case .shipDown:
            return .down
        case .shipLeft:
            return .left
        case .water:
            return .single
        }
    }
}

func fleetShapes(size: Int) -> [ShipPartShape] {
    (0..<size).map { index in
        if size == 1 {
            return .single
        }

        if index == 0 {
            return .right
        }

        if index == size - 1 {
            return .left
        }

        return .middle
    }
}
