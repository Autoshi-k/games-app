import { useState } from "react";
import { GameFeedback } from "../components/GameFeedback";
import type { GameComponentProps } from "../types";

export function ArithmeticGame({ hint, onCheck, onHint, result, session }: GameComponentProps) {
  const [answer, setAnswer] = useState("");

  return (
    <div className="play-surface">
      <div>
        <p className="eyebrow">{session.title}</p>
        <h3>{session.prompt}</h3>
      </div>

      <input
        className="answer-input"
        onChange={(event) => setAnswer(event.target.value)}
        placeholder="Answer"
        type="number"
        value={answer}
      />

      <div className="action-row">
        <button className="primary-action" onClick={() => onCheck({ value: Number(answer) })} type="button">
          Check
        </button>
        <button className="secondary-action" onClick={onHint} type="button">
          Hint
        </button>
      </div>

      <GameFeedback hint={hint} result={result} />
    </div>
  );
}
