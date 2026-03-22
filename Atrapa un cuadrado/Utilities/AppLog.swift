import Foundation
import os

/// Registro con `Logger` (OSLog) para filtrar en **Consola** / `log stream`.
///
/// **Subsistema**: `Bundle.main.bundleIdentifier` (p. ej. `com.antoniohermoso.atrapauncuadrado`).
/// En Consola: acción Filtrar → *Subsystem* contiene `atrapauncuadrado`, o *Process* `AtrapaUnCuadrado`.
///
/// **Categoría**: columna *Category* (`lifecycle`, `scene`, `persistence`, `telemetry`, `purchase`).
enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.antoniohermoso.atrapauncuadrado"

    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
    static let scene = Logger(subsystem: subsystem, category: "scene")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let telemetry = Logger(subsystem: subsystem, category: "telemetry")
    static let purchase = Logger(subsystem: subsystem, category: "purchase")
}
