import Foundation

// MARK: - Achievement Tracker

/// Tracks achievement progress and handles notifications.
final class AchievementTracker {
    private let registry: AchievementRegistry
    private var unlockedAchievements: Set<String> = []
    private var notifiedAchievements: Set<String> = []
    private var _pendingToasts: [AchievementDefinition] = []

    init(registry: AchievementRegistry = AchievementRegistry()) {
        self.registry = registry
    }

    // MARK: - State

    var achievements: [AchievementDefinition] {
        registry.allAchievements
    }

    var unlocked: Set<String> {
        unlockedAchievements
    }

    var pendingToasts: [AchievementDefinition] {
        _pendingToasts
    }

    // MARK: - Evaluation

    /// Evaluates all achievements and returns newly unlocked ones.
    func evaluate(context: AchievementContext) -> [AchievementDefinition] {
        var newlyUnlocked: [AchievementDefinition] = []

        for achievement in registry.allAchievements {
            guard !unlockedAchievements.contains(achievement.id) else { continue }

            if achievement.condition.evaluate(context: context) {
                unlock(achievement)
                newlyUnlocked.append(achievement)
            }
        }

        return newlyUnlocked
    }

    /// Evaluates a specific achievement.
    func evaluate(achievementId: String, context: AchievementContext) -> Bool {
        guard let achievement = registry.achievement(id: achievementId) else {
            return false
        }

        if unlockedAchievements.contains(achievementId) {
            return true
        }

        if achievement.condition.evaluate(context: context) {
            unlock(achievement)
            return true
        }

        return false
    }

    // MARK: - Unlocking

    /// Unlocks an achievement.
    func unlock(_ achievement: AchievementDefinition) {
        guard !unlockedAchievements.contains(achievement.id) else { return }

        unlockedAchievements.insert(achievement.id)
        _pendingToasts.append(achievement)
        notifiedAchievements.insert(achievement.id)
    }

    /// Marks an achievement notification as shown.
    func markNotified(_ achievementId: String) {
        notifiedAchievements.insert(achievementId)
        _pendingToasts.removeAll { $0.id == achievementId }
    }

    /// Clears all pending notifications.
    func clearPendingNotifications() {
        _pendingToasts.removeAll()
    }

    // MARK: - Persistence

    /// Loads unlocked achievements from persisted state.
    func loadUnlocked(from persistedIds: Set<String>) {
        unlockedAchievements = persistedIds
    }

    /// Returns achievements to persist.
    func achievementsToPersist() -> Set<String> {
        unlockedAchievements
    }

    // MARK: - Progress

    /// Returns progress toward an achievement (0.0 - 1.0) if trackable.
    func progress(achievementId: String, context: AchievementContext) -> Double? {
        guard let achievement = registry.achievement(id: achievementId) else {
            return nil
        }

        if unlockedAchievements.contains(achievementId) {
            return 1.0
        }

        if let condition = achievement.condition as? EnemyDefeatsCondition {
            return min(1.0, Double(context.enemyDefeats) / Double(condition.targetCount))
        }

        if let condition = achievement.condition as? ShelterLevelCondition {
            return min(1.0, Double(context.shelterLevel) / Double(condition.targetLevel))
        }

        if let condition = achievement.condition as? ResourcesGatheredCondition {
            return min(1.0, Double(context.resourcesGathered) / Double(condition.targetCount))
        }

        if let condition = achievement.condition as? LegendaryDropsCondition {
            return min(1.0, Double(context.legendaryDropsCollected) / Double(condition.targetCount))
        }

        return nil
    }
}
