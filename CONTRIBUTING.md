# Contributing to EcoVision AI

Thank you for your interest in contributing to EcoVision AI! This document provides guidelines for contributing to the project.

## Code of Conduct

Be respectful, inclusive, and professional in all interactions.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported
2. Open a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable
   - Device and OS information

### Suggesting Features

1. Check if the feature has been suggested
2. Open a new issue with:
   - Clear description of the feature
   - Use cases and benefits
   - Possible implementation approach

### Pull Requests

1. **Fork the repository**
   ```bash
   git clone https://github.com/Anshulmehra001/EcoVision-AI.git
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the code style guide
   - Write tests for new features
   - Update documentation

4. **Test your changes**
   ```bash
   flutter test
   flutter analyze
   ```

5. **Commit your changes**
   ```bash
   git commit -m "Add feature: description"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Open a Pull Request**
   - Describe your changes
   - Reference related issues
   - Include screenshots if UI changes

## Development Setup

See [docs/development/getting-started.md](docs/development/getting-started.md)

## Code Style

### Dart Code

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter format .` before committing
- Run `flutter analyze` to check for issues

### File Naming

- **Dart files:** `snake_case.dart`
- **Classes:** `PascalCase`
- **Variables:** `camelCase`

### Import Organization

```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 4. Relative imports
import '../core/models/user_progress.dart';
```

## Testing

### Write Tests

- Unit tests for services and models
- Integration tests for features
- Widget tests for UI components

### Run Tests

```bash
# All tests
flutter test

# Specific test
flutter test test/unit/services/permission_service_test.dart

# With coverage
flutter test --coverage
```

## Documentation

- Update README.md for major changes
- Add/update docs in `docs/` folder
- Include code comments for complex logic
- Update CHANGELOG.md

## Commit Messages

Use clear, descriptive commit messages:

```
Add feature: plant disease detection
Fix bug: camera permission crash
Update docs: getting started guide
Refactor: optimize AI inference
```

## Pull Request Checklist

Before submitting:

- [ ] Code follows style guide
- [ ] Tests added/updated
- [ ] Tests passing
- [ ] Documentation updated
- [ ] No linting errors
- [ ] Commits are clear
- [ ] PR description is complete

## Review Process

1. Maintainers review PR
2. Address feedback
3. Approval and merge

## Areas for Contribution

### High Priority

- iOS version development
- Additional AI models
- Performance optimizations
- Bug fixes

### Medium Priority

- UI/UX improvements
- Internationalization
- Accessibility features
- Documentation improvements

### Low Priority

- Code refactoring
- Test coverage improvements
- Build optimizations

## Questions?

- Check [docs/](docs/)
- Open a discussion on GitHub
- Email: dev@ecovisionai.com

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to EcoVision AI! 🌿
