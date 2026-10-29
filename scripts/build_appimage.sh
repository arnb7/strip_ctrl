#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$REPO_ROOT/app"
BUILD_DIR="$REPO_ROOT/release_fedora_x64"
APPDIR="/tmp/StripCtrl.AppDir"

echo "==> Building Flutter Linux release bundle..."
cd "$APP_DIR"
flutter build linux --release

echo "==> Assembling AppDir structure..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/applications"

# Copy binary, libs and assets
cp -r "$APP_DIR/build/linux/x64/release/bundle"/* "$APPDIR/"
cp "$APP_DIR/stripctl/stripctl.png" "$APPDIR/"
cp "$APP_DIR/stripctl/stripctl.png" "$APPDIR/.DirIcon"
cp "$APP_DIR/stripctl/stripctl.desktop" "$APPDIR/"
cp "$APP_DIR/stripctl/stripctl.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/stripctl.png"
cp "$APP_DIR/stripctl/stripctl.desktop" "$APPDIR/usr/share/applications/stripctl.desktop"

# Create AppRun
cat << 'RUNNER' > "$APPDIR/AppRun"
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/lib:${LD_LIBRARY_PATH}"
cd "${HERE}"
exec "${HERE}/stripctl" "$@"
RUNNER
chmod +x "$APPDIR/AppRun"

mkdir -p "$BUILD_DIR"
OUTPUT_APPIMAGE="$BUILD_DIR/StripCtrl-x86_64.AppImage"

echo "==> Packaging AppImage..."
ARCH=x86_64 /tmp/appimagetool "$APPDIR" "$OUTPUT_APPIMAGE"

cp "$OUTPUT_APPIMAGE" "$REPO_ROOT/StripCtrl.AppImage"
chmod +x "$REPO_ROOT/StripCtrl.AppImage"

echo "==> Done! Single AppImage generated at: $OUTPUT_APPIMAGE and $REPO_ROOT/StripCtrl.AppImage"
