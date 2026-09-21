# Repository Guidelines

## Project Facts

- Zig 0.16.0 2D platformer using raylib-zig (raylib 6.0.0). Working branch is `rewrite/zig` tracking `origin/rewrite/zig`.
- `src/main.zig`: window init + game loop, loads the sprite frames and owns raylib textures. `src/player.zig`: `Player` struct and `updatePlayer` (animation + draw + debug). `src/root.zig`: library module root for unit tests, currently empty. `src/debug.zig`: keyboard-driven debug overlay. `src/buildSettings.zig`: gameplay tuning constants (`speed`, `deltaMult`) and fork URLs.
- `src/utils.zig`: `errorLogFatal` (logs, emits a terminal notification, then `@panic`s) and `errorLogNonFatal` (logs only). Both reference `bugTrackerUrl` from `buildSettings.zig`; imported by `main.zig` (catches any uncaught error) and `player.zig`.
- Build config is `build.zig` / `build.zig.zon` (minimum Zig 0.16.0).

## Sprite Pipeline (Important)

- `player.aseprite` is the source of truth for player art. The build shells out to the `aseprite` CLI and exports frames 4x scaled to `assets/autogen/playerAnim/{frame}.png`. `assets/autogen/` is gitignored, so these are derived artifacts.
- **`zig build`, `zig build run`, and `zig build dist` fail if `aseprite` is not on PATH**, because the executable step depends on the sprite export. `zig build test` does not need Aseprite.
- At runtime `main.zig` walks `assets/autogen/playerAnim` and loads the numbered frames into an animation; the game cannot render the player without exported sprites.
- `player.png` at the repo root is a stale leftover from the old C version; current code never loads it.

## Build, Test, and Development Commands

- `zig build` — build `2d_platformer` (requires Aseprite).
- `zig build run` — build and launch the game locally.
- `zig build test` — run module (`src/root.zig`) and exe (`src/main.zig`) tests. Passes today; there are no `test` blocks in `src/` yet.
- `zig build sprites` — re-export sprites from `player.aseprite`.
- `zig build dist` — build a ReleaseSafe binary and package it with `assets/` into `dist/2d_platformer.zip`.
- `zig fmt build.zig build.zig.zon src/*.zig` — format Zig sources before committing.

## Testing Guidelines

- Add Zig `test "descriptive behavior" { ... }` blocks close to the code they cover, keeping unit tests window-free (no raylib init / texture loading).
- `src/player.zig` imports raylib, so its logic is only reachable through the exe test module (`src/main.zig`); keep purely-testable utilities out of raylib-importing files so they can live in the `src/root.zig` module tests.
- Run `zig build test` before submitting changes.

## Repository Quirks & Conventions

- Keep raylib calls in the game loop or the owning subsystem (textures loaded in `main.zig`, drawing in `player.zig`). Avoid unrelated refactors in gameplay changes.
- Ignore/generated paths — do not edit or commit: `zig-out/`, `zig-pkg/`, `.zig-cache/`, `dist/`, `local/`, `platformer.app`, and `assets/autogen/`.
- Debug controls (in `debug.zig`, invoked from `updatePlayer`, Debug builds only): F3 toggles the FPS overlay, Ctrl+1 shows the player position. Error triggers: Ctrl+Delete raises `ManuallyTriggeredException` (non-fatal, logged via `errorLogNonFatal`), Ctrl+F4 `ManuallyTriggeredCrash` and Ctrl+F6 `OutOfMemory` are fatal (`errorLogFatal`), Ctrl+F5 `ManualForceFallThroughError` is re-thrown to `main`. Error routing lives in `updatePlayer` (`player.zig`), not `debug.zig`.

## Agent Instructions

Before changing Zig code or build configuration, read the Zig 0.16 documentation for the APIs and language features involved. Also inspect the relevant Zig standard-library source files in the local Zig installation; use the implementation to resolve behavior, ownership, or API questions rather than guessing. State which documentation and source areas informed non-trivial changes.

## Commit & Pull Request Guidelines

- Match the repo's descriptive sentence-style commit subjects (e.g., "Initial Zig Rewrite Commit", "More specific behavior"). Keep each commit focused.
- Crash/error logs and the terminal notification reference `bugTrackerUrl` / `gameName` in `src/buildSettings.zig`; forks should update them and the assignee in `.github/ISSUE_TEMPLATE/unhandled-exception.md`.
- Pull requests should explain gameplay or build changes, list validation commands run, link relevant issues, and include a screenshot or short recording for visual changes.
- Do not rename the `platformer.app` `.gitignore` entry unless the change explicitly requires it.