import type {
  GameMetadata,
  GameResult,
  GameSession,
} from "../../../bindings/github.com/shanihzn/games-app/internal/games/domain/models";

export type AnswerPayload = Record<string, string | number | boolean>;

export type GameComponentProps = {
  game: GameMetadata;
  hint: string;
  onCheck: (answer: AnswerPayload) => void;
  onHint: () => void;
  result: GameResult | null;
  session: GameSession;
};

export const stateValue = <T,>(session: GameSession, key: string, fallback: T): T => {
  return (session.state?.[key] as T | undefined) ?? fallback;
};
