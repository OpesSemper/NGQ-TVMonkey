# TVMonkey — Security Review

A focused security review was completed on **2026-07-09** for the single-binary refactor (commit `7ad47e0` on branch `feat/tvmonkey-single-binary`).

## Review scope
- Secret storage (`~/.tvmonkey/env` / `%APPDATA%/tvmonkey/env`)
- Secret propagation to child processes / TradingView Desktop
- Local bridge bind surface
- Config parsing and validation
- Build-time `process.env` inlining in Bun `--compile`
- Build-time stub plugin for `react-devtools-core`

## Findings and resolutions

### HIGH — API key stored world-readable
- **Before:** `writeEnv` created the config dir with default perms and wrote the `env` file at `0644`.
- **After:** `mkdirSync(..., { mode: 0o700 })`, `writeFileSync(..., { mode: 0o600 })`, plus `chmodSync(path, 0o600)` to also tighten any pre-existing file.

### MEDIUM — API key leaked into the launcher child and into TradingView Desktop's environment
- **Before:** `ProcessManager` passed the full config into child env, including `NGQ_API_KEY`, which the launcher inherited and passed on to the spawned TradingView process.
- **After:** children now read config from the config file via `readEnv()`; `ProcessManager` strips `NGQ_API_KEY` from the inherited environment before spawning children.

### LOW — Invalid numeric config could yield `NaN`
- **Before:** `Number(...)` could produce `NaN` and flow into `server.listen()` and fetch URLs.
- **After:** `parseIntField()` validates values and falls back to safe defaults; ports are constrained to `1..65535`.

### LOW — Latent fallback bug in `TV_APP_PATH`
- **Before:** `map.get('TV_APP_PATH') ?? DEFAULTS.TVMONKEY_INPUT_TITLE` used the wrong default key.
- **After:** `?? DEFAULTS.TV_APP_PATH`.

### Build/runtime — Runtime-computed file path was not embedded by Bun compile
- **Before:** `readFileSync(join(import.meta.url, '../runtime/injected.js'))` works in dev but fails with `ENOENT` inside the compiled bunfs.
- **After:** `src/runtime/injected.ts` exports the runtime as a string constant, so it is embedded via the static import graph in both tsx dev and Bun compile.

### Build/runtime — Ink v7 devtools import crashed compiled binary
- **Before:** Ink v7's `import.meta.resolve('react-devtools-core')` succeeds inside bunfs, triggering a static import of the optional `react-devtools-core` package which is not a real dependency, causing a runtime crash.
- **After:** `scripts/build.js` stubs `react-devtools-core` with a no-op module at build time.

## Clean categories
- **No secret in logs** — config panel masks the API key; runtime logs never print it.
- **Bind surface** — the bridge binds `127.0.0.1` only (`src/bridge/index.ts`).
- **No shell invocation** — `ProcessManager` uses `spawn(cmd, args, { shell: false })`.
- **No secret baked into the binary** — no `define` or `process.env` inlining for secrets; all runtime config comes from the config file.

## Reporting issues
If you discover a new security issue in TVMonkey, please open an issue or contact the maintainer privately before publishing details.
