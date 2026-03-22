import CoreGraphics
import Foundation

// MARK: - Zone Registry

/// Registry of all world zones and their unlock progression.
final class ZoneRegistry {
    private var zones: [String: WorldZone] = [:]
    private var unlockOrder: [String] = []

    init() {
        registerDefaultZones()
    }

    // MARK: - Registration

    /// Registers a new zone.
    func register(_ zone: WorldZone) {
        zones[zone.id] = zone
        if zone.isDefault {
            unlockOrder.insert(zone.id, at: 0)
        } else {
            unlockOrder.append(zone.id)
        }
    }

    // MARK: - Access

    /// Returns a zone by ID.
    func zone(id: String) -> WorldZone? {
        zones[id]
    }

    /// Returns all registered zones.
    var allZones: [WorldZone] {
        Array(zones.values)
    }

    /// Returns zones in unlock order.
    var zonesInOrder: [WorldZone] {
        unlockOrder.compactMap { zones[$0] }
    }

    /// Returns the starting zone.
    var startingZone: WorldZone? {
        zones.values.first { $0.isDefault }
    }

    // MARK: - Default Zones

    private func registerDefaultZones() {
        // Starting zone - no requirements
        let startingZone = WorldZone(
            id: "zone_home",
            name: "Home Territory",
            description: "Your starting area with a safe refuge.",
            bounds: CGRect(x: 0, y: 0, width: 400, height: 400),
            unlockRequirements: [],
            entityConfig: ZoneEntityConfiguration(
                hostileSpawnRate: 1.0,
                passiveSpawnRate: 3.0,
                legendarySpawnRate: 0.05,
                maxHostile: 3,
                maxPassive: 8,
                legendaryCooldown: 600
            ),
            isDefault: true
        )
        register(startingZone)

        // Forest zone - requires shelter level 2
        let forestZone = WorldZone(
            id: "zone_forest",
            name: "Dark Forest",
            description: "Dense woods with more hostile creatures.",
            bounds: CGRect(x: 400, y: 0, width: 400, height: 400),
            unlockRequirements: [.shelterLevel(2)],
            entityConfig: ZoneEntityConfiguration(
                hostileSpawnRate: 2.5,
                passiveSpawnRate: 4.0,
                legendarySpawnRate: 0.08,
                maxHostile: 6,
                maxPassive: 10,
                legendaryCooldown: 480
            ),
            isDefault: false
        )
        register(forestZone)

        // Mountain zone - requires shelter level 3 and 10 enemy defeats
        let mountainZone = WorldZone(
            id: "zone_mountain",
            name: "Crystal Mountains",
            description: "High peaks with rare resources.",
            bounds: CGRect(x: 0, y: 400, width: 400, height: 400),
            unlockRequirements: [.shelterLevel(3), .enemyDefeats(10)],
            entityConfig: ZoneEntityConfiguration(
                hostileSpawnRate: 3.0,
                passiveSpawnRate: 2.0,
                legendarySpawnRate: 0.1,
                maxHostile: 8,
                maxPassive: 5,
                legendaryCooldown: 360
            ),
            isDefault: false
        )
        register(mountainZone)

        // Ancient ruins - requires shelter level 5
        let ruinsZone = WorldZone(
            id: "zone_ruins",
            name: "Ancient Ruins",
            description: "Mysterious ruins with legendary treasures.",
            bounds: CGRect(x: 400, y: 400, width: 400, height: 400),
            unlockRequirements: [.shelterLevel(5)],
            entityConfig: ZoneEntityConfiguration(
                hostileSpawnRate: 4.0,
                passiveSpawnRate: 1.0,
                legendarySpawnRate: 0.15,
                maxHostile: 10,
                maxPassive: 3,
                legendaryCooldown: 300
            ),
            isDefault: false
        )
        register(ruinsZone)
    }
}

// MARK: - Unlock Helpers

extension ZoneRegistry {
    /// Returns unlock requirements as human-readable strings.
    func requirementsDescription(for zone: WorldZone) -> [String] {
        zone.unlockRequirements.map { req in
            switch req {
            case .shelterLevel(let level):
                return "Reach shelter level \(level)"
            case .achievement(let id):
                return "Earn achievement: \(id)"
            case .itemCount(let itemId, let count):
                return "Collect \(count) \(itemId)"
            case .enemyDefeats(let count):
                return "Defeat \(count) enemies"
            case .allOf(let reqs):
                return reqs.map { "• \(requirementsDescription(for: zone, req: $0))" }.joined(separator: "\n")
            case .anyOf(let reqs):
                return "Complete one: " + reqs.map { "• \(requirementsDescription(for: zone, req: $0))" }.joined(separator: "\n")
            }
        }
    }

    private func requirementsDescription(for zone: WorldZone, req: ZoneUnlockRequirement) -> String {
        switch req {
        case .shelterLevel(let level):
            return "Shelter level \(level)"
        case .achievement(let id):
            return "Achievement: \(id)"
        case .itemCount(let itemId, let count):
            return "\(count) \(itemId)"
        case .enemyDefeats(let count):
            return "\(count) defeats"
        default:
            return ""
        }
    }
}
