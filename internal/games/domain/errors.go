package domain

import "errors"

var (
	ErrGameNotFound    = errors.New("game not found")
	ErrSessionNotFound = errors.New("game session not found")
	ErrInvalidSession  = errors.New("invalid game session")
	ErrInvalidAnswer   = errors.New("invalid answer")
)
