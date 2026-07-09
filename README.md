# TVMonkey × NGQ Data Injector

[![Security Review: Passed](https://img.shields.io/badge/security%20review-passed-brightgreen)](./SECURITY.md)
[![Platform: macOS + Windows](https://img.shields.io/badge/platform-macOS%20%2B%20Windows-blue)](#windows)
[![Binary: self-contained](https://img.shields.io/badge/binary-self--contained%20%7E62MB-orange)](#quick-start--single-binary-recommended)
[![Tests: 18/18](https://img.shields.io/badge/tests-18%2F18-brightgreen)](#docs)
[![Release](https://img.shields.io/github/v/release/OpesSemper/NGQ-TVMonkey?label=release)](https://github.com/OpesSemper/NGQ-TVMonkey/releases)

Injects NGQ option-chain data into a TradingView Desktop Pine `input.text_area`
via CDP + a local caching bridge. macOS + Windows.

> **Distribution:** prebuilt binaries are published to the public repo
> [`OpesSemper/NGQ-TVMonkey`](https://github.com/OpesSemper/NGQ-TVMonkey) —
> download a release, or clone that repo and run its install scripts.
> This source repo (TradingviewIndicator) builds those releases via the
> `tvmonkey-release` GitHub Actions workflow on tag push.

> **Security:** this project passed a focused security review (secret-at-rest
> hardening, child-env secret leakage, bind surface, config validation). See
> [`SECURITY.md`](./SECURITY.md) for the findings and how they were resolved.

## Quick Start — prebuilt binary (recommended)

Download the zip for your platform from the
[latest release](https://github.com/OpesSemper/NGQ-TVMonkey/releases):

- `tvmonkey-darwin-arm64.zip` — macOS (Apple Silicon)
- `tvmonkey-win32-x64.zip` — Windows (x64)

Unzip and put the binary on your PATH:

```bash
# macOS / Linux
unzip tvmonkey-darwin-arm64.zip -d ~/.local/bin
chmod +x ~/.local/bin/tvmonkey

# Windows
Expand-Archive tvmonkey-win32-x64.zip -DestinationPath C:\Tools
# then add C:\Tools to PATH
```

Then run `tvmonkey` — first run opens a config panel. Fill your NGQ API key,
save, then press `b` (bridge) and `l` (launcher). Config is stored at
`~/.tvmonkey/env` (macOS/Linux) or `%APPDATA%\tvmonkey\env` (Windows).

One binary, several modes:

```bash
tvmonkey              # TUI (default)
tvmonkey --bridge     # background bridge service (no UI)
tvmonkey --launch     # open TradingView + inject runtime
tvmonkey --inject     # inject into an already-running CDP target
tvmonkey --version / --help
```

The TUI starts bridge + launcher by re-invoking itself with `--bridge`/`--launch`,
so you only ship one file.

## Quick Start — install script (from the public dist repo)

Clone [`OpesSemper/NGQ-TVMonkey`](https://github.com/OpesSemper/NGQ-TVMonkey)
and run the bundled installer (requires [Bun](https://bun.sh) for the one-time
build; the resulting binary needs no runtime):

```bash
git clone https://github.com/OpesSemper/NGQ-TVMonkey.git
cd NGQ-TVMonkey

# macOS / Linux
bash install.sh

# Windows (PowerShell)
pwsh install.ps1
```

## Quick Start — build from source (this repo)

```bash
cd third-party-integrate-for-dasktop/tvmonkey
npm install
npm run build            # → dist/tvmonkey (~62 MB, self-contained)
./dist/tvmonkey          # TUI: first run opens config panel
```

## Quick Start — dev (from source)

```bash
cd third-party-integrate-for-dasktop/tvmonkey
npm install
npm run tui             # full-screen TUI: configure, start bridge + launcher
```

Or run components manually:

```bash
npm test                # unit tests, no TradingView needed
npm run bridge          # start http://127.0.0.1:8787
npm run launch          # open TradingView + CDP inject + blob-push loop
```

## TUI (full-screen terminal UI)

`tvmonkey` (or `npm run tui` in dev) opens an Ink/React full-screen UI.

Keys:
| Key | Action |
|-----|--------|
| `b` | Start bridge |
| `l` | Start launcher |
| `s` | Stop all |
| `c` | Config panel (edit API key, series, ports, TV path, Pine input title) |
| `^q` | Quit |

Config panel fields — all editable with arrow keys + ↵ enter:
- NGQ API Key (masked)
- NGQ Base URL, Series
- Bridge Port, Poll Interval, CDP Port
- **TradingView Path** — auto-detects macOS/Windows default
- **Pine Input Title** — matches the `input.text_area` title in your Pine script

The Pine input title is configurable. In your Pine indicator, set:
```pine
NGQ_DATA = input.text_area("", "My Custom Title", group="Data Feed")
```
Then in the TUI config panel, set `Pine Input Title = My Custom Title`.
TVMonkey will match that textarea by name in the settings dialog.

## How data reaches Pine

The chart renderer (https://www.tradingview.com/...) cannot fetch
`http://127.0.0.1` (mixed content). The launcher/injector (Node side) pulls
the CSV blob from the bridge and pushes it into the renderer via CDP
`Runtime.evaluate`, calling `window.__TVMONKEY__.injectBlob(blob)` — the
runtime finds the Pine `input.text_area` inside the open settings dialog and
sets its value.

## Confirmed option-chain columns (from probe on 2026-07-08)

**Active series:** `GCQ6` (Gold Aug 2026) returned **494 rows**.

**Row keys (20):**
```
strike, optionSeries, futureSeries, snapshotAt, expirationDateUtc,
isWeekly, call, put, gamma, openInterestCall, openInterestPut,
intradayCall, intradayPut, expirationDte, volatility, theta, vega,
vanna, volga, isSyntheticAtm
```

Envelope: `{ ok, data: { option_chain: Array | null }, meta, error }`

## Architecture

```
NGQ API → bridge (HTTP, Node poll 30s) → launcher/injector (Node fetch)
  → CDP Runtime.evaluate → window.__TVMONKEY__.injectBlob(blob)
  → find textarea (visible + in settings dialog) → native setter + input event
  → Pine input.text_area
```

## Running --bridge as a background service

The bridge is headless and binds `127.0.0.1` only. To keep it running:

**macOS (launchd)** — `~/Library/LaunchAgents/com.tvmonkey.bridge.plist`:
```xml
<key>ProgramArguments</key>
<array>
  <string>/usr/local/bin/tvmonkey</string>
  <string>--bridge</string>
</array>
<key>RunAtLoad</key><true/>
<key>KeepAlive</key><true/>
```
`launchctl load ~/Library/LaunchAgents/com.tvmonkey.bridge.plist`

**Linux (systemd user)** — `~/.config/systemd/user/tvmonkey-bridge.service`:
```ini
[Service]
ExecStart=/usr/local/bin/tvmonkey --bridge
Restart=always
[Install]
WantedBy=default.target
```
`systemctl --user enable --now tvmonkey-bridge`

**Windows** — use NSSM or Task Scheduler to run `tvmonkey.exe --bridge` at logon.

Config for the service comes from `~/.tvmonkey/env` — run the TUI once first to create it.

## Build requirements

The binary is built with **Bun** (`bun scripts/build.js`). Runtime needs no Bun/Node —
it is fully self-contained. Dev mode (`npm run *`) uses Node 24 + tsx.

## Docs

- [INSTALL.md](INSTALL.md) — full installation guide
- [docs/manual-test.md](../../docs/manual-test.md) — selector discovery checklist
- [docs/superpowers/specs/2026-07-08-tvmonkey-ngq-injector-design.md](../../docs/superpowers/specs/2026-07-08-tvmonkey-ngq-injector-design.md) — design spec
- [docs/superpowers/plans/2026-07-08-tvmonkey-ngq-injector.md](../../docs/superpowers/plans/2026-07-08-tvmonkey-ngq-injector.md) — implementation plan