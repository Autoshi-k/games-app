package application

import (
	"context"

	"github.com/shanihzn/games-app/internal/games/domain"
)

type GameApplicationService struct {
	registry *GameRegistry
	sessions SessionRepository
}

func NewGameApplicationService(registry *GameRegistry, sessions SessionRepository) *GameApplicationService {
	return &GameApplicationService{
		registry: registry,
		sessions: sessions,
	}
}

func (s *GameApplicationService) ListGames(ctx context.Context) ([]domain.GameMetadata, error) {
	return s.registry.Metadata(), nil
}

func (s *GameApplicationService) CreateGame(ctx context.Context, input domain.CreateGameInput) (*domain.GameSession, error) {
	game, ok := s.registry.Get(input.GameID)
	if !ok {
		return nil, domain.ErrGameNotFound
	}

	session, err := game.CreateGame(ctx, input)
	if err != nil {
		return nil, err
	}
	if err := game.ValidateGame(ctx, session); err != nil {
		return nil, err
	}
	if err := s.sessions.Save(ctx, session); err != nil {
		return nil, err
	}

	return session, nil
}

func (s *GameApplicationService) CheckResult(ctx context.Context, input domain.CheckResultInput) (*domain.GameResult, error) {
	session, err := s.sessions.Find(ctx, input.SessionID)
	if err != nil {
		return nil, err
	}

	game, ok := s.registry.Get(session.GameID)
	if !ok {
		return nil, domain.ErrGameNotFound
	}

	input.GameID = session.GameID
	result, err := game.CheckResult(ctx, session, input)
	if err != nil {
		return nil, err
	}
	if err := s.sessions.Save(ctx, session); err != nil {
		return nil, err
	}
	result.Session = session
	return result, nil
}

func (s *GameApplicationService) Hint(ctx context.Context, sessionID string, input domain.HintInput) (*domain.HintResult, error) {
	session, err := s.sessions.Find(ctx, sessionID)
	if err != nil {
		return nil, err
	}

	game, ok := s.registry.Get(session.GameID)
	if !ok {
		return nil, domain.ErrGameNotFound
	}

	return game.Hint(ctx, session, input)
}
