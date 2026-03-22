import Foundation
import os

@MainActor
final class AppTelemetry: TelemetryLogging {
    static let shared = AppTelemetry()

    #if DEBUG
    private(set) var recentEvents: [(name: String, parameters: [String: String], date: Date)] = []
    private let maxDebugEvents = 120
    #endif

    func logEvent(_ name: String, parameters: [String: String]) {
        let paramsText: String
        if parameters.isEmpty {
            paramsText = ""
        } else {
            paramsText = parameters
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
        }
        AppLog.telemetry.info("event=\(name, privacy: .public) \(paramsText, privacy: .public)")

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
