import Foundation

/// Eventos de producto; implementación real puede enviar a analytics o ser no-op.
@MainActor
protocol TelemetryLogging: AnyObject {
    func logEvent(_ name: String, parameters: [String: String])
}

extension TelemetryLogging {
    func logEvent(_ name: String) {
        logEvent(name, parameters: [:])
    }
}

@MainActor
final class NoOpTelemetryLogging: TelemetryLogging {
    static let shared = NoOpTelemetryLogging()
    func logEvent(_ name: String, parameters: [String: String]) {}
}
