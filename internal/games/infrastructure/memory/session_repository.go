package memory

import (
	"context"
	"sync"

	"github.com/shanihzn/games-app/internal/games/domain"
)

type SessionRepository struct {
	mu       sync.RWMutex
	sessions map[string]*domain.GameSession
}

func NewSessionRepository() *SessionRepository {
	return &SessionRepository{
		sessions: make(map[string]*domain.GameSession),
	}
}

func (r *SessionRepository) Save(_ context.Context, session *domain.GameSession) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.sessions[session.ID] = session
	return nil
}

func (r *SessionRepository) Find(_ context.Context, sessionID string) (*domain.GameSession, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	session, ok := r.sessions[sessionID]
	if !ok {
		return nil, domain.ErrSessionNotFound
	}

	return session, nil
}
