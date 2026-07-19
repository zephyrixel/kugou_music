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

mkdir -p "$output_dir"
rm -rf "$app_dir" "$deb_root"
mkdir -p "$app_dir/usr/bin" "$app_dir/usr/lib/kgmusic" \
  "$app_dir/usr/share/applications" "$app_dir/usr/share/icons/hicolor/1024x1024/apps"
cp -a "$bundle_dir/." "$app_dir/usr/lib/kgmusic/"
mpv_library="$(ldconfig -p | awk '/libmpv\.so\.2 \(/ && !found {value=$NF; found=1} END {print value}')"
if [[ -z "$mpv_library" || ! -f "$mpv_library" ]]; then
  echo "libmpv.so.2 was not found; install libmpv-dev before packaging" >&2
  exit 1
fi
cp -L "$mpv_library" "$app_dir/usr/lib/kgmusic/lib/libmpv.so.2"
ln -s ../lib/kgmusic/kgmusic "$app_dir/usr/bin/kgmusic"
cp "$project_root/packaging/linux/com.zephyrixel.kgmusic.desktop" \
  "$app_dir/com.zephyrixel.kgmusic.desktop"
cp "$project_root/packaging/linux/com.zephyrixel.kgmusic.desktop" \
  "$app_dir/usr/share/applications/com.zephyrixel.kgmusic.desktop"
cp "$project_root/assets/branding/app_icon.png" \
  "$app_dir/com.zephyrixel.kgmusic.png"
cp "$project_root/assets/branding/app_icon.png" \
  "$app_dir/usr/share/icons/hicolor/1024x1024/apps/com.zephyrixel.kgmusic.png"
ln -s com.zephyrixel.kgmusic.png "$app_dir/.DirIcon"
cp "$project_root/packaging/linux/AppRun" "$app_dir/AppRun"
chmod +x "$app_dir/AppRun"

mkdir -p "$deb_root/DEBIAN" "$deb_root/opt/kgmusic" \
  "$deb_root/usr/bin" "$deb_root/usr/share/applications" \
  "$deb_root/usr/share/icons/hicolor/1024x1024/apps" \
  "$deb_root/usr/share/metainfo"
cp -a "$bundle_dir/." "$deb_root/opt/kgmusic/"
ln -s /opt/kgmusic/kgmusic "$deb_root/usr/bin/kgmusic"
cp "$project_root/packaging/linux/com.zephyrixel.kgmusic.desktop" \
  "$deb_root/usr/share/applications/"
cp "$project_root/packaging/linux/com.zephyrixel.kgmusic.metainfo.xml" \
  "$deb_root/usr/share/metainfo/"
cp "$project_root/assets/branding/app_icon.png" \
  "$deb_root/usr/share/icons/hicolor/1024x1024/apps/com.zephyrixel.kgmusic.png"
sed "s/@VERSION@/$version/" "$project_root/packaging/linux/control" \
  > "$deb_root/DEBIAN/control"
find "$app_dir" "$deb_root" -type d -exec chmod 0755 {} +
dpkg-deb --root-owner-group --build "$deb_root" \
  "$output_dir/kgmusic_${version}_amd64.deb"
