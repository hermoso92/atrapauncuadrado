#!/usr/bin/env bash
# Exporta un .ipa del target principal. Requiere Xcode y firma válida en el Mac.
# Uso:
#   ./scripts/export-ipa.sh              # IPA de desarrollo (instalable en dispositivos del team)
#   ./scripts/export-ipa.sh development
#   ./scripts/export-ipa.sh app-store    # Para subir a App Store Connect / TestFlight (Apple Distribution)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="Atrapa un cuadrado"
CONFIGURATION="Release"
DERIVED="$ROOT/build/DerivedDataExport"
ARCHIVE="$ROOT/build/AtrapaUnCuadrado.xcarchive"
EXPORT_DIR="$ROOT/build/ipa"

MODE="${1:-development}"
case "$MODE" in
  development|debugging)
    PLIST="$ROOT/scripts/ExportOptions-Development.plist"
    ;;
  app-store|appstore|store)
    PLIST="$ROOT/scripts/ExportOptions-AppStore.plist"
    ;;
  *)
    echo "Uso: $0 [development|app-store]" >&2
    exit 1
    ;;
esac

if [[ ! -f "$PLIST" ]]; then
  echo "No se encuentra $PLIST" >&2
  exit 1
fi

mkdir -p "$ROOT/build"
rm -rf "$ARCHIVE" "$EXPORT_DIR"

echo "==> Archive ($CONFIGURATION)…"
xcodebuild \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED" \
  -archivePath "$ARCHIVE" \
  archive

echo "==> Export IPA ($MODE)…"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$PLIST"

echo "==> Listo:"
ls -la "$EXPORT_DIR"/*.ipa 2>/dev/null || ls -la "$EXPORT_DIR"
