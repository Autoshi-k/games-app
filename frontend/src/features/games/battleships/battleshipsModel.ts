export const shipMarks = [
  "ship_left",
  "ship_right",
  "ship_up",
  "ship_down",
  "ship_single",
  "ship_middle",
] as const;

export type ShipMark = (typeof shipMarks)[number];
export type CellMark = "water" | ShipMark;
export type Direction = "up" | "right" | "down" | "left";

export type BoardPosition = {
  row: number;
  col: number;
};

export type FleetItem = {
  size: number;
  count: number;
};

export type FixedBlock = {
  coordinate: string;
  mark: CellMark;
};

export type BoardMarks = Record<string, CellMark>;

export const firstRowCode = "A".charCodeAt(0);

export function rowLabel(row: number) {
  return String.fromCharCode(firstRowCode + row);
}

export function coordinateFor(row: number, col: number) {
  return `${rowLabel(row)}${col + 1}`;
}

export function positionFor(coordinate: string): BoardPosition {
  return {
    row: coordinate.charCodeAt(0) - firstRowCode,
    col: Number(coordinate.slice(1)) - 1,
  };
}

export function isShipMark(mark?: CellMark): mark is ShipMark {
  return Boolean(mark && shipMarks.includes(mark as ShipMark));
}

export function nextCellMark(current?: CellMark): CellMark | undefined {
  if (!current) return "water";
  if (current === "water") return "ship_single";
  return undefined;
}

export function fixedMarksFromBlocks(fixedBlocks: FixedBlock[]): BoardMarks {
  const fixedMarks: BoardMarks = {};

  for (const block of fixedBlocks) {
    fixedMarks[block.coordinate] = block.mark;
  }

  return fixedMarks;
}

export function shipCoordinates(marks: BoardMarks) {
  return Object.keys(marks).filter((coordinate) => isShipMark(marks[coordinate]));
}

export function countShipsInRow(row: number, boardSize: number, marks: BoardMarks) {
  let count = 0;

  for (let col = 0; col < boardSize; col += 1) {
    if (isShipMark(marks[coordinateFor(row, col)])) {
      count += 1;
    }
  }

  return count;
}

export function countShipsInColumn(col: number, boardSize: number, marks: BoardMarks) {
  let count = 0;

  for (let row = 0; row < boardSize; row += 1) {
    if (isShipMark(marks[coordinateFor(row, col)])) {
      count += 1;
    }
  }

  return count;
}

export function neighborCoordinates(position: BoardPosition, boardSize: number) {
  const { row, col } = position;
  const neighbors: string[] = [];

  if (row > 0) neighbors.push(coordinateFor(row - 1, col));
  if (col < boardSize - 1) neighbors.push(coordinateFor(row, col + 1));
  if (row < boardSize - 1) neighbors.push(coordinateFor(row + 1, col));
  if (col > 0) neighbors.push(coordinateFor(row, col - 1));

  return neighbors;
}

export function connectedShipCoordinates(start: string, marks: BoardMarks, boardSize: number) {
  const queue = [start];
  const visited = new Set<string>([start]);

  while (queue.length > 0) {
    const current = queue.shift();
    if (!current) continue;

    for (const neighbor of neighborCoordinates(positionFor(current), boardSize)) {
      if (visited.has(neighbor) || !isShipMark(marks[neighbor])) continue;

      visited.add(neighbor);
      queue.push(neighbor);
    }
  }

  return Array.from(visited);
}

export function lastCoordinateByReadingOrder(coordinates: string[]) {
  let last = coordinates[0] ?? "";

  for (const coordinate of coordinates) {
    const currentPosition = positionFor(coordinate);
    const lastPosition = positionFor(last);
    const isLowerRow = currentPosition.row > lastPosition.row;
    const isFurtherRight = currentPosition.row === lastPosition.row && currentPosition.col > lastPosition.col;

    if (isLowerRow || isFurtherRight) {
      last = coordinate;
    }
  }

  return last;
}

export function shipMarkForPosition(position: BoardPosition, component: Set<string>, boardSize: number): ShipMark {
  const { row, col } = position;
  const connectedDirections: Direction[] = [];

  if (row > 0 && component.has(coordinateFor(row - 1, col))) connectedDirections.push("up");
  if (col < boardSize - 1 && component.has(coordinateFor(row, col + 1))) connectedDirections.push("right");
  if (row < boardSize - 1 && component.has(coordinateFor(row + 1, col))) connectedDirections.push("down");
  if (col > 0 && component.has(coordinateFor(row, col - 1))) connectedDirections.push("left");

  if (connectedDirections.length === 0) return "ship_single";
  if (connectedDirections.length > 1) return "ship_middle";

  return `ship_${connectedDirections[0]}` as ShipMark;
}

export function shipPartShape(mark: ShipMark) {
  return mark.replace("ship_", "");
}

export function fleetShapes(size: number) {
  const shapes: Array<ReturnType<typeof shipPartShape>> = [];

  for (let index = 0; index < size; index += 1) {
    if (size === 1) {
      shapes.push("single");
    } else if (index === 0) {
      shapes.push("right");
    } else if (index === size - 1) {
      shapes.push("left");
    } else {
      shapes.push("middle");
    }
  }

  return shapes;
}
