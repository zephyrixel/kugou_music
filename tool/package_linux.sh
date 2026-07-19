#!/usr/bin/env bash
set -euo pipefail
umask 022

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bundle_dir="$project_root/build/linux/x64/release/bundle"
output_dir="$project_root/build/packages"
app_dir="$output_dir/KGMusic.AppDir"
deb_root="$output_dir/deb-root"
version="${1:-1.0.0}"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.+-][0-9A-Za-z.-]+)?$ ]]; then
  echo "Invalid package version: $version" >&2
  exit 1
fi

if [[ ! -x "$bundle_dir/kgmusic" ]]; then
  echo "Linux release bundle not found: $bundle_dir" >&2
  exit 1
fi

install_static_notices() {
  local destination="$1"
  mkdir -p "$destination/licenses"
  install -m 0644 "$project_root/LICENSE" "$destination/LICENSE"
  install -m 0644 "$project_root/NOTICE" "$destination/NOTICE"
  install -m 0644 "$project_root/THIRD_PARTY_NOTICES.md" \
    "$destination/THIRD_PARTY_NOTICES.md"
  install -m 0644 "$project_root/THIRD_PARTY_RUST_NOTICES.txt" \
    "$destination/THIRD_PARTY_RUST_NOTICES.txt"
  install -m 0644 "$project_root/packaging/linux/copyright" \
    "$destination/copyright"
  install -m 0644 "$project_root/third_party/just_audio/LICENSE" \
    "$destination/licenses/just_audio-LICENSE.txt"
  install -m 0644 "$project_root/third_party/media_kit_libs_linux/LICENSE" \
    "$destination/licenses/media_kit_libs_linux-LICENSE.txt"
  install -m 0644 "$project_root/third_party/tray_manager/LICENSE" \
    "$destination/licenses/tray_manager-LICENSE.txt"
  install -m 0644 \
    "$project_root/third_party/licenses/mimalloc-2.1.2-LICENSE.txt" \
    "$destination/licenses/mimalloc-2.1.2-LICENSE.txt"
}

mkdir -p "$output_dir"
rm -rf "$app_dir" "$deb_root"
mkdir -p "$app_dir/usr/bin" "$app_dir/usr/lib/kgmusic" \
  "$app_dir/usr/share/applications" \
  "$app_dir/usr/share/icons/hicolor/512x512/apps" \
  "$app_dir/usr/share/metainfo" \
  "$app_dir/usr/share/doc/kgmusic"
cp -a "$bundle_dir/." "$app_dir/usr/lib/kgmusic/"
ln -s ../lib/kgmusic/kgmusic "$app_dir/usr/bin/kgmusic"
cp "$project_root/packaging/linux/com.zephyrixel.kgmusic.desktop" \
  "$app_dir/com.zephyrixel.kgmusic.desktop"
cp "$project_root/packaging/linux/com.zephyrixel.kgmusic.desktop" \
  "$app_dir/usr/share/applications/com.zephyrixel.kgmusic.desktop"
cp "$project_root/packaging/linux/com.zephyrixel.kgmusic.metainfo.xml" \
  "$app_dir/usr/share/metainfo/com.zephyrixel.kgmusic.appdata.xml"
cp "$project_root/packaging/linux/com.zephyrixel.kgmusic.png" \
  "$app_dir/com.zephyrixel.kgmusic.png"
cp "$project_root/packaging/linux/com.zephyrixel.kgmusic.png" \
  "$app_dir/usr/share/icons/hicolor/512x512/apps/com.zephyrixel.kgmusic.png"
ln -s com.zephyrixel.kgmusic.png "$app_dir/.DirIcon"
cp "$project_root/packaging/linux/AppRun" "$app_dir/AppRun"
chmod +x "$app_dir/AppRun"
install_static_notices "$app_dir/usr/share/doc/kgmusic"

mkdir -p "$deb_root/DEBIAN" "$deb_root/opt/kgmusic" \
  "$deb_root/usr/bin" "$deb_root/usr/share/applications" \
  "$deb_root/usr/share/icons/hicolor/512x512/apps" \
  "$deb_root/usr/share/metainfo" "$deb_root/usr/share/doc/kgmusic"
cp -a "$bundle_dir/." "$deb_root/opt/kgmusic/"
ln -s /opt/kgmusic/kgmusic "$deb_root/usr/bin/kgmusic"
cp "$project_root/packaging/linux/com.zephyrixel.kgmusic.desktop" \
  "$deb_root/usr/share/applications/"
cp "$project_root/packaging/linux/com.zephyrixel.kgmusic.metainfo.xml" \
  "$deb_root/usr/share/metainfo/"
cp "$project_root/packaging/linux/com.zephyrixel.kgmusic.png" \
  "$deb_root/usr/share/icons/hicolor/512x512/apps/com.zephyrixel.kgmusic.png"
install_static_notices "$deb_root/usr/share/doc/kgmusic"
sed "s/@VERSION@/$version/" "$project_root/packaging/linux/control" \
  > "$deb_root/DEBIAN/control"
find "$app_dir" "$deb_root" -type d -exec chmod 0755 {} +
dpkg-deb --root-owner-group --build "$deb_root" \
  "$output_dir/kgmusic_${version}_amd64.deb"
