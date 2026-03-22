import CoreGraphics
import Foundation

// MARK: - Achievement Condition Protocol

/// Protocol for achievement conditions.
protocol AchievementCondition {
    var achievementId: String { get }
    var displayName: String { get }
    var description: String { get }

    /// Evaluates whether this achievement is unlocked.
    func evaluate(context: AchievementContext) -> Bool
}

/// Context provided for achievement evaluation.
struct AchievementContext {
    let shelterLevel: Int
    let totalPlayTime: TimeInterval
    let enemyDefeats: Int
    let resourcesGathered: Int
    let distanceTraveled: CGFloat
    let sessionsCompleted: Int
    let zonesExplored: Set<String>
    let legendaryDropsCollected: Int
    let maxEnergyReached: Double
    let maxHungerReached: Double
}

// MARK: - Achievement Registry

/// Registry of all achievements and their conditions.
final class AchievementRegistry {
    private var achievements: [String: AchievementDefinition] = [:]

    init() {
        registerDefaultAchievements()
    }

    /// Registers an achievement.
    func register(_ achievement: AchievementDefinition) {
        achievements[achievement.id] = achievement
    }

    /// Returns an achievement by ID.
    func achievement(id: String) -> AchievementDefinition? {
        achievements[id]
    }

    /// Returns all achievements.
    var allAchievements: [AchievementDefinition] {
        Array(achievements.values)
    }

    // MARK: - Default Achievements

    private func registerDefaultAchievements() {
        // Shelter achievements
        register(AchievementDefinition(
            id: "shelter_level_2",
            name: "Home Improvement",
            description: "Upgrade your shelter to level 2",
            category: .progression,
            condition: ShelterLevelCondition(targetLevel: 2)
        ))

        register(AchievementDefinition(
            id: "shelter_level_5",
            name: "Fortress",
            description: "Upgrade your shelter to level 5",
            category: .progression,
            condition: ShelterLevelCondition(targetLevel: 5)
        ))

        // Combat achievements
        register(AchievementDefinition(
            id: "first_defeat",
            name: "Hunter",
            description: "Defeat your first enemy",
            category: .combat,
            condition: EnemyDefeatsCondition(targetCount: 1)
        ))

        register(AchievementDefinition(
            id: "defeat_10",
            name: "Veteran",
            description: "Defeat 10 enemies",
            category: .combat,
            condition: EnemyDefeatsCondition(targetCount: 10)
        ))

        register(AchievementDefinition(
            id: "defeat_50",
            name: "Champion",
            description: "Defeat 50 enemies",
            category: .combat,
            condition: EnemyDefeatsCondition(targetCount: 50)
        ))

        // Exploration achievements
        register(AchievementDefinition(
            id: "explore_forest",
            name: "Forest Walker",
            description: "Enter the Dark Forest zone",
            category: .exploration,
            condition: ZoneExploredCondition(zoneId: "zone_forest")
        ))

        register(AchievementDefinition(
            id: "explore_mountain",
            name: "Mountain Climber",
            description: "Enter the Crystal Mountains zone",
            category: .exploration,
            condition: ZoneExploredCondition(zoneId: "zone_mountain")
        ))

        // Resource achievements
        register(AchievementDefinition(
            id: "gather_100",
            name: "Gatherer",
            description: "Gather 100 resources",
            category: .resources,
            condition: ResourcesGatheredCondition(targetCount: 100)
        ))

        // Legendary achievements
        register(AchievementDefinition(
            id: "legendary_first",
            name: "Lucky Find",
            description: "Collect your first legendary drop",
            category: .special,
            condition: LegendaryDropsCondition(targetCount: 1)
        ))
    }
}

// MARK: - Achievement Definition

struct AchievementDefinition: Identifiable {
    let id: String
    let name: String
    let description: String
    let category: AchievementCategory
    let condition: any AchievementCondition

    var achievementId: String { id }
}

enum AchievementCategory: String, CaseIterable {
    case progression = "Progression"
    case combat = "Combat"
    case exploration = "Exploration"
    case resources = "Resources"
    case special = "Special"
}

// MARK: - Concrete Conditions

struct ShelterLevelCondition: AchievementCondition {
    let achievementId: String
    let targetLevel: Int

    var displayName: String { "Reach level \(targetLevel)" }
    var description: String { "Upgrade shelter to level \(targetLevel)" }

    init(targetLevel: Int) {
        self.achievementId = "shelter_level_\(targetLevel)"
        self.targetLevel = targetLevel
    }

    func evaluate(context: AchievementContext) -> Bool {
        context.shelterLevel >= targetLevel
    }
}

struct EnemyDefeatsCondition: AchievementCondition {
    let achievementId: String
    let targetCount: Int

    var displayName: String { "Defeat \(targetCount) enemies" }
    var description: String { "Defeat \(targetCount) enemies" }

    init(targetCount: Int) {
        self.achievementId = "defeat_\(targetCount)"
        self.targetCount = targetCount
    }

    func evaluate(context: AchievementContext) -> Bool {
        context.enemyDefeats >= targetCount
    }
}

struct ZoneExploredCondition: AchievementCondition {
    let achievementId: String
    let zoneId: String

    var displayName: String { "Explore zone" }
    var description: String { "Enter \(zoneId)" }

    init(zoneId: String) {
        self.achievementId = "explore_\(zoneId.replacingOccurrences(of: "zone_", with: ""))"
        self.zoneId = zoneId
    }

    func evaluate(context: AchievementContext) -> Bool {
        context.zonesExplored.contains(zoneId)
    }
}

struct ResourcesGatheredCondition: AchievementCondition {
    let achievementId: String
    let targetCount: Int

    var displayName: String { "Gather \(targetCount) resources" }
    var description: String { "Collect \(targetCount) resources" }

    init(targetCount: Int) {
        self.achievementId = "gather_\(targetCount)"
        self.targetCount = targetCount
    }

    func evaluate(context: AchievementContext) -> Bool {
        context.resourcesGathered >= targetCount
    }
}

struct LegendaryDropsCondition: AchievementCondition {
    let achievementId: String
    let targetCount: Int

    var displayName: String { "Collect \(targetCount) legendary drops" }
    var description: String { "Find \(targetCount) legendary items" }

    init(targetCount: Int) {
        self.achievementId = "legendary_\(targetCount)"
        self.targetCount = targetCount
    }

    func evaluate(context: AchievementContext) -> Bool {
        context.legendaryDropsCollected >= targetCount
    }
}
