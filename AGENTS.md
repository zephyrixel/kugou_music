# Repository Guidelines

## Project Structure & Module Organization

KGMusic is an Android-first Flutter application backed by a Rust SDK bridge. Flutter code lives in `lib/`: `app/` contains routing and providers, `core/` contains shared models, database, player, native facade, design system, and widgets, while `features/` groups screens by user-facing capability. Rust bridge code is in `native/kugou_bridge/`; generated Flutter Rust Bridge bindings are under `lib/src/rust/`. Platform integration lives in `android/` and `rust_builder/`. Tests use matching `*_test.dart` files in `test/`, and architecture notes live in `docs/`.

## Build, Test, and Development Commands

- `flutter run`: launch the app on a connected Android device or emulator.
- `flutter analyze`: run Dart static analysis and project lints.
- `flutter test`: execute Flutter unit and database tests.
- `cargo test --manifest-path native/kugou_bridge/Cargo.toml`: run Rust bridge tests.
- `flutter build apk --debug`: build `build/app/outputs/flutter-apk/app-debug.apk`.
- `dart run build_runner build`: regenerate Drift and Freezed output after model changes.
- `flutter_rust_bridge_codegen generate`: regenerate Dart/Rust bindings after bridge API changes.

## Coding Style & Naming Conventions

Use two-space indentation for Dart and run `dart format .` before review. Follow `flutter_lints`; use `lower_snake_case.dart` filenames, `UpperCamelCase` types/widgets, and `lowerCamelCase` members and providers. Keep feature-specific UI inside its feature directory and reusable behavior in `core/`. Format Rust with `cargo fmt --all`; use standard Rust `snake_case` naming. Do not manually edit generated Drift, Freezed, or FRB files.

## Testing Guidelines

Use `flutter_test` and descriptive `test`/`group` names. Add focused tests for pagination, authentication policy, model behavior, and database migrations. There is no fixed coverage threshold, but every behavioral change should include a regression test when practical. Run both Flutter and Rust suites before submitting bridge changes.

## Commit & Pull Request Guidelines

History uses short, outcome-oriented subjects, with or without a Conventional Commit prefix, for example `feat: initialize KGMusic` or `功能：完善云歌单分页`. Keep each commit cohesive. Pull requests should summarize behavior, list verification commands, link relevant issues, and include screenshots or recordings for UI changes. Call out schema, generated binding, or SDK-version changes explicitly.

## Security & Architecture Notes

Use only `PlatformProfile::Lite`; never introduce a Standard-backend fallback. Store sessions in `flutter_secure_storage`, never Drift or logs. Keep `kugou_sdk`, Flutter Rust Bridge, and the pinned `freezed` version aligned with the lockfiles and documented toolchain.
