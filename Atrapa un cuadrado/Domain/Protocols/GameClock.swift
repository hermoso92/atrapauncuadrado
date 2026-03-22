import Foundation

/// Abstracción de tiempo para simulación y tests (sin acoplar a SpriteKit o CACurrentMediaTime).
protocol GameClock: Sendable {
    func now() -> TimeInterval
}

struct SystemGameClock: GameClock {
    func now() -> TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }
}
