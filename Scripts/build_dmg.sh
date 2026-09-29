#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DMG="${AIRCARD_DMG_OUTPUT:-$ROOT/build/AirCardMac.dmg}"
STAGING="$(mktemp -d -t aircard-dmg.XXXXXX)"
trap 'rm -rf "$STAGING"' EXIT
AIRCARD_APP_OUTPUT="$STAGING/AirCardMac.app" "$ROOT/Scripts/build_app.sh"

xattr -cr "$STAGING/AirCardMac.app" 2>/dev/null || true
for attribute in com.apple.FinderInfo com.apple.ResourceFork com.apple.fileprovider.fpfs#P com.apple.provenance; do
  xattr -dr "$attribute" "$STAGING/AirCardMac.app" 2>/dev/null || true
done
codesign --verify --deep --strict "$STAGING/AirCardMac.app"

hdiutil create \
  -volname "AirCard macOS" \
  -srcfolder "$STAGING" \
  -format UDZO \
  -ov \
  "$DMG"

rm -rf "$STAGING"
trap - EXIT
# Build and sign in the temporary staging directory, outside the synced
# workspace, so FileProvider cannot reattach metadata while codesign seals it.
echo "DMG listo: $DMG"
