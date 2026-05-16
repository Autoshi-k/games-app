package mockgames

import (
	"context"
	"time"

	"github.com/shanihzn/games-app/internal/games/domain"
)

type TriviaGame struct{}

func NewTriviaGame() *TriviaGame {
	return &TriviaGame{}
}

func (g *TriviaGame) Metadata() domain.GameMetadata {
	return domain.GameMetadata{
		ID:          "trivia-choice",
		Name:        "Trivia Choice",
		Description: "Pick one answer from a generated multiple-choice question.",
		Tags:        []string{"knowledge", "choice", "mock"},
		Difficulty:  "Easy",
		ViewKind:    "multiple-choice",
		InputSchema: []domain.InputField{
			{Name: "category", Label: "Category", Type: "select", Required: true, Options: []string{"games", "science"}},
		},
		Defaults: domain.CreateConfig{
			"category": "games",
		},
	}
}

func (g *TriviaGame) CreateGame(_ context.Context, input domain.CreateGameInput) (*domain.GameSession, error) {
	category := stringFromConfig(input.Config, "category", "games")
	prompt := "Which classic board game uses rooks and bishops?"
	options := []string{"Chess", "Go", "Backgammon", "Checkers"}
	answer := "Chess"
	if category == "science" {
		prompt = "What is the chemical symbol for water?"
		options = []string{"H2O", "CO2", "NaCl", "O2"}
		answer = "H2O"
	}

	return &domain.GameSession{
		ID:        newID("session"),
		GameID:    g.Metadata().ID,
		Title:     "Single question",
		Prompt:    prompt,
		CreatedAt: time.Now(),
		State: map[string]any{
			"category": category,
			"options":  options,
		},
		PrivateState: map[string]any{
			"answer": answer,
		},
	}, nil
}

func (g *TriviaGame) ValidateGame(_ context.Context, session *domain.GameSession) error {
	if session == nil || session.GameID != g.Metadata().ID || session.PrivateState["answer"] == nil {
		return domain.ErrInvalidSession
	}
	return nil
}

func (g *TriviaGame) CheckResult(_ context.Context, session *domain.GameSession, input domain.CheckResultInput) (*domain.GameResult, error) {
	selected, ok := input.Answer["value"].(string)
	if !ok || selected == "" {
		return nil, domain.ErrInvalidAnswer
	}

	expected, _ := session.PrivateState["answer"].(string)
	correct := selected == expected
	message := "That answer is not the mock solution."
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

func (g *TriviaGame) Hint(_ context.Context, session *domain.GameSession, input domain.HintInput) (*domain.HintResult, error) {
	answer, _ := session.PrivateState["answer"].(string)
	if input.Level > 1 && answer != "" {
		return &domain.HintResult{Message: "The mock answer starts with " + answer[:1] + ".", Cost: 20}, nil
	}
	return &domain.HintResult{Message: "Only one option matches every clue in the prompt.", Cost: 10}, nil
}
