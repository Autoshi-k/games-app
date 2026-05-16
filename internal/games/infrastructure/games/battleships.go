package games

import (
	"context"
	cryptorand "crypto/rand"
	"encoding/hex"
	"fmt"
	mathrand "math/rand/v2"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/shanihzn/games-app/internal/games/domain"
)

const (
	battleshipsID        = "battleships"
	battleshipsBoardSize = 10
)

var battleshipsFleet = []int{4, 3, 3, 2, 2, 2, 1, 1, 1, 1}

type BattleshipsGame struct{}

type battleship struct {
	ID    string
	Size  int
	Cells []coordinate
}

type coordinate struct {
	Row int
	Col int
}

type fleetInventoryItem struct {
	Size  int `json:"size"`
	Count int `json:"count"`
}

type fixedBlock struct {
	Coordinate string `json:"coordinate"`
	Mark       string `json:"mark"`
}

func NewBattleshipsGame() *BattleshipsGame {
	return &BattleshipsGame{}
}

func (g *BattleshipsGame) Metadata() domain.GameMetadata {
	return domain.GameMetadata{
		ID:          battleshipsID,
		Name:        "Battleships",
		Description: "Solve a 10x10 fleet puzzle from row and column ship-piece counts.",
		Tags:        []string{"strategy", "grid", "logic"},
		Difficulty:  "Medium / Hard",
		ViewKind:    "battleships",
		InputSchema: []domain.InputField{
			{Name: "difficulty", Label: "Difficulty", Type: "select", Required: true, Options: []string{"medium", "hard"}},
		},
		Defaults: domain.CreateConfig{
			"difficulty": "medium",
		},
	}
}

func (g *BattleshipsGame) CreateGame(_ context.Context, input domain.CreateGameInput) (*domain.GameSession, error) {
	difficulty := stringFromConfig(input.Config, "difficulty", "medium")
	if difficulty != "hard" {
		difficulty = "medium"
	}

	ships := placeBattleshipsFleet()
	occupied := occupiedCells(ships)
	fixedBlocks := chooseFixedBlocks(occupied, fixedBlockCount(difficulty))

	return &domain.GameSession{
		ID:        newGameID("session"),
		GameID:    battleshipsID,
		Title:     fmt.Sprintf("10x10 fleet puzzle - %s", difficulty),
		Prompt:    "Mark every ship part using the row and column counts, then submit the completed fleet.",
		CreatedAt: time.Now(),
		State: map[string]any{
			"difficulty":     difficulty,
			"boardSize":      battleshipsBoardSize,
			"rowCounts":      rowCounts(occupied),
			"columnCounts":   columnCounts(occupied),
			"fleet":          fleetInventory(),
			"fixedBlocks":    fixedBlocks,
			"shipRule":       "Ships are straight lines and cannot touch each other, including diagonally.",
			"totalShipCells": len(occupied),
		},
		PrivateState: map[string]any{
			"occupied": occupied,
			"ships":    ships,
		},
	}, nil
}

func (g *BattleshipsGame) ValidateGame(_ context.Context, session *domain.GameSession) error {
	if session == nil || session.GameID != battleshipsID || session.PrivateState["occupied"] == nil {
		return domain.ErrInvalidSession
	}
	return nil
}

func (g *BattleshipsGame) CheckResult(_ context.Context, session *domain.GameSession, input domain.CheckResultInput) (*domain.GameResult, error) {
	expected, ok := session.PrivateState["occupied"].(map[coordinate]bool)
	if !ok {
		return nil, domain.ErrInvalidSession
	}

	submitted, err := submittedShipCells(input.Answer)
	if err != nil {
		return nil, err
	}

	if len(submitted) != len(expected) {
		return &domain.GameResult{
			Correct: false,
			Message: fmt.Sprintf("The fleet needs exactly %d ship parts.", len(expected)),
			Score:   solutionScore(submitted, expected),
		}, nil
	}

	if err := validateSubmittedFleet(submitted); err != nil {
		return &domain.GameResult{
			Correct: false,
			Message: err.Error(),
			Score:   solutionScore(submitted, expected),
		}, nil
	}

	correct := sameCells(submitted, expected)
	if !correct {
		return &domain.GameResult{
			Correct: false,
			Message: "Not quite. Some ship parts are in the wrong cells.",
			Score:   solutionScore(submitted, expected),
		}, nil
	}

	return &domain.GameResult{
		Correct: true,
		Message: "Correct. The whole fleet is found.",
		Score:   100,
	}, nil
}

func (g *BattleshipsGame) Hint(_ context.Context, session *domain.GameSession, input domain.HintInput) (*domain.HintResult, error) {
	rowValues, rowOK := intSliceFromState(session.State["rowCounts"])
	columnValues, columnOK := intSliceFromState(session.State["columnCounts"])
	if !rowOK || !columnOK {
		return nil, domain.ErrInvalidSession
	}

	if input.Level > 1 {
		rowIndex, rowCount := maxCountIndex(rowValues)
		return &domain.HintResult{
			Message: fmt.Sprintf("Row %s contains the most ship parts: %d.", rowLabel(rowIndex), rowCount),
			Cost:    20,
		}, nil
	}

	columnIndex, columnCount := maxCountIndex(columnValues)
	return &domain.HintResult{
		Message: fmt.Sprintf("Column %d contains %d ship parts.", columnIndex+1, columnCount),
		Cost:    10,
	}, nil
}

func placeBattleshipsFleet() []battleship {
	for {
		ships, ok := tryPlaceBattleshipsFleet()
		if ok {
			return ships
		}
	}
}

func tryPlaceBattleshipsFleet() ([]battleship, bool) {
	ships := make([]battleship, 0, len(battleshipsFleet))
	occupied := make(map[coordinate]bool)

	for index, size := range battleshipsFleet {
		placed := false
		for attempt := 0; attempt < 500; attempt++ {
			horizontal := mathrand.IntN(2) == 0
			maxRow := battleshipsBoardSize
			maxCol := battleshipsBoardSize
			if horizontal {
				maxCol = battleshipsBoardSize - size + 1
			} else {
				maxRow = battleshipsBoardSize - size + 1
			}

			start := coordinate{Row: mathrand.IntN(maxRow), Col: mathrand.IntN(maxCol)}
			cells := shipCells(start, size, horizontal)
			if !canPlaceShip(cells, occupied) {
				continue
			}

			for _, cell := range cells {
				occupied[cell] = true
			}
			ships = append(ships, battleship{ID: fmt.Sprintf("ship-%d", index+1), Size: size, Cells: cells})
			placed = true
			break
		}

		if !placed {
			return nil, false
		}
	}

	return ships, true
}

func shipCells(start coordinate, size int, horizontal bool) []coordinate {
	cells := make([]coordinate, 0, size)
	for offset := 0; offset < size; offset++ {
		cell := start
		if horizontal {
			cell.Col += offset
		} else {
			cell.Row += offset
		}
		cells = append(cells, cell)
	}
	return cells
}

func canPlaceShip(cells []coordinate, occupied map[coordinate]bool) bool {
	for _, cell := range cells {
		if occupied[cell] {
			return false
		}
		for _, neighbor := range neighborsIncludingDiagonal(cell) {
			if occupied[neighbor] {
				return false
			}
		}
	}
	return true
}

func occupiedCells(ships []battleship) map[coordinate]bool {
	occupied := make(map[coordinate]bool)
	for _, ship := range ships {
		for _, cell := range ship.Cells {
			occupied[cell] = true
		}
	}
	return occupied
}

func rowCounts(occupied map[coordinate]bool) []int {
	counts := make([]int, battleshipsBoardSize)
	for cell := range occupied {
		counts[cell.Row]++
	}
	return counts
}

func columnCounts(occupied map[coordinate]bool) []int {
	counts := make([]int, battleshipsBoardSize)
	for cell := range occupied {
		counts[cell.Col]++
	}
	return counts
}

func fleetInventory() []fleetInventoryItem {
	counts := make(map[int]int)
	for _, size := range battleshipsFleet {
		counts[size]++
	}

	sizes := make([]int, 0, len(counts))
	for size := range counts {
		sizes = append(sizes, size)
	}
	sort.Sort(sort.Reverse(sort.IntSlice(sizes)))

	items := make([]fleetInventoryItem, 0, len(sizes))
	for _, size := range sizes {
		items = append(items, fleetInventoryItem{Size: size, Count: counts[size]})
	}
	return items
}

func fixedBlockCount(difficulty string) int {
	if difficulty == "hard" {
		return 1
	}
	return mathrand.IntN(5) + 1
}

func chooseFixedBlocks(occupied map[coordinate]bool, count int) []fixedBlock {
	used := make(map[coordinate]bool, count)
	blocks := make([]fixedBlock, 0, count)

	for len(blocks) < count {
		cell := coordinate{Row: mathrand.IntN(battleshipsBoardSize), Col: mathrand.IntN(battleshipsBoardSize)}
		if used[cell] {
			continue
		}
		used[cell] = true

		mark := "water"
		if occupied[cell] {
			surroundings := cell.getSurroundings()
			connections := make([]coordinate, 0)
			for _, c := range surroundings {
				if occupied[c] {
					connections = append(connections, c)
				}
			}

			if len(connections) == 1 {
				mark = "ship_" + cell.direction(connections[0])
			} else if len(connections) == 0 {
				mark = "ship_single"
			} else {
				mark = "ship_middle"
			}
		}
		blocks = append(blocks, fixedBlock{Coordinate: formatCoordinate(cell), Mark: mark})
	}

	return blocks
}

func submittedShipCells(answer map[string]any) (map[coordinate]bool, error) {
	rawCells, ok := answer["ships"]
	if !ok {
		rawCells = answer["value"]
	}

	items, ok := rawCells.([]any)
	if !ok {
		return nil, domain.ErrInvalidAnswer
	}

	cells := make(map[coordinate]bool, len(items))
	for _, item := range items {
		label, ok := item.(string)
		if !ok {
			return nil, domain.ErrInvalidAnswer
		}
		cell, err := parseCoordinate(label)
		if err != nil {
			return nil, err
		}
		cells[cell] = true
	}

	return cells, nil
}

func parseCoordinate(raw string) (coordinate, error) {
	raw = strings.ToUpper(strings.TrimSpace(raw))
	if len(raw) < 2 {
		return coordinate{}, domain.ErrInvalidAnswer
	}

	row := int(raw[0] - 'A')
	col, err := strconv.Atoi(raw[1:])
	if err != nil {
		return coordinate{}, domain.ErrInvalidAnswer
	}
	col--

	if row < 0 || row >= battleshipsBoardSize || col < 0 || col >= battleshipsBoardSize {
		return coordinate{}, domain.ErrInvalidAnswer
	}

	return coordinate{Row: row, Col: col}, nil
}

func formatCoordinate(cell coordinate) string {
	return rowLabel(cell.Row) + strconv.Itoa(cell.Col+1)
}

func validateSubmittedFleet(cells map[coordinate]bool) error {
	components := shipComponents(cells)
	sizes := make([]int, 0, len(components))
	for _, component := range components {
		if !isStraightShip(component) {
			return fmt.Errorf("Ships must be straight horizontal or vertical lines.")
		}
		if touchesAnotherShip(component, cells) {
			return fmt.Errorf("Ships must be surrounded by water and cannot touch each other, including diagonally.")
		}
		sizes = append(sizes, len(component))
	}

	sort.Sort(sort.Reverse(sort.IntSlice(sizes)))
	expected := append([]int(nil), battleshipsFleet...)
	sort.Sort(sort.Reverse(sort.IntSlice(expected)))
	if len(sizes) != len(expected) {
		return fmt.Errorf("The fleet shape does not match the required ships.")
	}
	for index := range expected {
		if sizes[index] != expected[index] {
			return fmt.Errorf("The fleet shape does not match the required ships.")
		}
	}

	return nil
}

func shipComponents(cells map[coordinate]bool) [][]coordinate {
	visited := make(map[coordinate]bool)
	components := [][]coordinate{}

	for cell := range cells {
		if visited[cell] {
			continue
		}

		queue := []coordinate{cell}
		visited[cell] = true
		component := []coordinate{}

		for len(queue) > 0 {
			current := queue[0]
			queue = queue[1:]
			component = append(component, current)

			for _, neighbor := range orthogonalNeighbors(current) {
				if cells[neighbor] && !visited[neighbor] {
					visited[neighbor] = true
					queue = append(queue, neighbor)
				}
			}
		}

		components = append(components, component)
	}

	return components
}

func isStraightShip(cells []coordinate) bool {
	if len(cells) == 1 {
		return true
	}

	sameRow := true
	sameCol := true
	row := cells[0].Row
	col := cells[0].Col
	for _, cell := range cells {
		sameRow = sameRow && cell.Row == row
		sameCol = sameCol && cell.Col == col
	}
	if !sameRow && !sameCol {
		return false
	}

	positions := make([]int, 0, len(cells))
	for _, cell := range cells {
		if sameRow {
			positions = append(positions, cell.Col)
		} else {
			positions = append(positions, cell.Row)
		}
	}
	sort.Ints(positions)
	for index := 1; index < len(positions); index++ {
		if positions[index] != positions[index-1]+1 {
			return false
		}
	}

	return true
}

func touchesAnotherShip(component []coordinate, allCells map[coordinate]bool) bool {
	componentCells := make(map[coordinate]bool, len(component))
	for _, cell := range component {
		componentCells[cell] = true
	}

	for _, cell := range component {
		for _, neighbor := range neighborsIncludingDiagonal(cell) {
			if allCells[neighbor] && !componentCells[neighbor] {
				return true
			}
		}
	}

	return false
}

func orthogonalNeighbors(cell coordinate) []coordinate {
	return []coordinate{
		{Row: cell.Row - 1, Col: cell.Col},
		{Row: cell.Row + 1, Col: cell.Col},
		{Row: cell.Row, Col: cell.Col - 1},
		{Row: cell.Row, Col: cell.Col + 1},
	}
}

func neighborsIncludingDiagonal(cell coordinate) []coordinate {
	neighbors := make([]coordinate, 0, 8)
	for rowOffset := -1; rowOffset <= 1; rowOffset++ {
		for colOffset := -1; colOffset <= 1; colOffset++ {
			if rowOffset == 0 && colOffset == 0 {
				continue
			}
			neighbor := coordinate{Row: cell.Row + rowOffset, Col: cell.Col + colOffset}
			if neighbor.Row >= 0 && neighbor.Row < battleshipsBoardSize && neighbor.Col >= 0 && neighbor.Col < battleshipsBoardSize {
				neighbors = append(neighbors, neighbor)
			}
		}
	}
	return neighbors
}

func sameCells(submitted map[coordinate]bool, expected map[coordinate]bool) bool {
	if len(submitted) != len(expected) {
		return false
	}
	for cell := range expected {
		if !submitted[cell] {
			return false
		}
	}
	return true
}

func solutionScore(submitted map[coordinate]bool, expected map[coordinate]bool) int {
	if len(expected) == 0 {
		return 0
	}

	correct := 0
	for cell := range submitted {
		if expected[cell] {
			correct++
		}
	}
	return int(float64(correct) / float64(len(expected)) * 100)
}

func intSliceFromState(value any) ([]int, bool) {
	switch typed := value.(type) {
	case []int:
		return typed, true
	case []any:
		values := make([]int, 0, len(typed))
		for _, item := range typed {
			switch number := item.(type) {
			case int:
				values = append(values, number)
			case float64:
				values = append(values, int(number))
			default:
				return nil, false
			}
		}
		return values, true
	default:
		return nil, false
	}
}

func maxCountIndex(values []int) (int, int) {
	bestIndex := 0
	bestValue := 0
	for index, value := range values {
		if value > bestValue {
			bestIndex = index
			bestValue = value
		}
	}
	return bestIndex, bestValue
}

func stringFromConfig(config domain.CreateConfig, key string, fallback string) string {
	value, ok := config[key].(string)
	if !ok || value == "" {
		return fallback
	}
	return value
}

func rowLabel(row int) string {
	return string(rune('A' + row))
}

func newGameID(prefix string) string {
	var bytes [8]byte
	if _, err := cryptorand.Read(bytes[:]); err != nil {
		return prefix + "-game"
	}
	return prefix + "-" + hex.EncodeToString(bytes[:])
}

func (c coordinate) getSurroundings() (surroundings []coordinate) {
	if c.Col != 0 {
		surroundings = append(surroundings, coordinate{Col: c.Col - 1, Row: c.Row})
	}

	if c.Row != 0 {
		surroundings = append(surroundings, coordinate{Col: c.Col, Row: c.Row - 1})
	}

	if c.Col != battleshipsBoardSize-1 {
		surroundings = append(surroundings, coordinate{Col: c.Col + 1, Row: c.Row})
	}

	if c.Row != battleshipsBoardSize-1 {
		surroundings = append(surroundings, coordinate{Col: c.Col, Row: c.Row + 1})
	}

	return
}

func (c coordinate) direction(t coordinate) string {
	if c.Row > t.Row {
		return "up"
	} else if c.Row < t.Row {
		return "down"
	}

	if c.Col > t.Col {
		return "left"
	} else if c.Col < t.Col {
		return "right"
	}

	return ""
}
