# Games App

A Wails v3 desktop app scaffold for hosting multiple Go-powered game generators behind one React + TypeScript UI.

## Architecture

- `internal/games/domain`: game interface, metadata, sessions, results, and domain errors.
- `internal/games/application`: registry and use-case orchestration.
- `internal/games/infrastructure/games`: production game generators.
- `internal/games/infrastructure/mockgames`: mock Go game generators that implement `domain.Game`.
- `internal/games/infrastructure/memory`: in-memory session repository for the first vertical slice.
- `internal/platform/wails/services`: Wails-facing service boundary.
- `frontend/src/features/games`: per-game React components and routing.

## Current Games

- Battleships: grid-targeting fleet hunt.
- Arithmetic Sprint: numeric-answer mock game.
- Trivia Choice: multiple-choice mock game.

## Development

```bash
wails3 dev
```

If `wails3` is not on your shell path, add the Go bin directory first:

```bash
export PATH="$HOME/go/bin:$PATH"
```

Useful verification commands:

```bash
go test ./...
npm --prefix frontend run build
wails3 build
```

Regenerate frontend bindings after changing exported service methods or DTOs:

```bash
wails3 generate bindings -ts ./...
```
