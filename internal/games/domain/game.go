package domain

import (
	"context"
	"time"
)

type Game interface {
	Metadata() GameMetadata
	CreateGame(ctx context.Context, input CreateGameInput) (*GameSession, error)
	ValidateGame(ctx context.Context, session *GameSession) error
	CheckResult(ctx context.Context, session *GameSession, input CheckResultInput) (*GameResult, error)
	Hint(ctx context.Context, session *GameSession, input HintInput) (*HintResult, error)
}

type GameMetadata struct {
	ID          string       `json:"id"`
	Name        string       `json:"name"`
	Description string       `json:"description"`
	Tags        []string     `json:"tags"`
	Difficulty  string       `json:"difficulty"`
	ViewKind    string       `json:"viewKind"`
	InputSchema []InputField `json:"inputSchema"`
	Defaults    CreateConfig `json:"defaults"`
}

type InputField struct {
	Name        string   `json:"name"`
	Label       string   `json:"label"`
	Type        string   `json:"type"`
	Required    bool     `json:"required"`
	Options     []string `json:"options,omitempty"`
	Placeholder string   `json:"placeholder,omitempty"`
}

type CreateConfig map[string]any

type CreateGameInput struct {
	GameID string       `json:"gameId"`
	Config CreateConfig `json:"config,omitempty"`
}

type GameSession struct {
	ID           string         `json:"id"`
	GameID       string         `json:"gameId"`
	Title        string         `json:"title"`
	Prompt       string         `json:"prompt"`
	State        map[string]any `json:"state"`
	PrivateState map[string]any `json:"-"`
	CreatedAt    time.Time      `json:"createdAt"`
}

type CheckResultInput struct {
	GameID    string         `json:"gameId"`
	SessionID string         `json:"sessionId"`
	Answer    map[string]any `json:"answer"`
}

type GameResult struct {
	Correct  bool           `json:"correct"`
	Message  string         `json:"message"`
	Score    int            `json:"score"`
	Expected map[string]any `json:"expected,omitempty"`
	Session  *GameSession   `json:"session,omitempty"`
}

type HintInput struct {
	Level int `json:"level"`
}

type HintResult struct {
	Message string `json:"message"`
	Cost    int    `json:"cost"`
}
