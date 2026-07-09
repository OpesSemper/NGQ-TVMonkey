# TVMonkey × NGQ Injector — คู่มือ (macOS / Windows)

คู่มือติดตั้งและรัน TVMonkey เพื่อ inject NGQ option-chain data เข้า Pine `input.text_area` ใน TradingView Desktop

## สิ่งที่ต้องมี

- **TradingView Desktop** ติดตั้งแล้ว (ทดสอบกับ v3.3.0, macOS + Windows)
- **NGQ API Key** — สร้างได้ที่ NGQ → Settings → API Keys
- สำหรับ **build binary** เอง: Bun (`bun --version`) + `npm install`
- สำหรับ **รัน dev mode**: Node.js 24+ (`node --version`)

## ติดตั้ง — 3 ทางเลือก

### ทางเลือก 1: ดาวน์โหลด binary สำเร็จ (ง่ายสุด)

ดาวน์โหลด zip จาก [NGQ-TVMonkey Releases](https://github.com/OpesSemper/NGQ-TVMonkey/releases):

| ไฟล์ | แพลตฟอร์ม |
|---|---|
| `tvmonkey-darwin-arm64.zip` | macOS (Apple Silicon) |
| `tvmonkey-win32-x64.zip` | Windows (x64) |

แตกไฟล์แล้ววาง binary ใน PATH:

```bash
# macOS / Linux
unzip tvmonkey-darwin-arm64.zip -d ~/.local/bin
chmod +x ~/.local/bin/tvmonkey

# Windows (PowerShell)
Expand-Archive tvmonkey-win32-x64.zip -DestinationPath C:\Tools
# แล้วเพิ่ม C:\Tools เข้า PATH
```

Binary ไม่ต้องการ Bun/Node runtime — self-contained ~62 MB.

### ทางเลือก 2: install script (ต้อง build เอง ครั้งเดียว)

ใช้ install script จาก repo distribution:

```bash
git clone https://github.com/OpesSemper/NGQ-TVMonkey.git
cd NGQ-TVMonkey

# macOS / Linux
bash install.sh

# Windows (PowerShell)
pwsh install.ps1
```

ต้องติดตั้ง [Bun](https://bun.sh) ก่อน — script จะ build binary แล้ววางใน PATH ให้อัตโนมัติ.

### ทางเลือก 3: build จาก source (repo นี้)

```bash
cd third-party-integrate-for-dasktop/tvmonkey
npm install
npm run build        # → dist/tvmonkey
```

## ตรวจสอบ TradingView Desktop ก่อนเริ่ม

TVMonkey สื่อสารกับ TradingView Desktop ผ่าน Chrome DevTools Protocol (CDP) ดังนั้นต้องแน่ใจว่า TV ติดตั้งและตั้งค่าถูกต้อง:

### 1. ตรวจว่าติดตั้งแล้วและที่ path ถูก

```bash
# macOS
ls -la /Applications/TradingView.app

# Windows (PowerShell)
Test-Path "$env:LOCALAPPDATA\TradingView\TradingView.exe"
```

ถ้า path ไม่ตรงค่าเริ่มต้น (เช่นติดตั้งที่อื่น) → ตั้ง `TradingView Path` ใน config ให้ตรงจริง

### 2. remote-debugging flag ทำงานได้

TVMonkey เปิด TV ด้วย flag `--remote-debugging-port=9222`. ตรวจหลัง launcher start:

```bash
curl -s http://127.0.0.1:9222/json/version
```

ถ้าส่งคืน JSON (`webSocketDebuggerUrl`, `Browser`) = CDP ทำงาน. ถ้า connection refused:
- ปิด TV ทุกหน้าต่างก่อน (Cmd-Q / Alt-F4) — flag ติดตอนเปิดใหม่เท่านั้น
- รัน launcher ใหม่ (`l` ใน TUI หรือ `tvmonkey --launch`)
- รอ ~5–10s ให้ chart renderer bootstrap

### 3. Single Instance (Windows)

TradingView บน Windows เปิดแบบ single instance — ถ้าเปิดอยู่แล้ว flag `--remote-debugging-port` จะไม่ติด ต้องปิดทุกหน้าต่างก่อนรัน launcher เสมอ

### 4. Pine indicator มี `input.text_area` ที่ตรงชื่อ

ใน Pine indicator ของคุณต้องมี:

```pine
NGQ_DATA = input.text_area("", "NGQ Data", group="Data Feed")
```

ชื่อ `"NGQ Data"` ต้องตรงกับ `Pine Input Title` ใน config TVMonkey. ถ้าตั้งชื่ออื่น → ตั้งค่า config ให้ตรง

### 5. settings dialog เปิดอยู่ตลอด (สำคัญ)

TVMonkey อ่าน/เขียน textarea ได้**ต่อเมื่อ indicator settings dialog เปิดอยู่เท่านั้น**:
1. เปิด indicator บน chart
2. คลิก **gear icon** (settings) → dialog ปรากฏ
3. คงไว้อย่างนั้น — TVMonkey push CSV blob เข้า textarea ทุก 30s โดยอัตโนมัติ

ถ้าปิด dialog → `blob push result { ok: false, reason: 'textarea_not_found' }` (ปกติ เปิดใหม่ได้)

### สรุปตรวจสอบ

| ตรวจสอบ | คำสั่ง / วิธี | ผลที่คาดหวัง |
|---|---|---|
| ติดตั้งที่ path | `ls /Applications/TradingView.app` | มีไฟล์ |
| CDP ทำงาน | `curl -s http://127.0.0.1:9222/json/version` | JSON มี `webSocketDebuggerUrl` |
| Pine title ตรง | เปิด Pine source ดูชื่อ `input.text_area` | ตรง `Pine Input Title` |
| dialog เปิด | คลิก gear icon | textarea ปรากฏใน dialog |

## รันครั้งแรก — TUI จัดการ config ให้

```bash
tvmonkey
```

ถ้าไม่มี config TUI จะเปิด **config panel** อัตโนมัติ ให้กรอก:

| Field | ค่าเริ่มต้น | หมายเหตุ |
|---|---|---|
| NGQ API Key | (ว่าง) | เปลี่ยนเป็น key จริง — **required** |
| NGQ Series | `GCQ6` | front-month gold contract |
| Bridge Port | `8787` | แก้ถ้า port ชน |
| Poll Interval | `30000` | ms (30 วินาที) |
| CDP Port | `9222` | TradingView remote debugging port |
| TradingView Path | auto | macOS: `/Applications/TradingView.app` |
| **Pine Input Title** | `NGQ Data` | ต้องตรงกับชื่อ `input.text_area` ใน Pine indicator |

กด **↵ enter** เพื่อ save → บันทึกลง `~/.tvmonkey/env` (macOS/Linux) หรือ `%APPDATA%\tvmonkey\env` (Windows)

> กด `esc`/`q` ออกจาก config panel

## การรันประจำวัน (TUI)

```bash
tvmonkey
```

ภายใน TUI:
1. กด `b` → start bridge (poll NGQ + cache)
2. กด `l` → start launcher (เปิด TradingView + inject runtime)
3. เปิด indicator settings dialog (gear icon) → textarea ถูกเติม CSV blob ทุก 30s
4. ดู log ทั้งหมดใน log pane
5. กด `s` → stop all, `^q` → quit

> ⚠️ **ต้องเปิด settings dialog ไว้ตลอด** — TVMonkey อ่าน/เขียน textarea ได้ต่อเมื่อ dialog เปิดอยู่

## รัน bridge เป็น background service (headless)

```bash
tvmonkey --bridge
```

เหมาะกับไม่ต้องการ TUI หรือติดตั้งเป็น auto-start service:

### macOS — launchd

สร้าง `~/Library/LaunchAgents/com.tvmonkey.bridge.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.tvmonkey.bridge</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/local/bin/tvmonkey</string>
    <string>--bridge</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict>
</plist>
```

```bash
launchctl load ~/Library/LaunchAgents/com.tvmonkey.bridge.plist
```

### Linux — systemd user unit

สร้าง `~/.config/systemd/user/tvmonkey-bridge.service`:

```ini
[Unit]
Description=TVMonkey bridge
[Service]
ExecStart=/usr/local/bin/tvmonkey --bridge
Restart=always
[Install]
WantedBy=default.target
```

```bash
systemctl --user enable --now tvmonkey-bridge
```

### Windows

ใช้ Task Scheduler หรือ NSSM:

```
Program: C:\Tools\tvmonkey.exe
Arguments: --bridge
```

แล้ว set **Run whether user is logged on or not** + **Trigger at logon**.

## การรัน manual แบบ dev

ถ้า build binary หรือรัน dev mode จาก source:

```bash
npm run tui      # TUI
npm run bridge   # bridge
npm run launch   # launcher
npm run inject   # standalone injector
```

## Pine Input Title — custom name

คุณเปลี่ยนชื่อ `input.text_area` ใน Pine ได้:

```pine
//@version=6
indicator("My Indicator", overlay=true)
NGQ_DATA = input.text_area("", "My Custom Name", group="Data Feed")
```

จากนั้นใน TUI config panel ตั้ง `Pine Input Title = My Custom Name` → TVMonkey จะจับคู่ textarea ตามชื่อนั้น

## Windows

| จุด | macOS | Windows |
|---|---|---|
| Config path | `~/.tvmonkey/env` | `%APPDATA%\tvmonkey\env` |
| TV path default | `/Applications/TradingView.app` | `%LOCALAPPDATA%\TradingView\TradingView.exe` |
| Launcher spawn | `open -a` | spawn `.exe` ตรง |

TradingView บน Windows เปิดด้วย Single Instance: เมื่อเรียก launcher → ต้องปิด TV ก่อนหรือยอมรับว่า instance ใหม่จะ re-use CDP flag ไม่ได้ (ปิดแล้วเปิดใหม่เสมอผ่าน launcher)

## แก้ปัญหา (troubleshooting)

### bridge ขึ้น "NGQ_API_KEY is not set"
- ยังไม่มี `~/.tvmonkey/env` หรือ key ว่าง
- รัน TUI ครั้งเดียวเพื่อสร้าง/กรอก config

### launcher ขึ้น "No TradingView chart target found"
- ปิด TV ให้หมด → รัน launcher ใหม่ — flag `--remote-debugging-port` ติดตอนเปิดใหม่เท่านั้น
- รอให้ chart load (~5-10s) launcher retry อัตโนมัติ

### "Page.enable timeout"
- chart renderer ยัง bootstrap — launcher retry อัตโนมัติ 5 ครั้ง

### "blob push result { ok: false, reason: 'textarea_not_found' }"
- ต้องเปิด **indicator settings dialog** (gear icon) ให้ textarea ปรากฏ
- ถ้าเปิดแล้วยังไม่เจอ → เช็ค `Pine Input Title` ตรงกับชื่อใน Pine หรือ TV DOM เปลี่ยน → ดู `docs/manual-test.md`

### bridge ขึ้น "EADDRINUSE :::8787"
- bridge อันเก่ารันอยู่ → `lsof -ti:8787 | xargs kill -9`

### ข้อมูลไม่อัปเดต (textarea ค้าง)
- ตรวจ bridge log ว่า poll — ถ้า NGQ ล่มจะ log `[cache] fetch failed, serving last-good`
- `curl -s http://127.0.0.1:8787/health` → `stale:true` = NGQ ล่ม, bridge serve last-good
- เช็ค `NGQ_SERIES` ว่ายัง active (GCM6 = June → expired, GCQ6 = Aug)

## TradingView update แล้วทำไง

TVMonkey ออกแบบให้ทน TV update:
1. รัน `tvmonkey --launch` ใหม่ — ไม่ต้องแก้ไฟล์ TV
2. ถ้าพัง ดู log ที่จุดเปราะบาง (logging ครอบไว้):
   - CDP → `[cdp]` / `[injector]` log
   - Runtime install → `Runtime.evaluate threw`
   - Selector → `[tvmonkey]` log ใน DevTools (`http://127.0.0.1:9222` → inspect chart)
3. แก้ `src/runtime/injected.js` ตาม DOM ใหม่ → rebuild binary → commit

## ไฟล์สำคัญ

| ไฟล์ | หน้าที่ |
|---|---|
| `dist/tvmonkey` | single self-contained binary (TUI + bridge + launcher + injector) |
| `~/.tvmonkey/env` | API key + config (created by TUI first run) |
| `src/main.tsx` | binary entrypoint: dispatch TUI / --bridge / --launch / --inject |
| `scripts/build.js` | Bun compile script + react-devtools-core stub |
| `src/tui/` | TUI (Ink/React): config, controls, log pane |
| `src/bridge/` | poll NGQ + cache + serve HTTP |
| `src/injector/` | CDP flat-protocol client + blob-push loop |
| `src/launcher/` | เปิด TradingView + รัน injector (cross-platform) |
| `src/runtime/injected.js` | runtime ใน renderer: หา textarea + inject |
| `pine/ngq-consumer.pine` | Pine indicator ตัวอย่าง |
| `docs/manual-test.md` | checklist ค้น selector หลัง TV update |
