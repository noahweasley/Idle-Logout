# Contributing

Thank you for your interest in contributing to this Idle Logout package.

Contributions of all kinds are welcome, including bug fixes, new features, documentation improvements, performance optimizations, and additional test coverage. Before submitting a pull request, please review the guidelines below to help keep the project consistent and maintainable.

---

## Continuous Integration

This package uses GitHub Actions to automatically verify every push and pull request.

The CI pipeline performs the following checks:

- Code formatting
- Static analysis
- Unit tests
- Code coverage validation

The project follows the rules provided by `very_good_analysis` and enforces minimum coverage requirements using `very_good_coverage`.

Before opening a pull request, ensure all checks pass locally.

---

## Development Setup

Install dependencies:

```sh
dart pub get
```

---

## Formatting

Format all Dart files before committing:

```sh
dart format .
```

---

## Static Analysis

Run the analyzer to ensure the codebase satisfies all lint rules:

```sh
dart analyze
```

---

## Running Tests

Run the full test suite:

```sh
dart test
```

Run tests with coverage:

```sh
dart test --coverage=coverage
```

Generate an LCOV report:

```sh
dart pub global activate coverage 1.15.0

dart run coverage:format_coverage \
  --lcov \
  --in=coverage \
  --out=coverage/lcov.info \
  --packages=.dart_tool/package_config.json
```

Filter external packages from the report:

```sh
lcov --remove coverage/lcov.info \
  --ignore-errors unused \
  '*/.pub-cache/*' \
  -o coverage/filtered.info
```

Generate an HTML coverage report:

```sh
genhtml coverage/filtered.info -o coverage/
```

Open the report:

```sh
open coverage/index.html
```

---

## Pull Requests

When submitting a pull request:

1. Add or update tests for any behavior changes.
2. Ensure all existing tests continue to pass.
3. Run formatting and analysis before pushing.
4. Verify coverage remains above the required threshold.
5. Keep pull requests focused on a single change whenever possible.

---

## Useful Commands

Run everything locally before submitting a pull request:

```sh
dart format .
dart analyze
dart test
```

For coverage verification:

```sh
dart test --coverage=coverage

dart run coverage:format_coverage \
  --lcov \
  --in=coverage \
  --out=coverage/lcov.info \
  --packages=.dart_tool/package_config.json

lcov --remove coverage/lcov.info \
  --ignore-errors unused \
  '*/.pub-cache/*' \
  -o coverage/filtered.info
```
