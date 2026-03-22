import Foundation

@MainActor
final class AppTelemetry: TelemetryLogging {
    static let shared = AppTelemetry()

    #if DEBUG
    private(set) var recentEvents: [(name: String, parameters: [String: String], date: Date)] = []
    private let maxDebugEvents = 120
    #endif

    func logEvent(_ name: String, parameters: [String: String]) {
        #if DEBUG
        recentEvents.append((name, parameters, Date()))
        if recentEvents.count > maxDebugEvents {
            recentEvents.removeFirst(recentEvents.count - maxDebugEvents)
        }
        #endif
    }

    #if DEBUG
    func clearDebugLog() {
        recentEvents.removeAll()
    }
    #endif
}
