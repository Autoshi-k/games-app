package application

import (
	"context"

	"github.com/shanihzn/games-app/internal/games/domain"
)

type SessionRepository interface {
	Save(ctx context.Context, session *domain.GameSession) error
	Find(ctx context.Context, sessionID string) (*domain.GameSession, error)
}
