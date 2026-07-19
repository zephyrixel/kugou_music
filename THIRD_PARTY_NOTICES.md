# Third-party notices

KGMusic contains or links to third-party software. KGMusic's own source is
licensed under `GPL-3.0-or-later`; the components below retain their original
copyrights and licenses. This file is a distribution aid, not a replacement
for the license text shipped by each upstream project.

The authoritative dependency versions are recorded in `pubspec.lock`,
`native/kugou_bridge/Cargo.lock`, and the tracked build-tool manifests. Flutter
also generates `data/flutter_assets/NOTICES.Z` in release bundles with the
licenses collected from Flutter and Dart packages. Rust crate license texts
are collected in `THIRD_PARTY_RUST_NOTICES.txt`.

## Modified sources kept in this repository

| Component | Version | Copyright | License | Upstream |
| --- | --- | --- | --- | --- |
| `just_audio` | 0.10.6 | Ryan Heise and contributors | MIT; bundled ExoPlayer notices are Apache-2.0 | <https://github.com/ryanheise/just_audio> |
| `media_kit_libs_linux` | 1.2.1 | Hitesh Kumar Saini and contributors | MIT | <https://github.com/media-kit/media-kit> |
| `tray_manager` | 0.5.3 | LiJianying and contributors | MIT | <https://github.com/leanflutter/tray_manager> |
| `audio_service_win` | 0.0.3 | Hemant KArya and contributors | MIT | <https://github.com/HemantKArya/audio_service_win> |

The complete retained texts are in each `third_party/<package>/LICENSE` file.
Local modifications are visible in this repository's Git history and are
distributed under the upstream license for that component.

## Native and platform runtime components

- **Flutter engine and Dart runtime** — BSD-style licenses and additional
  third-party notices; source: <https://github.com/flutter/engine> and
  <https://github.com/dart-lang/sdk>. Their generated notices are included in
  `NOTICES.Z` in every Flutter release bundle.
- **Rust crates, including `kugou_sdk` 0.2.9** — licenses and source locations
  are listed with full discovered license texts in
  `THIRD_PARTY_RUST_NOTICES.txt`. Crate versions are fixed by `Cargo.lock` and
  their source archives are available from <https://crates.io/>.
- **SQLite** — SQLite itself is dedicated to the public domain; the Dart and
  Flutter integration packages retain their own licenses in `NOTICES.Z`.
- **mimalloc 2.1.2 (Linux)** — Copyright Microsoft Corporation and Daan Leijen,
  MIT license. The Linux media plugin links its allocator override into the
  application. The retained license is
  `third_party/licenses/mimalloc-2.1.2-LICENSE.txt`; source:
  <https://github.com/microsoft/mimalloc/tree/v2.1.2>.
- **just_audio_windows 0.2.3 (Windows)** — Copyright Bruno D'Luka and
  contributors, MIT license. It uses the Windows Runtime `MediaPlayer` and
  does not add a bundled libmpv or FFmpeg binary. Source:
  <https://github.com/bdlukaa/just_audio_windows>.
- **libmpv (Linux system dependency)** — the DEB and AppImage do not bundle
  libmpv or FFmpeg. The system must provide `libmpv.so.2` (the Debian/Ubuntu
  package is `libmpv2`). Upstream source is available from
  <https://github.com/mpv-player/mpv>.

## Corresponding source

For a tagged KGMusic release, the corresponding KGMusic source is the source
archive attached by GitHub to that same tag, including the vendored patches,
lockfiles, native bridge, platform runners, and packaging scripts. Dependency
source locations and exact versions are recorded by the lockfiles and the
notices above.

If a distributed binary and its matching source tag ever differ, do not
publish the binary. Rebuild it from the tagged source or publish a corrected
release with an explicit replacement notice.
