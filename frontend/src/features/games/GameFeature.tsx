import { ArithmeticGame } from "./arithmetic/ArithmeticGame";
import { BattleshipsGame } from "./battleships/BattleshipsGame";
import { TriviaGame } from "./trivia/TriviaGame";
import type { GameComponentProps } from "./types";

export function GameFeature(props: GameComponentProps) {
  if (props.game.viewKind === "battleships") {
    return <BattleshipsGame {...props} />;
  }

  if (props.game.viewKind === "multiple-choice") {
    return <TriviaGame {...props} />;
  }

  return <ArithmeticGame {...props} />;
}
