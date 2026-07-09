# Changelog

All notable changes to TVMonkey are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] — 2026-07-09

### Added
- Single self-contained binary: one `bun build --compile` output (TUI + bridge + launcher + injector), dispatched by flag (`--bridge` / `--launch` / `--inject`), default = TUI.
- `src/main.tsx` entrypoint dispatcher with `--version` / `--help`.
- `scripts/build.js` Bun build script that stubs `react-devtools-core` (Ink v7 devtools import is not a real dependency and crashes the compiled bunfs).
- `src/runtime/injected.ts` — the renderer runtime as an embedded string constant, replacing the runtime `readFileSync` path that was not embedded by Bun compile.
- Config stored at `~/.tvmonkey/env` (macOS/Linux) or `%APPDATA%/tvmonkey/env` (Windows); the TUI opens a config panel on first run when no config exists.
- `SECURITY.md` documenting the security review and how each finding was resolved.
- Security-review badge in the README.
- Background-service instructions for launchd (macOS), systemd (Linux), and Task Scheduler/NSSM (Windows) in `INSTALL.md`.
- TradingView Desktop verification section in `INSTALL.md`.

### Security
- Config file holding `NGQ_API_KEY` is written `0600` inside a `0700` directory, with `chmodSync` to also tighten pre-existing files.
- `NGQ_API_KEY` is stripped from the environment inherited by child processes, so the launcher-spawned TradingView Desktop never sees the secret.
- Numeric config fields are validated (ports `1..65535`, intervals `>0`, `NaN` falls back to defaults) so invalid values cannot reach `server.listen()` or fetch URLs.
- Fixed a latent `TV_APP_PATH` fallback that used the wrong default constant.

### Changed
- Background modes (bridge / launcher / injector) read config via `readEnv()` from the config file instead of `process.env`, because `bun build --compile` inlines `process.env.*` at build time.
- The TUI starts bridge and launcher by re-invoking itself (`process.execPath --bridge` / `--launch` in compiled mode; `npx tsx src/main.tsx --flag` in dev mode) instead of spawning `npx tsx <path>`.

### Removed
- `src/tui/index.tsx` (orphaned — `src/main.tsx` is now the entrypoint).
- `src/runtime/injected.js` (replaced by the embedded `src/runtime/injected.ts`).
- `ProcessManager` env-builder methods — children now read config from the file directly.

### Internal (prior to single-binary, context)
- TUI (Ink/React) with config panel, controls, and log pane.
- Cross-platform launcher (macOS `open -a`, Windows `.exe`).
- Configurable Pine input title via `TVMONKEY_INPUT_TITLE`.
- Flat-CDP protocol client (`src/injector/flat-cdp.ts`) replacing `chrome-remote-interface`.
- Bridge: NGQ poll + cache + HTTP `/health`, `/data/option-chain`, `/blob/option-chain`, bound to `127.0.0.1`.

[0.1.0]: https://keepachangelog.com/en/1.1.0/