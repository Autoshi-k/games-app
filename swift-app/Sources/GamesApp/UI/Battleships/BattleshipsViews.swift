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

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 24) {
                    BattleshipsBoardView(board: board)
                    BattleshipsFleetView(fleet: puzzle.fleet)
                }
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
        Grid(horizontalSpacing: 3, verticalSpacing: 3) {
            GridRow {
                ForEach(0..<board.puzzle.boardSize, id: \.self) { col in
                    CountCell(
                        value: board.puzzle.columnCounts[col],
                        isComplete: board.countShipsInColumn(col) == board.puzzle.columnCounts[col]
                    )
                }
                Color.clear.frame(width: 30, height: 30)
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
                            onToggleLink: { board.toggleLinkedShip() }
                        )
                    }

                    CountCell(
                        value: board.puzzle.rowCounts[row],
                        isComplete: board.countShipsInRow(row) == board.puzzle.rowCounts[row]
                    )
                }
            }
        }
        #if os(macOS)
        .onHover { isHovering in
            if !isHovering {
                board.clearHoveredShip()
            }
        }
        #endif
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

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderColor, lineWidth: isHoveredComponent ? 2 : 1)
                )

            if mark == .water {
                Image(systemName: "drop.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(.blue)
            } else if let mark, mark.isShip {
                ShipPartView(shape: mark.shipPartShape)
                    .frame(width: 24, height: 24)
            }

            if showsLinkButton {
                Button(action: onToggleLink) {
                    Image(systemName: isLinked ? "link.badge.minus" : "link")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.primary))
                }
                .buttonStyle(.plain)
                .offset(x: 8, y: 8)
            }
        }
        .frame(width: 42, height: 42)
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

    var body: some View {
        Text("\(value)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(isComplete ? .white : .primary)
            .frame(width: 30, height: 30)
            .background(isComplete ? Color.teal : Color.gray.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

struct BattleshipsFleetView: View {
    let fleet: [FleetItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fleet")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            ForEach(fleet) { item in
                ForEach(0..<item.count, id: \.self) { index in
                    HStack(spacing: 0) {
                        ForEach(Array(fleetShapes(size: item.size).enumerated()), id: \.offset) { _, shape in
                            ShipPartView(shape: shape)
                                .frame(width: 28, height: 28)
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .id("\(item.size)-\(index)")
                }
            }
        }
        .padding(16)
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
