import { Fragment, useEffect, useMemo, useState, type CSSProperties } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faLink, faLinkSlash, faWater } from "@fortawesome/free-solid-svg-icons";
import { GameFeedback } from "../components/GameFeedback";
import { stateValue, type AnswerPayload, type GameComponentProps } from "../types";
import "./battleships.css";

const shipTypes = ["ship_left", "ship_right", "ship_up", "ship_down", "ship_single", "ship_middle"] as const;

type ShipMark = typeof shipTypes[number];
type CellMark = "water" | ShipMark;

type FleetItem = {
  size: number;
  count: number;
};

type FixedBlock = {
  coordinate: string;
  mark: CellMark;
};

type Direction = "up" | "right" | "down" | "left";
type Position = {
  row: number;
  col: number;
};

const rowLabel = (row: number) => String.fromCharCode("A".charCodeAt(0) + row);
const coordinateFor = (row: number, col: number) => `${rowLabel(row)}${col + 1}`;

const nextMark = (current?: CellMark): CellMark | undefined => {
  if (!current) return "water";
  if (current === "water") return "ship_single";
  return undefined;
};

function ShipPart({ shape }: { shape: string }) {
  return <span aria-hidden="true" className={`battle-ship-icon ${shape}`} />;
}

const isShipMark = (mark?: CellMark): mark is ShipMark => {
  return Boolean(mark && shipTypes.includes(mark as ShipMark));
};

const positionFor = (coordinate: string): Position => {
  return {
    row: coordinate.charCodeAt(0) - "A".charCodeAt(0),
    col: Number(coordinate.slice(1)) - 1,
  };
};

const connectedShipCoordinates = (
  start: string,
  marks: Record<string, CellMark>,
  boardSize: number,
) => {
  const queue = [start];
  const visited = new Set<string>([start]);

  while (queue.length > 0) {
    const current = queue.shift();
    if (!current) continue;

    const { row, col } = positionFor(current);
    const neighbors = [
      row > 0 ? coordinateFor(row - 1, col) : "",
      col < boardSize - 1 ? coordinateFor(row, col + 1) : "",
      row < boardSize - 1 ? coordinateFor(row + 1, col) : "",
      col > 0 ? coordinateFor(row, col - 1) : "",
    ].filter(Boolean);

    for (const neighbor of neighbors) {
      if (!visited.has(neighbor) && isShipMark(marks[neighbor])) {
        visited.add(neighbor);
        queue.push(neighbor);
      }
    }
  }

  return [...visited];
};

const componentActionCoordinate = (component: string[]) => {
  return component.reduce((best, coordinate) => {
    const currentPosition = positionFor(coordinate);
    const bestPosition = positionFor(best);
    if (currentPosition.row > bestPosition.row) return coordinate;
    if (currentPosition.row === bestPosition.row && currentPosition.col > bestPosition.col) return coordinate;
    return best;
  }, component[0]);
};

const shipMarkFor = (
  row: number,
  col: number,
  component: Set<string>,
  boardSize: number,
): ShipMark => {
  const connected: Direction[] = [];
  if (row > 0 && component.has(coordinateFor(row - 1, col))) connected.push("up");
  if (col < boardSize - 1 && component.has(coordinateFor(row, col + 1))) connected.push("right");
  if (row < boardSize - 1 && component.has(coordinateFor(row + 1, col))) connected.push("down");
  if (col > 0 && component.has(coordinateFor(row, col - 1))) connected.push("left");

  if (connected.length === 0) return "ship_single";
  if (connected.length > 1) return "ship_middle";
  return `ship_${connected[0]}` as ShipMark;
};

export function BattleshipsGame({ hint, onCheck, onHint, result, session }: GameComponentProps) {
  const boardSize = stateValue<number>(session, "boardSize", 10);
  const rowCounts = stateValue<number[]>(session, "rowCounts", []);
  const columnCounts = stateValue<number[]>(session, "columnCounts", []);
  const fleet = stateValue<FleetItem[]>(session, "fleet", []);
  const fixedBlocks = stateValue<FixedBlock[]>(session, "fixedBlocks", []);
  const totalShipCells = stateValue<number>(session, "totalShipCells", 20);
  const fixedMarks = useMemo(
    () => Object.fromEntries(fixedBlocks.map((block) => [block.coordinate, block.mark])) as Record<string, CellMark>,
    [fixedBlocks],
  );
  const [marks, setMarks] = useState<Record<string, CellMark>>(fixedMarks);
  const [hoveredShip, setHoveredShip] = useState<string | null>(null);

  useEffect(() => {
    setMarks(fixedMarks);
    setHoveredShip(null);
  }, [fixedMarks, session.id]);

  const markedShips = useMemo(
    () =>
      Object.entries(marks)
        .filter(([, mark]) => isShipMark(mark))
        .map(([coordinate]) => coordinate),
    [marks],
  );

  const hoveredComponent = useMemo(() => {
    if (!hoveredShip || !isShipMark(marks[hoveredShip])) return [];
    return connectedShipCoordinates(hoveredShip, marks, boardSize);
  }, [boardSize, hoveredShip, marks]);
  const hoveredComponentSet = useMemo(() => new Set(hoveredComponent), [hoveredComponent]);
  const hoveredMutableComponent = hoveredComponent.filter((coordinate) => !fixedMarks[coordinate]);
  const hoveredActionCoordinate = hoveredComponent.length > 0 ? componentActionCoordinate(hoveredComponent) : "";
  const hoveredComponentLinked =
    hoveredMutableComponent.length > 0 &&
    hoveredMutableComponent.every((coordinate) => marks[coordinate] !== "ship_single");

  const canSubmit = markedShips.length === totalShipCells;

  const cycleCell = (coordinate: string) => {
    if (fixedMarks[coordinate]) return;

    setMarks((current) => {
      const updated = { ...current };
      const mark = nextMark(current[coordinate]);
      if (!mark) {
        delete updated[coordinate];
      } else {
        updated[coordinate] = mark;
      }
      return updated;
    });
  };

  const countMarkedShipsInRow = (row: number) => {
    let count = 0;
    for (let col = 0; col < boardSize; col += 1) {
      if (isShipMark(marks[coordinateFor(row, col)])) count += 1;
    }
    return count;
  };

  const countMarkedShipsInColumn = (col: number) => {
    let count = 0;
    for (let row = 0; row < boardSize; row += 1) {
      if (isShipMark(marks[coordinateFor(row, col)])) count += 1;
    }
    return count;
  };

  const toggleLinkedShip = () => {
    if (hoveredComponent.length === 0) return;

    setMarks((current) => {
      const updated = { ...current };
      const component = new Set(hoveredComponent);

      for (const coordinate of hoveredComponent) {
        if (fixedMarks[coordinate]) {
          updated[coordinate] = fixedMarks[coordinate];
          continue;
        }

        if (hoveredComponentLinked) {
          updated[coordinate] = "ship_single";
          continue;
        }

        const { row, col } = positionFor(coordinate);
        updated[coordinate] = shipMarkFor(row, col, component, boardSize);
      }

      return updated;
    });
  };

  return (
    <div className="play-surface battleships-puzzle">
      <div>
        <p className="eyebrow">{session.title}</p>
        <h3>{session.prompt}</h3>
      </div>

      <div className="battleships-puzzle-layout">
        <div
          className="battleships-puzzle-board"
          onMouseLeave={() => setHoveredShip(null)}
          style={{ "--board-size": boardSize } as CSSProperties}
        >
          {/* <span className="battle-empty-corner" /> */}
          {Array.from({ length: boardSize }, (_, col) => {
            const marked = countMarkedShipsInColumn(col);
            const expected = columnCounts[col] ?? 0;
            return (
              <span className={marked === expected ? "battle-count complete" : "battle-count"} key={`col-${col}`}>
                {expected}
              </span>
            );
          })}
          <span className="battle-empty-corner" />

          {Array.from({ length: boardSize }, (_, row) => (
            <Fragment key={`row-${row}`}>
              {/* <span className="battle-axis">{rowLabel(row)} xx</span> */}
              {Array.from({ length: boardSize }, (_, col) => {
                const coordinate = coordinateFor(row, col);
                const mark = marks[coordinate];
                const fixed = Boolean(fixedMarks[coordinate]);

                return (
                  <div
                    aria-label={`${coordinate} ${mark ?? "empty"}`}
                    className={`battle-puzzle-cell ${mark ?? ""} ${fixed ? "fixed" : ""} ${
                      hoveredComponentSet.has(coordinate) ? "linked-hover" : ""
                    }`}
                    onClick={() => cycleCell(coordinate)}
                    onFocus={() => isShipMark(mark) && setHoveredShip(coordinate)}
                    onKeyDown={(event) => {
                      if (event.key === "Enter" || event.key === " ") {
                        event.preventDefault();
                        cycleCell(coordinate);
                      }
                    }}
                    onMouseEnter={() => isShipMark(mark) && setHoveredShip(coordinate)}
                    role="button"
                    tabIndex={0}
                  >
                    {mark === "water" && <FontAwesomeIcon className="battle-water-icon" icon={faWater} />}
                    {isShipMark(mark) && <ShipPart shape={mark.split('_')[1]} />}
                    {hoveredActionCoordinate === coordinate && hoveredMutableComponent.length > 0 && (
                      <button
                        aria-label={hoveredComponentLinked ? "Unlink ship parts" : "Link ship parts"}
                        className="ship-link-button"
                        onClick={(event) => {
                          event.stopPropagation();
                          toggleLinkedShip();
                        }}
                        title={hoveredComponentLinked ? "Unlink ship parts" : "Link ship parts"}
                        type="button"
                      >
                        <FontAwesomeIcon icon={hoveredComponentLinked ? faLinkSlash : faLink} />
                      </button>
                    )}
                  </div>
                );
              })}
              <span
                className={
                  countMarkedShipsInRow(row) === (rowCounts[row] ?? 0)
                    ? "battle-count complete"
                    : "battle-count"
                }
              >
                {rowCounts[row] ?? 0}
              </span>
            </Fragment>
          ))}
        </div>

        <aside className="battle-puzzle-panel">
          <p className="eyebrow">Fleet</p>
          <div className="battle-fleet-list">
            {fleet.map((item) => {
              return Array(item.count).fill(item.size).map((size, index) => {
                console.log("nani ", size, index)
                return <div key={size + 10 * index} style={{display: "flex"}}>{Array(size).fill(0).map((_, index) => {
                  console.log("herro?")
                  const shape = size === 1 ? "single" :
                    index === 0 ? "right" : index + 1 === size ? "left" : "middle";
                    console.log("this is the shape", shape, size, index)
                  return <div style={{width: "2rem", height: "2rem"}} key={index}><ShipPart shape={shape} /></div>
                })}</div>
              })
            })}
          </div>
        </aside>
      </div>

      <div className="action-row">
        <button
          className="primary-action"
          disabled={!canSubmit}
          onClick={() => onCheck({ ships: markedShips } as unknown as AnswerPayload)}
          type="button"
        >
          Check solution
        </button>
        <button className="secondary-action" onClick={onHint} type="button">
          Hint
        </button>
      </div>

      <GameFeedback hint={hint} result={result} />
    </div>
  );
}
