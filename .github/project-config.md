# Day Break Project Configuration

This file contains project-specific settings and context for the Day Break Flutter application. All agent files reference this configuration.

---

## Project Identity

- **Name**: Day Break
- **Type**: Flutter Mobile Application
- **Platform**: Android
- **Purpose**: Minimalist weather notification app

---

## Technical Environment

### Platform & Versions

- **Flutter**: 3.35.3 (verify with `.fvmrc`)
- **Dart**: 3.6.1
- **Android SDK**: API 35+

### Architecture & Dependencies

- **State Management**: GetX
- **Local Storage**: Hive
- **Environment**: `flutter_dotenv`
- **HTTP Client**: Built-in
- **Timezone**: `timezone` package

---

## Project-Specific Rules

### Timezone Requirement

- **Critical**: All time operations must use `America/Halifax` timezone
- **Reason**: Per PRD requirement, regardless of device location
- **Implementation**: `tz.getLocation('America/Halifax')`

### API Configuration

- **Weather API**: Tomorrow.io
- **Environment Variable**: `TOMORROWIO_API_KEY`
- **Never hardcode**: Use `dotenv.env['TOMORROWIO_API_KEY']`

### File Limits

- **UI files**: ≤200-250 lines (use `part`/`part of` to split)
- **Functions**: ≤30-50 lines (extract helper methods)

### Testing Requirements

- **Mandatory**: All `expect` calls must include `reason` property
- **Location**: `test/` directory
- **Patterns**: Follow existing GetX and Hive test patterns

---

## Project Structure

```txt
lib/
├── main.dart                    # App entry point
├── controllers/                 # GetX controllers
├── models/                      # Data models
├── screens/                     # UI screens
├── services/                    # Business logic services
└── utils/                       # Helper utilities

assets/                          # Static resources (images, fonts, etc.)
pubspec.yaml                     # Dependencies and project configuration
test/                            # Unit tests
└── *_test.dart                  # Test files

.github/
├── copilot-instructions.md      # Quick reference
├── agent-*.md                   # Specialized agents
└── project-config.md           # This file
```

### File Organization Rules

- **Dependencies**: Use `pubspec.yaml` for all package dependencies
- **Static Resources**: Place images, fonts, assets in `assets/` directory
- **Source Code**: All Dart code goes in `lib/` directory
- **Tests**: Unit tests in `test/` directory with `*_test.dart` naming

---

## Context Documents

### Requirements & Strategy

- **`PRD.md`**: Product features, user stories, goals
- **`PLAN.md`**: Execution strategy, milestones, completed work

### Standards Reference

- **`.github/copilot-instructions.md`**: Quick reference and routing
- **Dart Style Guide**: <https://dart.dev/guides/language/effective-dart/style>

---

## Build & Deployment

### Development Commands

```bash
flutter pub get                 # Install dependencies
flutter analyze                 # Code analysis
flutter test                    # Run tests
flutter build apk --debug       # Debug build
dart update_version.dart     # Version bump for commits
```

### Release Build

```bash
build-prod-apk.bat                # Windows script for production APK
```

---

## Domain-Specific Context

### Weather Service

- **API Provider**: Tomorrow.io (not OpenWeatherMap)
- **Endpoints**: Realtime and forecast timelines
- **Data Fields**: temperature, humidity, weatherCode, windSpeed, etc.
- **Error Handling**: WeatherException for API failures

### Notification System

- **Schedule**: Daily notifications at user-specified time
- **Timezone**: Always Halifax, regardless of device location
- **Content**: Weather summary with temperature and conditions

### Location Service

- **Permissions**: ACCESS_FINE_LOCATION required
- **Fallback**: Manual location entry if permissions denied
- **Usage**: Lat/lon for weather API calls

---

## Security & Permissions

### Android Manifest Requirements

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### Environment Variables

- Store in `.env` file (not committed)
- Load with `flutter_dotenv`
- Reference in `.env.example`

---

## Known Limitations

- Production build script is Windows-only
- App requires notification permissions on device
- If builds fail, check Flutter version and Android SDK compatibility
