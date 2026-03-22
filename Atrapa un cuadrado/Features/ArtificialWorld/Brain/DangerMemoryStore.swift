import CoreGraphics
import Foundation

// MARK: - Danger Zone

/// Represents a dangerous area the agent should avoid.
struct DangerZone: Codable, Equatable {
    let id: UUID
    let center: CGPoint
    let radius: CGFloat
    let createdAt: Date
    let sourceEntityId: UUID

    /// Returns true if the given point is within this danger zone.
    func contains(_ point: CGPoint) -> Bool {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distanceSquared = dx * dx + dy * dy
        return distanceSquared <= radius * radius
    }

    /// Returns true if this danger zone has expired (older than maxAge).
    func isExpired(maxAge: TimeInterval = 300) -> Bool {
        Date().timeIntervalSince(createdAt) > maxAge
    }
}

// MARK: - Danger Memory Store

/// Handles persistence and retrieval of danger zones for the agent.
final class DangerMemoryStore {
    private var dangerZones: [DangerZone] = []
    private let maxZones: Int

    init(maxZones: Int = 50) {
        self.maxZones = maxZones
    }

    /// Adds a new danger zone at the given position.
    func addDanger(at position: CGPoint, radius: CGFloat, sourceEntityId: UUID) {
        let zone = DangerZone(
            id: UUID(),
            center: position,
            radius: radius,
            createdAt: Date(),
            sourceEntityId: sourceEntityId
        )
        dangerZones.append(zone)
        pruneExpired()
        pruneIfNeeded()
    }

    /// Returns all active (non-expired) danger zones.
    func activeZones() -> [DangerZone] {
        dangerZones.filter { !$0.isExpired() }
    }

    /// Returns the nearest safe direction away from all active danger zones.
    /// Returns nil if no dangers nearby or if center is already safe.
    func nearestSafeDirection(from position: CGPoint, worldBounds: CGRect) -> CGPoint? {
        let active = activeZones()
        guard !active.isEmpty else { return nil }

        // Find if position is in any danger zone
        for zone in active {
            if zone.contains(position) {
                // Calculate escape vector
                let escapeX = position.x < zone.center.x ? -1.0 : 1.0
                let escapeY = position.y < zone.center.y ? -1.0 : 1.0
                let escape = CGPoint(
                    x: position.x + escapeX * 100,
                    y: position.y + escapeY * 100
                )
                return clamp(escape, worldBounds: worldBounds)
            }
        }

        return nil
    }

    /// Prunes danger zones that are too old.
    func pruneExpired(maxAge: TimeInterval = 300) {
        dangerZones.removeAll { $0.isExpired(maxAge: maxAge) }
    }

    /// Prunes oldest zones if we exceed maxZones.
    private func pruneIfNeeded() {
        if dangerZones.count > maxZones {
            let sorted = dangerZones.sorted { $0.createdAt < $1.createdAt }
            let toRemove = sorted.prefix(dangerZones.count - maxZones)
            dangerZones.removeAll { zone in toRemove.contains { $0.id == zone.id } }
        }
    }

    /// Clears all danger zones.
    func clear() {
        dangerZones.removeAll()
    }

    /// Codable storage helpers for SwiftData persistence.
    func encode() -> Data? {
        try? JSONEncoder().encode(dangerZones)
    }

    func decode(from data: Data) {
        guard let decoded = try? JSONDecoder().decode([DangerZone].self, from: data) else {
            return
        }
        dangerZones = decoded
    }

    private func clamp(_ point: CGPoint, worldBounds: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(point.x, worldBounds.minX + 20), worldBounds.maxX - 20),
            y: min(max(point.y, worldBounds.minY + 20), worldBounds.maxY - 20)
        )
    }
}
