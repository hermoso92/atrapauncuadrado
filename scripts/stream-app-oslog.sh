#!/usr/bin/env bash
# Trazas OSLog de la app (subsistema = bundle id). Ejecutar en tu Mac con Simulador arrancado.
set -euo pipefail

SUBSYS="com.antoniohermoso.atrapauncuadrado"
MODE="${1:-sim}"

if [[ "$MODE" == "mac" ]]; then
  echo "Stream en Mac (útil si corres desde Xcode con Run): subsystem=$SUBSYS"
  echo "Activa en Consola: Incluir mensajes informativos / Debug si hace falta."
  exec log stream --predicate "subsystem == \"$SUBSYS\"" --style compact --level debug
fi

if [[ "$MODE" == "sim" ]]; then
  if ! xcrun simctl list devices booted 2>/dev/null | grep -q Booted; then
    echo "No hay simulador arrancado. Abre Simulator o: xcrun simctl boot <UDID>" >&2
    exit 1
  fi
  echo "Stream dentro del Simulador iOS booted: subsystem=$SUBSYS"
  echo "Abre la app en el simulador para ver líneas (lifecycle, scene, telemetry, …)."
  exec xcrun simctl spawn booted log stream --predicate "subsystem == \"$SUBSYS\"" --style compact --level debug
fi

echo "Uso: $0 [sim|mac]" >&2
exit 1
