# Security Hub — Flutter App

Mobile surveillance app for the AI Security Hub server.
Connects to the Mini PC server over local WiFi.

---

## What It Does

- Live camera streams from all RTSP cameras
- Real-time AI detection alerts (fire, smoke, spill, fall, suspicious)
- Alert history with 10s incident clips and snapshots
- AI text search across all detection events
- Analytics and weekly detection trends
- Storage management panel with live disk status
- Notification toggles per detection type

---

## Screens

| Screen | What It Shows |
|--------|--------------|
| Dashboard | Live camera grid + server status + today's stats |
| Alerts | Real-time detection alerts with clips and snapshots |
| AI Search | Natural language search across all events |
| Analytics | Detection trends, top categories, camera activity |
| Reports | Camera activity, alert summary, system performance |
| Settings | Storage panel, notification toggles, server config |

---

## How Video Works

```
Mini PC (Server)                    Phone (App)
─────────────────                   ─────────────────────
data/clips/          ─── WiFi ───►  Alert clips
data/snapshots/      ─── WiFi ───►  Alert photos
```

- Video files live on the Mini PC disk
- App streams them directly over local WiFi
- No cloud, no upload — everything is local

---

## Storage Management Panel (Settings Screen)

The storage panel shows full disk information in real time:

```
┌──────────────────────────────────────────┐
│ 🔴 Storage  72.4% used    [WARNING] [🔄] │
│ ████████████████████████░░░░              │
│ [Used 724GB]  [Free 276GB]  [Total 1TB]   │
│ ────────────────────────────────────────  │
│ 📹 Recordings    450 GB    234 files      │
│ 🎬 Alert Clips   180 GB     89 files      │
│ 📸 Snapshots      94 MB    445 files      │
│ ────────────────────────────────────────  │
│ 🕐 Oldest file: 6.2 days old             │
│ 🔄 Auto-cleanup every 7 days             │
│ 📁 /data/recordings                       │
│                                            │
│  [  🧹  Clean Old Data  ]                 │ ← white (OK)
│  [  ⚠️  Free Space Now  ]                 │ ← red (Critical)
└──────────────────────────────────────────┘
```

### Status Badge

| Badge | Meaning |
|-------|---------|
| 🟢 OK | Disk is healthy, retention cleanup handles everything |
| 🟡 WARNING | Disk above 85% — consider cleaning soon |
| 🔴 CRITICAL | Disk above 95% — button turns red, emergency cleanup runs |

### Cleanup Button Behaviour

| Storage Level | Button Label | What Happens |
|---------------|-------------|--------------|
| OK / Warning | Clean Old Data | Deletes files older than retention period |
| Critical | Free Space Now (red) | Warning dialog → deletes oldest files first regardless of age |

When emergency cleanup runs, the snackbar shows exactly what was deleted:
```
⚠️ Emergency cleanup: 47 files, 12 events, 3 recordings removed
   (oldest files deleted to free space)
```

---

## Automatic Storage Protection (Server Side)

Two background threads run on the server automatically:

```
Thread 1 — Retention (every 60 min)
  Deletes files older than the configured retention period.
  Works silently without any user action.

Thread 2 — Emergency Watch (every 5 min)
  Checks if disk is ≥ 95% full.
  If yes → deletes oldest files first until disk is safe.
  Triggers even if no files have passed the retention window.
```

The app button gives the user immediate control without waiting
for the background threads.

---

## Connect to Server

1. Open the app
2. Enter the Mini PC IP address
3. API port: `8000`, Stream port: `8888`
4. Tap **Connect**

---

## Tech Stack

- Flutter + Dart
- Riverpod (state management)
- video_player (incident clip playback)
- WebSocket (real-time alerts)
- HTTP (REST API calls)

---

## Server

See the server README at `C:\AI Projects\ai-project\README.md`
for server setup, configuration, and API documentation.
