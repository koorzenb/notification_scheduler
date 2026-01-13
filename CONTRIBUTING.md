# Contributing to Announcement Scheduler

Thank you for your interest in contributing to Announcement Scheduler! We welcome contributions from the community and appreciate your help in making this package better.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing Requirements](#testing-requirements)
- [Commit Message Guidelines](#commit-message-guidelines)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment. We expect all contributors to:

- Be respectful and considerate in communication
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before submitting a bug report:

1. Check the [existing issues](https://github.com/koorzenb/announcement_scheduler/issues) to avoid duplicates
2. Ensure you're using the latest version of the package
3. Collect relevant information (Flutter version, device/OS, error logs)

When submitting a bug report, include:

- A clear, descriptive title
- Steps to reproduce the issue
- Expected vs. actual behavior
- Code snippets or minimal reproduction example
- Flutter doctor output (`flutter doctor -v`)
- Device/OS information

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- Use a clear and descriptive title
- Provide a detailed description of the proposed functionality
- Explain why this enhancement would be useful
- Include code examples if applicable

### Contributing Code

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following our [code style guidelines](#code-style-guidelines)
4. Add or update tests as needed
5. Ensure all tests pass
6. Commit your changes following our [commit guidelines](#commit-message-guidelines)
7. Push to your fork
8. Open a Pull Request

## Development Setup

### Prerequisites

- Flutter SDK (see `pubspec.yaml` for version requirements)
- Android Studio or VS Code with Flutter extensions
- Git

### Initial Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/announcement_scheduler.git
cd announcement_scheduler

# Add upstream remote
git remote add upstream https://github.com/koorzenb/announcement_scheduler.git

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run analysis
flutter analyze
```

### Working with the Example App

```bash
cd example
flutter pub get
flutter run
```

## Pull Request Process

1. **Update Documentation**: Ensure README.md, API_REFERENCE.md, and inline documentation are updated
2. **Update Changelog**: Add your changes to CHANGELOG.md under "Unreleased"
3. **Run Tests**: All tests must pass (`flutter test`)
4. **Run Analysis**: Code must pass analysis (`flutter analyze`)
5. **Format Code**: Run `dart format .` before committing
6. **Link Issues**: Reference any related issues in your PR description
7. **Description**: Provide a clear description of what your PR does and why

### PR Review Criteria

- Code follows project style guidelines
- Tests are included and passing
- Documentation is updated
- No breaking changes without discussion
- Commit history is clean and meaningful

## Code Style Guidelines

### Dart Style

Follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style) and project conventions:

- Use single quotes for strings: `'text'`
- Use arrow functions for simple callbacks: `() => action()`
- Prefer `async/await` over `.then()`
- Use enums instead of string constants
- Document public APIs with `///` doc comments
- Keep functions under 30-50 lines when possible
- Keep UI files under 200-250 lines

### File Organization

```dart
// Import order:
// 1. Dart SDK imports
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 4. Project imports
import '../models/announcement.dart';
```

### Command-Query Separation (CQS)

- No side effects in getters or retrieval methods
- Methods that modify state should not return values (except status/confirmation)
- Methods that return values should not modify state

### Constants

- Use `app_constants.dart` for shared constants
- Name constants in `lowerCamelCase` for `const` values
- Name constants in `UPPER_SNAKE_CASE` for configuration values

## Testing Requirements

### Test Coverage

- All public APIs must have unit tests
- Integration tests for complex flows
- Test both success and failure scenarios
- Include edge case testing

### Test Style

```dart
test('should schedule announcement successfully', () async {
  // Arrange
  final scheduler = await AnnouncementScheduler.initialize(
    config: testConfig,
  );
  
  // Act
  final result = await scheduler.scheduleAnnouncement(
    content: 'Test',
    announcementTime: TimeOfDay(hour: 10, minute: 0),
  );
  
  // Assert
  expect(result, isNotNull, reason: 'Announcement should be scheduled');
  expect(result.content, equals('Test'), reason: 'Content should match');
});
```

**Important**: All `expect` calls must include a `reason` parameter.

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/announcement_scheduler_test.dart

# Run with coverage
flutter test --coverage
```

## Commit Message Guidelines

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat(scheduler): add support for monthly recurrence

Implements monthly recurrence pattern for announcements.
Includes validation for day-of-month edge cases.

Closes #123
```

```
fix(tts): resolve crash on initialization failure

Handle TTS initialization failures gracefully by falling
back to notification-only mode.

Fixes #456
```

## Platform-Specific Contributions

### Android

- Test on multiple Android versions (API 21+)
- Verify notification permissions and behaviors
- Check alarm scheduling on different OEMs

### iOS

Currently not supported, but iOS contributions are welcome! If you're interested in adding iOS support, please open an issue to discuss implementation approach.

## Questions?

If you have questions about contributing:

1. Check existing documentation
2. Search [closed issues](https://github.com/koorzenb/announcement_scheduler/issues?q=is%3Aissue+is%3Aclosed)
3. Open a new issue with the "question" label

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Announcement Scheduler! 🎉
