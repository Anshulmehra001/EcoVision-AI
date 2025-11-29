# Test Execution Guide

## Prerequisites

Ensure Flutter is installed and in your PATH:
```bash
flutter --version
```

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test Suites

#### Unit Tests Only
```bash
# All unit tests
flutter test test/unit/

# Model tests
flutter test test/unit/models/

# Service tests
flutter test test/unit/services/
```

#### Integration Tests Only
```bash
# All integration tests
flutter test test/integration/

# Navigation tests
flutter test test/integration/navigation_test.dart

# Eco Action Hub tests
flutter test test/integration/eco_action_hub_test.dart

# Offline functionality tests
flutter test test/integration/offline_functionality_test.dart
```

#### Widget Tests
```bash
flutter test test/widget_test.dart
```

### Run with Coverage
```bash
flutter test --coverage
```

View coverage report:
```bash
# Install lcov (if not already installed)
# On Windows with Chocolatey:
choco install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
start coverage/html/index.html
```

### Run with Verbose Output
```bash
flutter test --verbose
```

### Run Specific Test
```bash
flutter test test/unit/models/classification_result_test.dart
```

## Test Results

After running tests, you should see output like:
```
00:01 +50: All tests passed!
```

## Troubleshooting

### Flutter Not Found
If you get "flutter: command not found", ensure Flutter is installed:
1. Download Flutter SDK from https://flutter.dev
2. Add Flutter to your PATH
3. Run `flutter doctor` to verify installation

### Test Failures
If tests fail:
1. Check error messages for specific failures
2. Ensure all dependencies are installed: `flutter pub get`
3. Verify assets are in place (models, data files)
4. Check that SharedPreferences mock is initialized

### Asset Loading Errors
If tests fail due to missing assets:
1. Ensure `assets/data/tasks.json` exists
2. Verify `pubspec.yaml` includes asset paths
3. Run `flutter pub get` to update asset bundle

## Expected Test Count

The test suite includes:
- **Unit Tests**: ~30 tests
  - Classification Result: 5 tests
  - Eco Task: 6 tests
  - User Progress: 10 tests
  - Permission Service: 9 tests

- **Integration Tests**: ~20 tests
  - Navigation: 7 tests
  - Eco Action Hub: 9 tests
  - Offline Functionality: 9 tests

- **Widget Tests**: ~10 tests
  - App initialization: 3 tests
  - Navigation: 4 tests
  - Theme: 1 test
  - Feature screens: 4 tests

**Total**: ~60 tests

## Performance Benchmarks

Tests verify these performance requirements:
- ✓ Navigation transitions: < 1 second
- ✓ Splash screen duration: 3 seconds
- ✓ Model initialization: < 5 seconds (logic tested)
- ✓ Image inference: < 3 seconds (logic tested)
- ✓ Audio inference: < 5 seconds (logic tested)

## CI/CD Integration

For continuous integration, use:
```yaml
# Example GitHub Actions workflow
- name: Run tests
  run: flutter test --coverage

- name: Upload coverage
  uses: codecov/codecov-action@v3
  with:
    files: coverage/lcov.info
```

## Notes

- Tests use mocked SharedPreferences for isolation
- AI model inference tests focus on testable logic
- Actual model files are not required for unit tests
- Permission tests verify logic, not actual system permissions
- All tests are designed to run without network connectivity
