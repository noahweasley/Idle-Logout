# For Agents

## Project guidance

- Read `.github/workflows/main.yaml` and keep test coverage at or above its `min_coverage`.
- Keep changes focused and preserve the package's supported platforms and public API.
- `IdleLogout` monitors inactivity and calls the app's callback; do not add app-specific authentication, navigation, or storage behavior.
- Add or update tests for behavior changes, especially timers, lifecycle handling, and controller operations.
- Follow `analysis_options.yaml`; run `dart format .`, `dart analyze`, and `very_good test --coverage` for relevant changes.
- Ignore writing tests in example folder