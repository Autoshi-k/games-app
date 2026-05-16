package main

import (
	"embed"
	_ "embed"
	"log"

	gamesapp "github.com/shanihzn/games-app/internal/games/application"
	realgames "github.com/shanihzn/games-app/internal/games/infrastructure/games"
	"github.com/shanihzn/games-app/internal/games/infrastructure/memory"
	"github.com/shanihzn/games-app/internal/games/infrastructure/mockgames"
	wailsservices "github.com/shanihzn/games-app/internal/platform/wails/services"
	"github.com/wailsapp/wails/v3/pkg/application"
)

//go:embed all:frontend/dist
var assets embed.FS

func main() {
	gameService := gamesapp.NewGameApplicationService(
		gamesapp.NewGameRegistry(
			realgames.NewBattleshipsGame(),
			mockgames.NewArithmeticGame(),
			mockgames.NewTriviaGame(),
		),
		memory.NewSessionRepository(),
	)

	app := application.New(application.Options{
		Name:        "games-app",
		Description: "A desktop playground for multiple generated games",
		Services: []application.Service{
			application.NewService(wailsservices.NewGameCatalogService(gameService)),
		},
		Assets: application.AssetOptions{
			Handler: application.AssetFileServerFS(assets),
		},
		Mac: application.MacOptions{
			ApplicationShouldTerminateAfterLastWindowClosed: true,
		},
	})

	app.Window.NewWithOptions(application.WebviewWindowOptions{
		Title: "Games App",
		Mac: application.MacWindow{
			InvisibleTitleBarHeight: 50,
			Backdrop:                application.MacBackdropTranslucent,
			TitleBar:                application.MacTitleBarHiddenInset,
		},
		BackgroundColour: application.NewRGB(246, 247, 250),
		URL:              "/",
	})

	if err := app.Run(); err != nil {
		log.Fatal(err)
	}
}
