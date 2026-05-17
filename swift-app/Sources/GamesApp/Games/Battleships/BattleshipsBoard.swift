import Foundation

enum BattleshipsBoard {
    static func rowLabel(_ row: Int) -> String {
        String(UnicodeScalar(UInt8(ascii: "A") + UInt8(row)))
    }

    static func coordinateName(for cell: BoardCoordinate) -> String {
        "\(rowLabel(cell.row))\(cell.col + 1)"
    }

    static func coordinate(from name: String, boardSize: Int) throws -> BoardCoordinate {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let rowLetter = trimmed.first else {
            throw GameError.invalidAnswer
        }

        let rowValue = rowLetter.asciiValue.map { Int($0 - UInt8(ascii: "A")) } ?? -1
        let colText = String(trimmed.dropFirst())
        guard let visibleColumn = Int(colText) else {
            throw GameError.invalidAnswer
        }

        let cell = BoardCoordinate(row: rowValue, col: visibleColumn - 1)
        guard contains(cell, boardSize: boardSize) else {
            throw GameError.invalidAnswer
        }

        return cell
    }

    static func contains(_ cell: BoardCoordinate, boardSize: Int) -> Bool {
        cell.row >= 0 && cell.row < boardSize && cell.col >= 0 && cell.col < boardSize
    }

    static func cells(start: BoardCoordinate, size: Int, direction: ShipDirection) -> [BoardCoordinate] {
        (0..<size).map { offset in
            switch direction {
            case .horizontal:
                return BoardCoordinate(row: start.row, col: start.col + offset)
            case .vertical:
                return BoardCoordinate(row: start.row + offset, col: start.col)
            }
        }
    }

    static func orthogonalNeighbors(of cell: BoardCoordinate, boardSize: Int) -> [BoardCoordinate] {
        [
            BoardCoordinate(row: cell.row - 1, col: cell.col),
            BoardCoordinate(row: cell.row + 1, col: cell.col),
            BoardCoordinate(row: cell.row, col: cell.col - 1),
            BoardCoordinate(row: cell.row, col: cell.col + 1)
        ].filter { contains($0, boardSize: boardSize) }
    }

    static func surroundingCells(of cell: BoardCoordinate, boardSize: Int) -> [BoardCoordinate] {
        var cells: [BoardCoordinate] = []

        for rowOffset in -1...1 {
            for colOffset in -1...1 {
                if rowOffset == 0 && colOffset == 0 {
                    continue
                }

                let neighbor = BoardCoordinate(row: cell.row + rowOffset, col: cell.col + colOffset)
                if contains(neighbor, boardSize: boardSize) {
                    cells.append(neighbor)
                }
            }
        }

        return cells
    }

    static func shipMark(for cell: BoardCoordinate, occupied: Set<BoardCoordinate>, boardSize: Int) -> CellMark {
        let connected = orthogonalNeighbors(of: cell, boardSize: boardSize).filter { occupied.contains($0) }

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
