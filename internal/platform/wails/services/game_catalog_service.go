package services

import (
	"context"

	gamesapp "github.com/shanihzn/games-app/internal/games/application"
	"github.com/shanihzn/games-app/internal/games/domain"
)

type GameCatalogService struct {
	games *gamesapp.GameApplicationService
}

func NewGameCatalogService(games *gamesapp.GameApplicationService) *GameCatalogService {
	return &GameCatalogService{games: games}
}

func (s *GameCatalogService) ListGames() ([]domain.GameMetadata, error) {
	return s.games.ListGames(context.Background())
}

func (s *GameCatalogService) CreateGame(input domain.CreateGameInput) (*domain.GameSession, error) {
	return s.games.CreateGame(context.Background(), input)
}

func (s *GameCatalogService) CheckResult(input domain.CheckResultInput) (*domain.GameResult, error) {
	return s.games.CheckResult(context.Background(), input)
}

func (s *GameCatalogService) Hint(sessionID string, input domain.HintInput) (*domain.HintResult, error) {
	return s.games.Hint(context.Background(), sessionID, input)
}
