import { Fragment, useEffect, useMemo, useState, type CSSProperties } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faLink, faLinkSlash, faWater } from "@fortawesome/free-solid-svg-icons";
import { GameFeedback } from "../components/GameFeedback";
import { stateValue, type AnswerPayload, type GameComponentProps } from "../types";
import {
  connectedShipCoordinates,
  coordinateFor,
  countShipsInColumn,
  countShipsInRow,
  fixedMarksFromBlocks,
  fleetShapes,
  isShipMark,
  lastCoordinateByReadingOrder,
  nextCellMark,
  positionFor,
  shipCoordinates,
  shipMarkForPosition,
  shipPartShape,
  type BoardMarks,
  type FixedBlock,
  type FleetItem,
} from "./battleshipsModel";
import "./battleships.css";

function ShipPart({ shape }: { shape: string }) {
  return <span aria-hidden="true" className={`battle-ship-icon ${shape}`} />;
}

export function BattleshipsGame({ hint, onCheck, onHint, result, session }: GameComponentProps) {
  const boardSize = stateValue<number>(session, "boardSize", 10);
  const rowCounts = stateValue<number[]>(session, "rowCounts", []);
  const columnCounts = stateValue<number[]>(session, "columnCounts", []);
  const fleet = stateValue<FleetItem[]>(session, "fleet", []);
  const fixedBlocks = stateValue<FixedBlock[]>(session, "fixedBlocks", []);
  const totalShipCells = stateValue<number>(session, "totalShipCells", 20);
  const fixedMarks = useMemo(() => fixedMarksFromBlocks(fixedBlocks), [fixedBlocks]);
  const [marks, setMarks] = useState<BoardMarks>(fixedMarks);
  const [hoveredShip, setHoveredShip] = useState<string | null>(null);

  useEffect(() => {
    setMarks(fixedMarks);
    setHoveredShip(null);
  }, [fixedMarks, session.id]);

  const markedShips = useMemo(() => shipCoordinates(marks), [marks]);

  const hoveredComponent = useMemo(() => {
    if (!hoveredShip || !isShipMark(marks[hoveredShip])) return [];
    return connectedShipCoordinates(hoveredShip, marks, boardSize);
  }, [boardSize, hoveredShip, marks]);
  const hoveredCoordinates = useMemo(() => new Set(hoveredComponent), [hoveredComponent]);
  const editableHoveredComponent = hoveredComponent.filter((coordinate) => !fixedMarks[coordinate]);
  const linkButtonCoordinate = lastCoordinateByReadingOrder(hoveredComponent);
  const hoveredComponentLinked =
    editableHoveredComponent.length > 0 &&
    editableHoveredComponent.every((coordinate) => marks[coordinate] !== "ship_single");

  const canSubmit = markedShips.length === totalShipCells;

  const cycleCell = (coordinate: string) => {
    if (fixedMarks[coordinate]) return;

    setMarks((current) => {
      const updated = { ...current };
      const mark = nextCellMark(current[coordinate]);
      if (!mark) {
        delete updated[coordinate];
      } else {
        updated[coordinate] = mark;
      }
      return updated;
    });
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

        updated[coordinate] = shipMarkForPosition(positionFor(coordinate), component, boardSize);
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
          {Array.from({ length: boardSize }, (_, col) => {
            const marked = countShipsInColumn(col, boardSize, marks);
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
              {Array.from({ length: boardSize }, (_, col) => {
                const coordinate = coordinateFor(row, col);
                const mark = marks[coordinate];
                const fixed = Boolean(fixedMarks[coordinate]);

                return (
                  <div
                    aria-label={`${coordinate} ${mark ?? "empty"}`}
                    className={`battle-puzzle-cell ${mark ?? ""} ${fixed ? "fixed" : ""} ${
                      hoveredCoordinates.has(coordinate) ? "linked-hover" : ""
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
                    {isShipMark(mark) && <ShipPart shape={shipPartShape(mark)} />}
                    {linkButtonCoordinate === coordinate && editableHoveredComponent.length > 0 && (
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
                  countShipsInRow(row, boardSize, marks) === (rowCounts[row] ?? 0)
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
            {fleet.map((item, fleetIndex) =>
              Array.from({ length: item.count }, (_, shipIndex) => (
                <div className="battle-fleet-ship" key={`${fleetIndex}-${item.size}-${shipIndex}`}>
                  {fleetShapes(item.size).map((shape, partIndex) => (
                    <span className="battle-fleet-part" key={`${shape}-${partIndex}`}>
                      <ShipPart shape={shape} />
                    </span>
                  ))}
                </div>
              )),
            )}
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
