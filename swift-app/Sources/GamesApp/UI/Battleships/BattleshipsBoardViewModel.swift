import Foundation
import Combine

final class BattleshipsBoardViewModel: ObservableObject {
    let puzzle: BattleshipsPuzzle

    @Published var marks: [String: CellMark]
    @Published var hoveredShip: String?

    private let fixedMarks: [String: CellMark]

    init(puzzle: BattleshipsPuzzle) {
        self.puzzle = puzzle
        self.fixedMarks = Dictionary(uniqueKeysWithValues: puzzle.fixedBlocks.map { ($0.coordinate, $0.mark) })
        self.marks = fixedMarks
    }

    var markedShipCoordinates: [String] {
        marks.keys.filter { marks[$0]?.isShip == true }
    }

    var canSubmit: Bool {
        markedShipCoordinates.count == puzzle.totalShipCells
    }

    var hoveredComponent: [String] {
        guard let hoveredShip, marks[hoveredShip]?.isShip == true else {
            return []
        }

        return connectedShipCoordinates(start: hoveredShip)
    }

    var hoveredCoordinates: Set<String> {
        Set(hoveredComponent)
    }

    var editableHoveredComponent: [String] {
        hoveredComponent.filter { fixedMarks[$0] == nil }
    }

    var linkButtonCoordinate: String? {
        hoveredComponent.max { left, right in
            let leftPosition = position(for: left)
            let rightPosition = position(for: right)

            if leftPosition.row != rightPosition.row {
                return leftPosition.row < rightPosition.row
            }

            return leftPosition.col < rightPosition.col
        }
    }

    var hoveredComponentIsLinked: Bool {
        !editableHoveredComponent.isEmpty && editableHoveredComponent.allSatisfy { marks[$0] != .shipSingle }
    }

    func coordinate(row: Int, col: Int) -> String {
        BattleshipsBoard.coordinateName(for: BoardCoordinate(row: row, col: col))
    }

    func mark(at coordinate: String) -> CellMark? {
        marks[coordinate]
    }

    func isFixed(_ coordinate: String) -> Bool {
        fixedMarks[coordinate] != nil
    }

    func cycleCell(_ coordinate: String) {
        guard fixedMarks[coordinate] == nil else {
            return
        }

        switch marks[coordinate] {
        case nil:
            marks[coordinate] = .water
        case .water:
            marks[coordinate] = .shipSingle
            hoveredShip = coordinate
        default:
            marks.removeValue(forKey: coordinate)
            if hoveredShip == coordinate {
                hoveredShip = nil
            }
        }
    }

    func countShipsInRow(_ row: Int) -> Int {
        (0..<puzzle.boardSize).filter { col in
            mark(at: coordinate(row: row, col: col))?.isShip == true
        }.count
    }

    func countShipsInColumn(_ col: Int) -> Int {
        (0..<puzzle.boardSize).filter { row in
            mark(at: coordinate(row: row, col: col))?.isShip == true
        }.count
    }

    func setHoveredShipIfNeeded(_ coordinate: String) {
        if marks[coordinate]?.isShip == true {
            hoveredShip = coordinate
        }
    }

    func clearHoveredShip() {
        hoveredShip = nil
    }

    func toggleLinkedShip() {
        guard !hoveredComponent.isEmpty else {
            return
        }

        let component = Set(hoveredComponent)

        for coordinate in hoveredComponent {
            if let fixedMark = fixedMarks[coordinate] {
                marks[coordinate] = fixedMark
                continue
            }

            if hoveredComponentIsLinked {
                marks[coordinate] = .shipSingle
                continue
            }

            marks[coordinate] = shipMark(for: position(for: coordinate), in: component)
        }
    }

    private func connectedShipCoordinates(start: String) -> [String] {
        var queue = [start]
        var visited = Set([start])

        while !queue.isEmpty {
            let current = queue.removeFirst()

            for neighbor in neighbors(of: position(for: current)) {
                guard !visited.contains(neighbor), marks[neighbor]?.isShip == true else {
                    continue
                }

                visited.insert(neighbor)
                queue.append(neighbor)
            }
        }

        return Array(visited)
    }

    private func neighbors(of position: BoardCoordinate) -> [String] {
        BattleshipsBoard.orthogonalNeighbors(of: position, boardSize: puzzle.boardSize).map {
            BattleshipsBoard.coordinateName(for: $0)
        }
    }

    private func position(for coordinate: String) -> BoardCoordinate {
        (try? BattleshipsBoard.coordinate(from: coordinate, boardSize: puzzle.boardSize)) ?? BoardCoordinate(row: 0, col: 0)
    }

    private func shipMark(for cell: BoardCoordinate, in component: Set<String>) -> CellMark {
        let connected = BattleshipsBoard.orthogonalNeighbors(of: cell, boardSize: puzzle.boardSize)
            .filter { component.contains(BattleshipsBoard.coordinateName(for: $0)) }

        if connected.isEmpty {
            return .shipSingle
        }

        if connected.count > 1 {
            return .shipMiddle
        }

        let neighbor = connected[0]
        if cell.row > neighbor.row { return .shipUp }
        if cell.row < neighbor.row { return .shipDown }
        if cell.col > neighbor.col { return .shipLeft }
        return .shipRight
    }
}
