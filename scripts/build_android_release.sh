#!/usr/bin/env bash
# Build a Play-signed Android release and copy it to local/builds/.
#
# Usage:
#   ./scripts/build_android_release.sh <version> <apk|aab|full>
#   ./scripts/build_android_release.sh <apk|aab|full>
#
# Examples:
#   ./scripts/build_android_release.sh 0.1.1 aab
#   ./scripts/build_android_release.sh aab
#
# Needs android/key.properties and the upload keystore (both gitignored).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

usage() {
  cat >&2 <<'EOF'
Usage:
  ./scripts/build_android_release.sh <version> <apk|aab|full>
  ./scripts/build_android_release.sh <apk|aab|full>

  version  e.g. 0.1.1  (optional if pubspec.yaml has version:)
  type     apk | aab | full  (full = both)

  BUILD_NUMBER=N  optional env override for versionCode
EOF
  exit 1
}

is_build_type() {
  case "${1:-}" in
    apk|aab|full) return 0 ;;
    *) return 1 ;;
  esac
}

if [[ ! -f "$ROOT/android/key.properties" ]]; then
  echo "error: android/key.properties is missing." >&2
  echo "Copy android/key.properties.example and point storeFile at the upload keystore." >&2
  exit 1
fi

PUBSPEC_VERSION_LINE="$(grep -E '^version:' pubspec.yaml | head -1 | sed 's/version:[[:space:]]*//')"
PUBSPEC_NAME="${PUBSPEC_VERSION_LINE%%+*}"
PUBSPEC_NUMBER="${PUBSPEC_VERSION_LINE##*+}"
if [[ "$PUBSPEC_NUMBER" == "$PUBSPEC_VERSION_LINE" ]]; then
  PUBSPEC_NUMBER=""
fi

if [[ $# -lt 1 ]]; then
  usage
fi

if is_build_type "$1"; then
  VERSION="$PUBSPEC_NAME"
  BUILD_TYPE="$1"
elif [[ $# -ge 2 ]] && is_build_type "$2"; then
  VERSION="$1"
  BUILD_TYPE="$2"
else
  usage
fi

if [[ -z "$VERSION" ]]; then
  echo "error: no version (pass one or set version: in pubspec.yaml)" >&2
  exit 1
fi

if [[ -n "${BUILD_NUMBER:-}" ]]; then
  :
elif [[ -n "$PUBSPEC_NUMBER" && "$VERSION" == "$PUBSPEC_NAME" ]]; then
  BUILD_NUMBER="$PUBSPEC_NUMBER"
else
  BUILD_NUMBER="${VERSION##*.}"
fi

if ! [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "error: build number must be an integer (got '$BUILD_NUMBER')" >&2
  exit 1
fi

OUT_DIR="$ROOT/local/builds"
OUT_APK="$OUT_DIR/soar_albania_android_${VERSION}.apk"
OUT_AAB="$OUT_DIR/soar_albania_android_${VERSION}.aab"
mkdir -p "$OUT_DIR"

echo "Android release build"
echo "  type:         $BUILD_TYPE"
echo "  build-name:   $VERSION"
echo "  build-number: $BUILD_NUMBER"
echo

COMMON_ARGS=(
  --release
  --build-name="$VERSION"
  --build-number="$BUILD_NUMBER"
)

build_apk() {
  echo "→ Building APK…"
  flutter build apk "${COMMON_ARGS[@]}"
  local src="build/app/outputs/flutter-apk/app-release.apk"
  if [[ ! -f "$src" ]]; then
    echo "error: expected APK at $src" >&2
    exit 1
  fi
  mv -f "$src" "$OUT_APK"
  echo "  Done → $OUT_APK"
  echo
}

build_aab() {
  echo "→ Building App Bundle…"
  flutter build appbundle "${COMMON_ARGS[@]}"
  local src="build/app/outputs/bundle/release/app-release.aab"
  if [[ ! -f "$src" ]]; then
    echo "error: expected AAB at $src" >&2
    find build/app/outputs/bundle -name '*.aab' 2>/dev/null || true
    exit 1
  fi
  mv -f "$src" "$OUT_AAB"
  echo "  Done → $OUT_AAB"
  echo
}

case "$BUILD_TYPE" in
  apk)  build_apk ;;
  aab)  build_aab ;;
  full)
    build_apk
    build_aab
    ;;
esac

echo "All done."
case "$BUILD_TYPE" in
  apk)  echo "  $OUT_APK" ;;
  aab)  echo "  $OUT_AAB" ;;
  full)
    echo "  $OUT_APK"
    echo "  $OUT_AAB"
    ;;
esac
