# Downstream TV Apps

TV applications for LG WebOS and Samsung Tizen Smart TVs.

Browse your personal video library with a Netflix-style interface optimized for TV remote control.

```text
┌─────────────────────────────────────────────────────────────────┐
│  DOWNSTREAM                                   nick ▼            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │ ███████ │ │ ███████ │ │ ███████ │ │ ███████ │ │ ███████ │   │
│  │ ███████ │ │ ███████ │ │ ███████ │ │ ███████ │ │ ███████ │   │
│  │ ███████ │ │ ███████ │ │ ███████ │ │ ███████ │ │ ███████ │   │
│  │ ███████ │ │ ███████ │ │ ███████ │ │ ███████ │ │ ███████ │   │
│  │ Arcane  │ │ Dune 2  │ │ Shogun  │ │ Ripley  │ │ 3 Body  │   │
│  │ ★ 9.1   │ │ ★ 8.8   │ │ ★ 8.7   │ │ ★ 8.3   │ │ ★ 8.0   │   │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Features

- **Library**: Browse your video collection in Netflix-style horizontal rows grouped by genre
- **New Releases**: Discover new movies and TV shows from TMDB
- **Trending**: See what's trending today or this week
- **Search**: Search TMDB and request downloads
- **Queue**: Track download/transcode progress
- **Video Player**: HLS adaptive streaming with remote control support

## Apps

| App | Platform | Technology | Folder |
|-----|----------|------------|--------|
| **WebOS** | LG Smart TVs | Flutter Web | `webos_app/` |
| **Tizen** | Samsung Smart TVs | Native Flutter | `tizen_app/` |

## Project Structure

```
downstream-web/
├── webos_app/        # LG WebOS TV app (Flutter Web)
│   ├── lib/
│   ├── web/
│   └── README.md
├── tizen_app/        # Samsung Tizen TV app (Native Flutter)
│   ├── lib/
│   ├── tizen/
│   └── README.md
└── README.md
```

## Quick Start

### WebOS (LG TV)

```bash
cd webos_app
flutter run -d chrome   # Local testing
flutter build web       # Build for TV
```

See [webos_app/README.md](webos_app/README.md) for deployment instructions.

### Tizen (Samsung TV)

```bash
cd tizen_app
flutter run -d macos    # Local testing
flutter-tizen build tpk # Build for TV
```

See [tizen_app/README.md](tizen_app/README.md) for deployment instructions.

## Related Projects

- **[downstream-server](../downstream-server)**: Backend API for TMDB, ratings, and request management
- **[downstream-cli](https://github.com/nickmeinhold/downstream-cli)**: Download, transcode, and upload workflow

## License

MIT
