import type { GameResult } from "../../../../bindings/github.com/shanihzn/games-app/internal/games/domain/models";

type GameFeedbackProps = {
  hint: string;
  result: GameResult | null;
};

export function GameFeedback({ hint, result }: GameFeedbackProps) {
  return (
    <>
      {hint && <p className="hint">{hint}</p>}
      {result && (
        <p className={result.correct ? "result correct" : "result incorrect"}>
          {result.message} Score: {result.score}
        </p>
      )}
    </>
  );
}
