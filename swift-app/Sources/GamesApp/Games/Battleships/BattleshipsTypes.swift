import Foundation

enum CellMark: String, Equatable {
    case water
    case shipLeft = "ship_left"
    case shipRight = "ship_right"
    case shipUp = "ship_up"
    case shipDown = "ship_down"
    case shipSingle = "ship_single"
    case shipMiddle = "ship_middle"

    var isShip: Bool {
        self != .water
    }
}

enum ShipDirection {
    case horizontal
    case vertical
}

struct BoardCoordinate: Hashable, Comparable {
    let row: Int
    let col: Int

    static func < (left: BoardCoordinate, right: BoardCoordinate) -> Bool {
        if left.row != right.row {
            return left.row < right.row
        }

        return left.col < right.col
    }
}

struct Battleship {
    let id: String
    let size: Int
    let cells: [BoardCoordinate]
}

struct FleetItem: Identifiable, Equatable {
    var id: Int { size }

    let size: Int
    let count: Int
}

struct FixedBlock: Identifiable, Equatable {
    var id: String { coordinate }

    let coordinate: String
    let mark: CellMark
}

struct BattleshipsPuzzle {
    let difficulty: String
    let boardSize: Int
    let rowCounts: [Int]
    let columnCounts: [Int]
    let fleet: [FleetItem]
    let fixedBlocks: [FixedBlock]
    let shipRule: String
    let totalShipCells: Int
}

struct BattleshipsSolution {
    let occupied: Set<BoardCoordinate>
    let ships: [Battleship]
}
