# roblox-dev-pipeline

Code for our Roblox games. Studio is where the world gets built; the Luau lives here in git and [Rojo](https://rojo.space) syncs it into Studio while you work. The workflow from idea to live game is in [docs/process.md](docs/process.md).

## Layout

```
roblox-dev-pipeline/
├── rokit.toml              # pinned tool versions (Rojo, Wally, Selene, StyLua, Lune)
├── selene.toml, testez.yml # lint config
├── stylua.toml             # format config
├── docs/process.md         # the game pipeline
├── tools/run-specs.luau    # runs a game's specs outside Studio with Lune
├── shared/                 # libraries reused across games (empty for now)
└── games/
    └── countdown-crew/
        ├── default.project.json  # Rojo project for the game
        ├── test.project.json     # same tree plus TestEZ and tests/
        ├── wally.toml            # packages
        ├── src/server/   -> ServerScriptService.Server
        ├── src/client/   -> StarterPlayer.StarterPlayerScripts.Client
        ├── src/shared/   -> ReplicatedStorage.Shared
        ├── tests/        -> ServerScriptService.Tests (test build only)
        └── docs/         # game-specific docs, such as playtest scripts (not synced)
```

## Setup on Windows

You need [Roblox Studio](https://create.roblox.com), [Git for Windows](https://git-scm.com/download/win) and [VS Code](https://code.visualstudio.com). Run the commands below in PowerShell.

1. **Install Rokit**, the toolchain manager. Download `rokit-*-windows-x86_64.zip` from the [Rokit releases](https://github.com/rojo-rbx/rokit/releases), unzip it, and run `.\rokit.exe self-install`. Close and reopen PowerShell so `rokit` is on your PATH.
2. **Clone the repo and install the tools.** This reads `rokit.toml` and installs the exact versions of Rojo, Wally, Selene and StyLua. Say yes when Rokit asks to trust each tool.
   ```powershell
   git clone https://github.com/rubaismail/roblox-dev-pipeline.git
   cd roblox-dev-pipeline
   rokit install
   ```
3. **Install the Rojo plugin into Studio.** With Studio closed, run `rojo plugin install`. This installs the plugin that matches the pinned Rojo version.
4. **Install packages for a game.** Wally downloads TestEZ and any other packages into `Packages/` and `DevPackages/`, which are not committed.
   ```powershell
   cd games\countdown-crew
   wally install
   ```
5. **Open VS Code** in the repo and accept the recommended extensions (Luau LSP, StyLua, Selene, Rojo). Files format on save.

## Setup on macOS

You need [Roblox Studio](https://create.roblox.com), Git and [VS Code](https://code.visualstudio.com). If `git --version` asks you to install the command line developer tools, accept. Run the commands below in Terminal.

1. **Install Rokit**, the toolchain manager. Then close and reopen Terminal so `rokit` is on your PATH.
   ```sh
   curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
   ```
2. **Clone the repo and install the tools.** Say yes when Rokit asks to trust each tool.
   ```sh
   git clone https://github.com/rubaismail/roblox-dev-pipeline.git
   cd roblox-dev-pipeline
   rokit install
   ```
3. **Install the Rojo plugin into Studio.** With Studio closed, run `rojo plugin install`.
4. **Install packages for a game.**
   ```sh
   cd games/countdown-crew
   wally install
   ```
5. **Open VS Code** in the repo and accept the recommended extensions.

The rest of this README uses Windows paths. On macOS, use `/` instead of `\`.

## Daily workflow

1. In `games\countdown-crew`, run `rojo serve`.
2. Open the game's place in Studio, open the Rojo plugin (Plugins tab), and click **Connect**. Edits to `.luau` files now sync into Studio live.
3. Build parts, maps and UI in Studio as usual. Rojo only manages the folders listed in `default.project.json`, so anything else you make in Studio stays in the place file.
4. Before you push, run the same checks as CI from the repo root:
   ```powershell
   stylua .
   selene .
   lune run tools/run-specs games/countdown-crew
   ```

## Running tests

Specs are TestEZ `*.spec.luau` files in each game's `tests/` folder. There are two ways to run them.

- **From the terminal, no Studio:** from the repo root, run `lune run tools/run-specs games/countdown-crew`. This is what CI runs. It reads the game's Rojo project so specs can require modules the same way they do in Studio, and it supports the TestEZ features the specs use (`describe`, `it`, `beforeEach`, `afterEach`, and `expect` with `equal`, `near`, `ok`, `a`, `throw` and `never`).
- **In Studio:** in the game folder, run `wally install` once, then `rojo serve test.project.json`. Connect from Studio and press **Run** (F8). `TestRunner` runs every spec and prints the results to the Output window.

Specs cover pure logic like scoring, timers and station rules. Keep those modules free of services and Instances so they run in both places. Anything that needs a running game is checked by the playtest script in the game's `docs/` folder.

## CI

`.github/workflows/lint.yml` runs on every pull request and every push to `main`. It installs the pinned tools with Rokit, then runs `stylua --check .`, `selene .`, every game's specs with Lune, and `rojo build` on every game's project. A red check means run `stylua .` locally to fix formatting, or read the failing step's output.

## Adding a new game

1. Copy `games/countdown-crew` to `games/<new-game>` and delete its game-specific code.
2. Change `name` in both project files and in `wally.toml`.
3. Run `wally install` in the new folder.
