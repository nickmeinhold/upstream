# Claude Code Context

## Project Overview

Downstream is a self-hosted web app for discovering new streaming content. Users can browse, search, track watched content, and request downloads.

## Architecture

- `frontend/` - Flutter Web app (WASM)
- `server/` - Dart backend using shelf

## Related Projects

**downstream-cli** (`../downstream-cli`) handles the downloading workflow:
- Polls Firestore every 5 seconds for pending content requests
- Uses Jackett to search for torrents
- Manages downloads via Transmission
- Transcodes to HLS and uploads to B2
- Updates request status as it progresses

## How They Relate

```
User browses in downstream-web
         ↓
Clicks "Request for Download"
         ↓
Request saved to Firestore (status: pending)
         ↓
downstream-cli polls Firestore every 5 seconds
         ↓
Picks up request, downloads, transcodes, uploads
         ↓
Updates Firestore status → reflected in web app
```

## Request Status Flow

| Status | Set By | Meaning |
|--------|--------|---------|
| `pending` | web app | User requested, waiting for CLI |
| `downloading` | CLI | Torrent added to Transmission |
| `transcoding` | CLI | Converting to HLS format |
| `uploading` | CLI | Uploading to B2 storage |
| `available` | CLI | Ready to stream |
| `failed` | CLI | Error occurred |

## Environment Variables

Server requires (in `server/.env`):
- `TMDB_API_KEY` - Content discovery
- `FIREBASE_PROJECT_ID` - Auth and Firestore
- `FIREBASE_SERVICE_ACCOUNT` - Service account JSON (inline or path)
- `OMDB_API_KEY` - Optional, for IMDB/RT/Metacritic ratings

## Running Locally

```bash
# Server
cd server
set -a && source .env && set +a
dart run bin/server.dart

# Frontend (separate terminal)
cd frontend
flutter run -d chrome
```
