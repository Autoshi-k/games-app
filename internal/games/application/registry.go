package application

import (
	"sort"

	"github.com/shanihzn/games-app/internal/games/domain"
)

type GameRegistry struct {
	games map[string]domain.Game
}

func NewGameRegistry(games ...domain.Game) *GameRegistry {
	registry := &GameRegistry{games: make(map[string]domain.Game, len(games))}
	for _, game := range games {
		metadata := game.Metadata()
		registry.games[metadata.ID] = game
	}
	return registry
}

func (r *GameRegistry) Get(gameID string) (domain.Game, bool) {
	game, ok := r.games[gameID]
	return game, ok
}

func (r *GameRegistry) Metadata() []domain.GameMetadata {
	items := make([]domain.GameMetadata, 0, len(r.games))
	for _, game := range r.games {
		items = append(items, game.Metadata())
	}

	sort.Slice(items, func(i, j int) bool {
		return items[i].Name < items[j].Name
	})

	return items
}
