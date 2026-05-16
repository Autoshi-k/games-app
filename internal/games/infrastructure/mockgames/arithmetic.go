package mockgames

import (
	"context"
	"fmt"
	"math"
	"strconv"
	"time"

	"github.com/shanihzn/games-app/internal/games/domain"
)

type ArithmeticGame struct{}

func NewArithmeticGame() *ArithmeticGame {
	return &ArithmeticGame{}
}

func (g *ArithmeticGame) Metadata() domain.GameMetadata {
	return domain.GameMetadata{
		ID:          "arithmetic-sprint",
		Name:        "Arithmetic Sprint",
		Description: "Solve a short generated arithmetic challenge.",
		Tags:        []string{"numbers", "logic", "mock"},
		Difficulty:  "Easy",
		ViewKind:    "number-answer",
		InputSchema: []domain.InputField{
			{Name: "rounds", Label: "Rounds", Type: "number", Required: true, Placeholder: "3"},
			{Name: "operation", Label: "Operation", Type: "select", Required: true, Options: []string{"addition", "subtraction"}},
		},
		Defaults: domain.CreateConfig{
			"rounds":    3,
			"operation": "addition",
		},
	}
}

func (g *ArithmeticGame) CreateGame(_ context.Context, input domain.CreateGameInput) (*domain.GameSession, error) {
	rounds := intFromConfig(input.Config, "rounds", 3)
	operation := stringFromConfig(input.Config, "operation", "addition")

	left := rounds * 4
	right := rounds + 7
	answer := left + right
	symbol := "+"
	if operation == "subtraction" {
		left = rounds * 6
		right = rounds + 3
		answer = left - right
		symbol = "-"
	}

	return &domain.GameSession{
		ID:        newID("session"),
		GameID:    g.Metadata().ID,
		Title:     "Quick calculation",
		Prompt:    fmt.Sprintf("What is %d %s %d?", left, symbol, right),
		CreatedAt: time.Now(),
		State: map[string]any{
			"left":      left,
			"right":     right,
			"operation": operation,
		},
		PrivateState: map[string]any{
			"answer": answer,
		},
	}, nil
}

func (g *ArithmeticGame) ValidateGame(_ context.Context, session *domain.GameSession) error {
	if session == nil || session.GameID != g.Metadata().ID || session.PrivateState["answer"] == nil {
		return domain.ErrInvalidSession
	}
	return nil
}

func (g *ArithmeticGame) CheckResult(_ context.Context, session *domain.GameSession, input domain.CheckResultInput) (*domain.GameResult, error) {
	answer, ok := numberFromMap(input.Answer, "value")
	if !ok {
		return nil, domain.ErrInvalidAnswer
	}

	expected, ok := numberFromMap(session.PrivateState, "answer")
	if !ok {
		return &domain.GameResult{
			Correct: false,
			Message: "Mock answer payload is missing the expected answer.",
			Score:   0,
		}, nil
	}

	correct := math.Abs(answer-expected) < 0.0001
	message := "Close, but not quite."
	score := 0
	if correct {
		message = "Correct."
		score = 100
	}

	return &domain.GameResult{
		Correct: correct,
		Message: message,
		Score:   score,
		Expected: map[string]any{
			"value": expected,
		},
	}, nil
}

func (g *ArithmeticGame) Hint(_ context.Context, session *domain.GameSession, input domain.HintInput) (*domain.HintResult, error) {
	operation, _ := session.State["operation"].(string)
	if input.Level > 1 {
		return &domain.HintResult{Message: "Use the operation shown in the prompt, then submit only the final number.", Cost: 20}, nil
	}
	return &domain.HintResult{Message: fmt.Sprintf("This mock challenge uses %s.", operation), Cost: 10}, nil
}

func intFromConfig(config domain.CreateConfig, key string, fallback int) int {
	value, ok := config[key]
	if !ok {
		return fallback
	}

	switch typed := value.(type) {
	case int:
		return typed
	case int32:
		return int(typed)
	case int64:
		return int(typed)
	case float64:
		return int(typed)
	case string:
		parsed, err := strconv.Atoi(typed)
		if err == nil {
			return parsed
		}
	}

	return fallback
}

func stringFromConfig(config domain.CreateConfig, key string, fallback string) string {
	value, ok := config[key].(string)
	if !ok || value == "" {
		return fallback
	}
	return value
}

func numberFromMap(values map[string]any, key string) (float64, bool) {
	value, ok := values[key]
	if !ok {
		return 0, false
	}

	switch typed := value.(type) {
	case int:
		return float64(typed), true
	case int32:
		return float64(typed), true
	case int64:
		return float64(typed), true
	case float64:
		return typed, true
	case string:
		parsed, err := strconv.ParseFloat(typed, 64)
		return parsed, err == nil
	default:
		return 0, false
	}
}
