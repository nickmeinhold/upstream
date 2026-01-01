# Claude Code Context

## Project Overview

Downstream TV Apps contains the Flutter applications for LG WebOS and Samsung Tizen Smart TVs. These apps provide a Netflix-style interface for browsing a personal video library.

## Architecture

- `webos_app/` - Flutter Web app for LG WebOS TVs
- `tizen_app/` - Native Flutter app for Samsung Tizen TVs

## Shared Code

Both apps share similar code structure:
- Models, services, and widgets are largely identical
- WebOS uses Flutter Web (JavaScript build)
- Tizen uses native Flutter via flutter-tizen

## Related Projects

- **downstream-server** - Backend API (separate repo)
- **downstream-cli** - Download/transcode/upload workflow

## Running Locally

```bash
# WebOS app
cd webos_app
flutter run -d chrome

# Tizen app
cd tizen_app
flutter run -d macos
```

## Workflow

Before committing, run the Dart analyzer on both apps using the MCP tool.
