import { useState } from "react";
import { GameFeedback } from "../components/GameFeedback";
import { stateValue, type GameComponentProps } from "../types";

export function TriviaGame({ hint, onCheck, onHint, result, session }: GameComponentProps) {
  const [answer, setAnswer] = useState("");
  const options = stateValue<string[]>(session, "options", []);

  return (
    <div className="play-surface">
      <div>
        <p className="eyebrow">{session.title}</p>
        <h3>{session.prompt}</h3>
      </div>

      <div className="choice-grid">
        {options.map((option) => (
          <button
            className={answer === option ? "choice selected" : "choice"}
            key={option}
            onClick={() => setAnswer(option)}
            type="button"
          >
            {option}
          </button>
        ))}
      </div>

      <div className="action-row">
        <button className="primary-action" onClick={() => onCheck({ value: answer })} type="button">
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
