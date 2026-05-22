# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Scope

**Only work within `swift-app/`.** Everything else in the repo (Go backend, React frontend, Wails config, Taskfile, `internal/`, `frontend/`) is experimental scratch code and should be ignored unless explicitly told otherwise.

## What This Is

A native iOS games app (iPhone/iPad, iOS 16+) built with SwiftUI. The code lives entirely in `swift-app/`, opened in Xcode via `swift-app/SwiftGamesApp.xcodeproj`. Swift version is 6.0 with strict concurrency enabled.

## Adding Files — Critical

The Xcode project uses **explicit file references**. Every new `.swift` file or resource must be registered in `SwiftGamesApp.xcodeproj/project.pbxproj` with:
1. A `PBXFileReference` entry (with the relative path from the project root)
2. A `PBXBuildFile` entry referencing it
3. The file added to the `PBXGroup` children list (Sources group)
4. Swift files added to `PBXSourcesBuildPhase`; resource files added to `PBXResourcesBuildPhase`

IDs follow the sequential hex pattern already in the file (`020000000000000000000001`, etc.).

## Architecture (`swift-app/`)

The Swift app uses a domain-driven design with Domain and Application layers:

- **`Sources/GamesApp/Domain/`** — Protocols and types defining the game contract.
- **`Sources/GamesApp/Application/`** — Game catalog and orchestration (session management, result checking).
- **`Sources/GamesApp/Games/<Name>/`** — Game logic implementing the `Game` protocol.
- **`Sources/GamesApp/UI/<Name>/`** — SwiftUI views per game; shared shell in `UI/Shell/`.
- **`Sources/GamesApp/Resources/`** — Bundled assets (word lists, etc.). Accessed via `Bundle.main` at runtime.

## Offline-first constraint

No network calls. All game assets must be bundled files in `Sources/GamesApp/Resources/` and added to the Xcode project's Resources build phase. Access them at runtime via `Bundle.main.url(forResource:withExtension:)`.

## Adding a New Game

1. Create types and `Game` conformance in `Sources/GamesApp/Games/<Name>/`.
2. Add cases to `GameState`, `PrivateGameState`, and `GameAnswer` in `Domain/Game.swift`.
3. Register the game in `SwiftGamesApp.swift`.
4. Add SwiftUI views in `Sources/GamesApp/UI/<Name>/`.
5. Add the `.wordle(puzzle)` case to `GameSessionView` in `ContentView.swift`.
6. Register every new file in `project.pbxproj` (see "Adding Files" above).
