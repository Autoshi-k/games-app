import Foundation

struct BattleshipsGame: Game {
    private let boardSize = 10
    private let fleetSizes = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1]

    var metadata: GameMetadata {
        GameMetadata(
            id: "battleships",
            name: "Battleships",
            description: "Solve a 10x10 fleet puzzle from row and column ship-piece counts.",
            tags: ["strategy", "grid", "logic"],
            difficulty: "Medium / Hard",
            viewKind: "battleships",
            inputSchema: [
                InputField(
                    id: "difficulty",
                    label: "Difficulty",
                    type: .select,
                    required: true,
                    options: ["medium", "hard"],
                    placeholder: ""
                )
            ],
            defaults: ["difficulty": "medium"]
        )
    }

    func createGame(config: [String: String]) throws -> GameSession {
        let difficulty = config["difficulty"] == "hard" ? "hard" : "medium"
        let ships = placeFleet()
        let occupied = Set(ships.flatMap(\.cells))
        let fixedBlocks = chooseFixedBlocks(from: occupied, count: fixedBlockCount(for: difficulty))

        let puzzle = BattleshipsPuzzle(
            difficulty: difficulty,
            boardSize: boardSize,
            rowCounts: countsByRow(occupied),
            columnCounts: countsByColumn(occupied),
            fleet: fleetInventory(),
            fixedBlocks: fixedBlocks,
            shipRule: "Ships are straight lines and cannot touch each other, including diagonally.",
            totalShipCells: occupied.count
        )

        return GameSession(
            id: "session-\(UUID().uuidString)",
            gameID: metadata.id,
            title: "10x10 fleet puzzle - \(difficulty)",
            prompt: "Mark every ship part using the row and column counts, then submit the completed fleet.",
            state: .battleships(puzzle),
            privateState: .battleships(BattleshipsSolution(occupied: occupied, ships: ships)),
            createdAt: Date()
        )
    }

    func validate(session: GameSession) throws {
        guard session.gameID == metadata.id else {
            throw GameError.invalidSession
        }

        guard case .battleships = session.privateState else {
            throw GameError.invalidSession
        }
    }

    func checkResult(session: GameSession, answer: GameAnswer) throws -> GameResult {
        guard case let .battleships(solution) = session.privateState else {
            throw GameError.invalidSession
        }

        guard case let .battleships(shipCoordinates) = answer else {
            throw GameError.invalidAnswer
        }

        let submitted = try Set(shipCoordinates.map { try BattleshipsBoard.coordinate(from: $0, boardSize: boardSize) })
        if submitted.count != solution.occupied.count {
            return GameResult(
                correct: false,
                message: "The fleet needs exactly \(solution.occupied.count) ship parts.",
                score: solutionScore(submitted: submitted, expected: solution.occupied),
                expected: nil
            )
        }

        if let validationMessage = validateFleet(submitted) {
            return GameResult(
                correct: false,
                message: validationMessage,
                score: solutionScore(submitted: submitted, expected: solution.occupied),
                expected: nil
            )
        }

        let correct = submitted == solution.occupied
        return GameResult(
            correct: correct,
            message: correct ? "Correct. The whole fleet is found." : "Not quite. Some ship parts are in the wrong cells.",
            score: correct ? 100 : solutionScore(submitted: submitted, expected: solution.occupied),
            expected: nil
        )
    }

    func hint(session: GameSession, level: Int) throws -> HintResult {
        guard case let .battleships(puzzle) = session.state else {
            throw GameError.invalidSession
        }

        if level > 1 {
            let row = maxCountIndex(puzzle.rowCounts)
            return HintResult(
                message: "Row \(BattleshipsBoard.rowLabel(row.index)) contains the most ship parts: \(row.value).",
                cost: 20
            )
        }

        let column = maxCountIndex(puzzle.columnCounts)
        return HintResult(message: "Column \(column.index + 1) contains \(column.value) ship parts.", cost: 10)
    }

    private func placeFleet() -> [Battleship] {
        while true {
            if let ships = tryPlaceFleet() {
                return ships
            }
        }
    }

    private func tryPlaceFleet() -> [Battleship]? {
        var ships: [Battleship] = []
        var occupied = Set<BoardCoordinate>()

        for (index, size) in fleetSizes.enumerated() {
            var placedShip: Battleship?

            for _ in 0..<500 {
                let direction: ShipDirection = Bool.random() ? .horizontal : .vertical
                let maxRow = direction == .horizontal ? boardSize : boardSize - size + 1
                let maxCol = direction == .horizontal ? boardSize - size + 1 : boardSize
                let start = BoardCoordinate(row: Int.random(in: 0..<maxRow), col: Int.random(in: 0..<maxCol))
                let cells = BattleshipsBoard.cells(start: start, size: size, direction: direction)

                if canPlaceShip(cells, occupied: occupied) {
                    occupied.formUnion(cells)
                    placedShip = Battleship(id: "ship-\(index + 1)", size: size, cells: cells)
                    break
                }
            }

            guard let placedShip else {
                return nil
            }

            ships.append(placedShip)
        }

        return ships
    }

    private func canPlaceShip(_ cells: [BoardCoordinate], occupied: Set<BoardCoordinate>) -> Bool {
        for cell in cells {
            if occupied.contains(cell) {
                return false
            }

            if BattleshipsBoard.surroundingCells(of: cell, boardSize: boardSize).contains(where: occupied.contains) {
                return false
            }
        }

        return true
    }

    private func countsByRow(_ occupied: Set<BoardCoordinate>) -> [Int] {
        var counts = Array(repeating: 0, count: boardSize)
        for cell in occupied {
            counts[cell.row] += 1
        }

        return counts
    }

    private func countsByColumn(_ occupied: Set<BoardCoordinate>) -> [Int] {
        var counts = Array(repeating: 0, count: boardSize)
        for cell in occupied {
            counts[cell.col] += 1
        }

        return counts
    }

    private func fleetInventory() -> [FleetItem] {
        let counts = Dictionary(grouping: fleetSizes, by: { $0 }).mapValues(\.count)
        return counts.keys.sorted(by: >).map { size in
            FleetItem(size: size, count: counts[size] ?? 0)
        }
    }

    private func fixedBlockCount(for difficulty: String) -> Int {
        difficulty == "hard" ? 1 : Int.random(in: 1...5)
    }

    private func chooseFixedBlocks(from occupied: Set<BoardCoordinate>, count: Int) -> [FixedBlock] {
        var used = Set<BoardCoordinate>()
        var blocks: [FixedBlock] = []

        while blocks.count < count {
            let cell = BoardCoordinate(row: Int.random(in: 0..<boardSize), col: Int.random(in: 0..<boardSize))
            guard !used.contains(cell) else {
                continue
            }

            used.insert(cell)
            let mark = occupied.contains(cell)
                ? BattleshipsBoard.shipMark(for: cell, occupied: occupied, boardSize: boardSize)
                : CellMark.water
            blocks.append(FixedBlock(coordinate: BattleshipsBoard.coordinateName(for: cell), mark: mark))
        }

        return blocks
    }

    private func validateFleet(_ cells: Set<BoardCoordinate>) -> String? {
        let components = shipComponents(cells)
        var sizes: [Int] = []

        for component in components {
            if !isStraightShip(component) {
                return "Ships must be straight horizontal or vertical lines."
            }

            if touchesAnotherShip(component, allCells: cells) {
                return "Ships must be surrounded by water and cannot touch each other, including diagonally."
            }

            sizes.append(component.count)
        }

        if sizes.sorted(by: >) != fleetSizes.sorted(by: >) {
            return "The fleet shape does not match the required ships."
        }

        return nil
    }

    private func shipComponents(_ cells: Set<BoardCoordinate>) -> [[BoardCoordinate]] {
        var visited = Set<BoardCoordinate>()
        var components: [[BoardCoordinate]] = []

        for cell in cells {
            guard !visited.contains(cell) else {
                continue
            }

            var queue = [cell]
            var component: [BoardCoordinate] = []
            visited.insert(cell)

            while !queue.isEmpty {
                let current = queue.removeFirst()
                component.append(current)

                for neighbor in BattleshipsBoard.orthogonalNeighbors(of: current, boardSize: boardSize) {
                    if cells.contains(neighbor) && !visited.contains(neighbor) {
                        visited.insert(neighbor)
                        queue.append(neighbor)
                    }
                }
            }

            components.append(component)
        }

        return components
    }

    private func isStraightShip(_ cells: [BoardCoordinate]) -> Bool {
        if cells.count == 1 {
            return true
        }

        let rows = Set(cells.map(\.row))
        let cols = Set(cells.map(\.col))
        guard rows.count == 1 || cols.count == 1 else {
            return false
        }

        let positions = (rows.count == 1 ? cells.map(\.col) : cells.map(\.row)).sorted()
        for index in 1..<positions.count {
            if positions[index] != positions[index - 1] + 1 {
                return false
            }
        }

        return true
    }

    private func touchesAnotherShip(_ component: [BoardCoordinate], allCells: Set<BoardCoordinate>) -> Bool {
        let componentCells = Set(component)

        for cell in component {
            for neighbor in BattleshipsBoard.surroundingCells(of: cell, boardSize: boardSize) {
                if allCells.contains(neighbor) && !componentCells.contains(neighbor) {
                    return true
                }
            }
        }

        return false
    }

    private func solutionScore(submitted: Set<BoardCoordinate>, expected: Set<BoardCoordinate>) -> Int {
        guard !expected.isEmpty else {
            return 0
        }

        let correctCount = submitted.intersection(expected).count
        return Int(Double(correctCount) / Double(expected.count) * 100)
    }

    private func maxCountIndex(_ values: [Int]) -> (index: Int, value: Int) {
        values.enumerated().max { left, right in left.element < right.element }.map {
            (index: $0.offset, value: $0.element)
        } ?? (index: 0, value: 0)
    }
}
