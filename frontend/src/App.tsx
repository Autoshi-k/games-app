import { useEffect, useMemo, useState } from "react";
import { GameCatalogService } from "../bindings/github.com/shanihzn/games-app/internal/platform/wails/services";
import type {
  CheckResultInput,
  GameMetadata,
  GameResult,
  GameSession,
} from "../bindings/github.com/shanihzn/games-app/internal/games/domain/models";
import { GameFeature } from "./features/games/GameFeature";

type GameConfig = Record<string, string | number>;
type AnswerPayload = Record<string, string | number | boolean>;

function App() {
  const [games, setGames] = useState<GameMetadata[]>([]);
  const [selectedGameId, setSelectedGameId] = useState<string>("");
  const [config, setConfig] = useState<GameConfig>({});
  const [session, setSession] = useState<GameSession | null>(null);
  const [result, setResult] = useState<GameResult | null>(null);
  const [hint, setHint] = useState("");
  const [error, setError] = useState("");

  const selectedGame = useMemo(
    () => games.find((game) => game.id === selectedGameId) ?? null,
    [games, selectedGameId],
  );

  useEffect(() => {
    GameCatalogService.ListGames()
      .then((items) => {
        setGames(items);
        if (items.length > 0) {
          setSelectedGameId(items[0].id);
          setConfig(items[0].defaults ?? {});
        }
      })
      .catch((err) => setError(String(err)));
  }, []);

  const chooseGame = (game: GameMetadata) => {
    setSelectedGameId(game.id);
    setConfig(game.defaults ?? {});
    setSession(null);
    setResult(null);
    setHint("");
    setError("");
  };

  const createGame = async () => {
    if (!selectedGame) return;
    setError("");
    setResult(null);
    setHint("");

    try {
      const created = await GameCatalogService.CreateGame({
        gameId: selectedGame.id,
        config,
      });
      setSession(created);
    } catch (err) {
      setError(String(err));
    }
  };

  const checkResult = async (answer: AnswerPayload) => {
    if (!session) return;
    setError("");

    const payload: CheckResultInput = {
      gameId: session.gameId,
      sessionId: session.id,
      answer,
    };

    try {
      const checked = await GameCatalogService.CheckResult(payload);
      setResult(checked);
      if (checked?.session) {
        setSession(checked.session);
      }
    } catch (err) {
      setError(String(err));
    }
  };

  const requestHint = async () => {
    if (!session) return;
    setError("");

    try {
      const nextHint = await GameCatalogService.Hint(session.id, { level: hint ? 2 : 1 });
      if (!nextHint) {
        setError("No hint was returned.");
        return;
      }
      setHint(`${nextHint.message} (${nextHint.cost} points)`);
    } catch (err) {
      setError(String(err));
    }
  };

  return (
    <main className="app-shell">
      <section className="catalog-panel" aria-label="Available games">
        <div className="panel-heading">
          <p className="eyebrow">Games App</p>
          <h1>Generated games</h1>
        </div>

        <div className="game-list">
          {games.map((game) => (
            <button
              className={`game-card ${game.id === selectedGameId ? "selected" : ""}`}
              key={game.id}
              onClick={() => chooseGame(game)}
              type="button"
            >
              <span>{game.name}</span>
              <small>{game.description}</small>
              <strong>{game.difficulty}</strong>
            </button>
          ))}
        </div>
      </section>

      <section className="workspace-panel" aria-label="Game workspace">
        {selectedGame && (
          <>
            <div className="workspace-header">
              <div>
                <p className="eyebrow">{selectedGame.viewKind}</p>
                <h2>{selectedGame.name}</h2>
              </div>
              <div className="tag-row">
                {selectedGame.tags?.map((tag) => <span key={tag}>{tag}</span>)}
              </div>
            </div>

            <div className="config-grid">
              {selectedGame.inputSchema?.map((field) => (
                <label key={field.name}>
                  <span>{field.label}</span>
                  {field.type === "select" ? (
                    <select
                      value={String(config[field.name] ?? "")}
                      onChange={(event) =>
                        setConfig((current) => ({ ...current, [field.name]: event.target.value }))
                      }
                    >
                      {field.options?.map((option) => (
                        <option key={option} value={option}>
                          {option}
                        </option>
                      ))}
                    </select>
                  ) : (
                    <input
                      min="1"
                      placeholder={field.placeholder}
                      type={field.type}
                      value={String(config[field.name] ?? "")}
                      onChange={(event) =>
                        setConfig((current) => ({
                          ...current,
                          [field.name]:
                            field.type === "number" ? Number(event.target.value) : event.target.value,
                        }))
                      }
                    />
                  )}
                </label>
              ))}
              <button className="primary-action" onClick={createGame} type="button">
                Create game
              </button>
            </div>

            {session && (
              <GameFeature
                game={selectedGame}
                hint={hint}
                onCheck={checkResult}
                onHint={requestHint}
                result={result}
                session={session}
              />
            )}

            {error && <p className="error">{error}</p>}
          </>
        )}
      </section>
    </main>
  );
}

export default App;
