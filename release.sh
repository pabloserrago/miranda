#!/bin/bash
#
# Produce an App Store submission archive with the GM (non-beta) Xcode toolchain.
#
# Why this exists: on macOS 27 the stable Xcode 26.6 GUI will not launch, so the
# only GUI available is Xcode-beta (Xcode 27 beta). Archives built with the beta
# use a beta SDK, which App Store review rejects (ITMS-90111). The GM Xcode's
# command-line tools still work, so we archive from the CLI with DEVELOPER_DIR
# pinned to the GM Xcode. Override DEVELOPER_DIR per run if the GM Xcode lives
# elsewhere, e.g. DEVELOPER_DIR=/Applications/Xcode-26.6.app/Contents/Developer.
#
# Check the toolchain accepted by App Store review at:
#   https://developer.apple.com/news/releases/
#
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

cd "$(dirname "$0")"

ARCHIVE_PATH="../build/ios.xcarchive"

echo "== Toolchain =="
xcodebuild -version

# Refuse to build with a beta Xcode. GM build numbers look like 17F113;
# beta seeds look like 27A5228h (a 5xxx block).
XCODE_BUILD="$(xcodebuild -version | awk '/Build version/ {print $3}')"
if [[ "$XCODE_BUILD" =~ [0-9]+[A-Z]5[0-9]{3} ]]; then
  echo "ERROR: '$XCODE_BUILD' looks like a BETA Xcode. App Store review will reject it (ITMS-90111)."
  echo "       Point DEVELOPER_DIR at the GM/RC Xcode and re-run."
  exit 1
fi

echo "== Archiving =="
rm -rf "$ARCHIVE_PATH"
xcodebuild -project ios.xcodeproj -scheme ios \
  -destination 'generic/platform=iOS' -configuration Release \
  -archivePath "$ARCHIVE_PATH" archive

echo "== Verifying archive stamps =="
APP_PLIST="$ARCHIVE_PATH/Products/Applications/ios.app/Info.plist"
DTXCODEBUILD="$(/usr/libexec/PlistBuddy -c 'Print DTXcodeBuild' "$APP_PLIST")"
DTSDKNAME="$(/usr/libexec/PlistBuddy -c 'Print DTSDKName' "$APP_PLIST")"
CFBUILD="$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$APP_PLIST")"
echo "  CFBundleVersion = $CFBUILD"
echo "  DTXcodeBuild    = $DTXCODEBUILD"
echo "  DTSDKName       = $DTSDKNAME"

if [[ "$DTSDKNAME" == *"27"* || "$DTXCODEBUILD" =~ [0-9]+[A-Z]5[0-9]{3} ]]; then
  echo "ERROR: archive was built with a beta SDK/Xcode. Do NOT submit this build."
  exit 1
fi

echo "OK: archive built with GM toolchain -> $ARCHIVE_PATH"
echo "Next: open the archive in Xcode-beta Organizer (or Transporter) and upload,"
echo "      then select this build in App Store Connect and submit for review."
