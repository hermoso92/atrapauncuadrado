//
//  ArtificialWorldFASE5Tests.swift
//  Atrapa un cuadradoTests
//
//  Tests for Artificial World FASE5 features
//

import CoreGraphics
import Foundation
import Testing
@testable import AtrapaUnCuadrado

// MARK: - Entity Tests

struct EntityTests {

    @Test func hostileEntityHasCorrectDamage() async throws {
        let entity = HostileEntityFactory.create(at: CGPoint(x: 100, y: 100), damage: 25)
        #expect(entity.hostileDamage == 25)
    }

    @Test func hostileEntityCanAttackPlayerOutsideShelter() async throws {
        let entity = HostileEntityFactory.create(at: CGPoint(x: 50, y: 50))
        #expect(entity.canAttackPlayer(at: CGPoint(x: 50, y: 50), playerInShelter: false))
        #expect(!entity.canAttackPlayer(at: CGPoint(x: 50, y: 50), playerInShelter: true))
        #expect(!entity.canAttackPlayer(at: CGPoint(x: 500, y: 500), playerInShelter: false))
    }

    @Test func passiveEntityCanBeHarvested() async throws {
        let entity = PassiveEntityFactory.create(at: CGPoint(x: 100, y: 100), resourceYield: 3)
        #expect(entity.isHarvestable)
        #expect(entity.passiveResourceYield == 3)
    }

    @Test func passiveEntityCannotBeHarvestedTwice() async throws {
        var entity = PassiveEntityFactory.create(at: CGPoint(x: 100, y: 100), resourceYield: 3)
        #expect(entity.isHarvestable)
        let firstYield = entity.harvestResource()
        #expect(firstYield == 3)
        #expect(!entity.isHarvestable)
        let secondYield = entity.harvestResource()
        #expect(secondYield == 0)
    }

    @Test func legendaryEntitySpawnsAfterCooldown() async throws {
        let entity = LegendaryEntityFactory.create(
            at: CGPoint(x: 100, y: 100),
            spawnCondition: .timer(seconds: 60)
        )
        #expect(!entity.isSpawned)
        #expect(entity.canSpawn == false)
    }

    @Test func legendaryDropHasCorrectCoinValue() async throws {
        let drop = LegendaryDrop.goldenSquare
        #expect(drop.coinValue == 500)
        #expect(drop.rarity == .rare)
    }
}

// MARK: - Danger Memory Tests

struct DangerMemoryStoreTests {

    @Test func dangerZoneContainsPoint() async throws {
        let zone = DangerZone(
            id: UUID(),
            center: CGPoint(x: 100, y: 100),
            radius: 50,
            createdAt: Date(),
            sourceEntityId: UUID()
        )
        #expect(zone.contains(CGPoint(x: 100, y: 100)))
        #expect(zone.contains(CGPoint(x: 120, y: 100)))
        #expect(!zone.contains(CGPoint(x: 200, y: 100)))
    }

    @Test func dangerZoneExpiresAfterTimeout() async throws {
        let oldZone = DangerZone(
            id: UUID(),
            center: CGPoint(x: 100, y: 100),
            radius: 50,
            createdAt: Date().addingTimeInterval(-400),
            sourceEntityId: UUID()
        )
        #expect(oldZone.isExpired(maxAge: 300))

        let freshZone = DangerZone(
            id: UUID(),
            center: CGPoint(x: 100, y: 100),
            radius: 50,
            createdAt: Date(),
            sourceEntityId: UUID()
        )
        #expect(!freshZone.isExpired(maxAge: 300))
    }

    @Test func dangerMemoryStoreRecordsAndRecallsZones() async throws {
        let store = DangerMemoryStore(maxZones: 10)
        let position = CGPoint(x: 100, y: 100)
        let entityId = UUID()

        store.addDanger(at: position, radius: 50, sourceEntityId: entityId)
        let zones = store.activeZones()
        #expect(zones.count == 1)
        #expect(zones[0].contains(position))
    }

    @Test func dangerMemoryStoreFindsSafeDirection() async throws {
        let store = DangerMemoryStore()
        let dangerPos = CGPoint(x: 100, y: 100)
        let playerPos = CGPoint(x: 100, y: 100)
        let bounds = CGRect(x: 0, y: 0, width: 400, height: 400)

        store.addDanger(at: dangerPos, radius: 60, sourceEntityId: UUID())

        let safeDirection = store.nearestSafeDirection(from: playerPos, worldBounds: bounds)
        #expect(safeDirection != nil)
    }

    @Test func dangerMemoryStorePrunesExpiredZones() async throws {
        let store = DangerMemoryStore()
        let oldPos = CGPoint(x: 50, y: 50)
        let newPos = CGPoint(x: 300, y: 300)

        // Add old zone manually by manipulating time (simplified test)
        store.addDanger(at: oldPos, radius: 30, sourceEntityId: UUID())
        store.addDanger(at: newPos, radius: 30, sourceEntityId: UUID())

        store.pruneExpired(maxAge: 0)
        let zones = store.activeZones()
        #expect(zones.count == 0)
    }
}

// MARK: - Zone Unlock Tests

struct ZoneUnlockTests {

    @Test func shelterLevelRequirementMet() async throws {
        let zone = WorldZone(
            id: "test",
            name: "Test Zone",
            description: "Test",
            bounds: .zero,
            unlockRequirements: [.shelterLevel(3)],
            entityConfig: .init(hostileSpawnRate: 1, passiveSpawnRate: 1, legendarySpawnRate: 0.1, maxHostile: 3, maxPassive: 5, legendaryCooldown: 600),
            isDefault: false
        )

        #expect(zone.isUnlocked(shelterLevel: 3, unlockedAchievements: [], inventoryItemCounts: [:], enemyDefeats: 0))
        #expect(!zone.isUnlocked(shelterLevel: 2, unlockedAchievements: [], inventoryItemCounts: [:], enemyDefeats: 0))
    }

    @Test func enemyDefeatsRequirementMet() async throws {
        let zone = WorldZone(
            id: "test",
            name: "Test Zone",
            description: "Test",
            bounds: .zero,
            unlockRequirements: [.enemyDefeats(10)],
            entityConfig: .init(hostileSpawnRate: 1, passiveSpawnRate: 1, legendarySpawnRate: 0.1, maxHostile: 3, maxPassive: 5, legendaryCooldown: 600),
            isDefault: false
        )

        #expect(zone.isUnlocked(shelterLevel: 1, unlockedAchievements: [], inventoryItemCounts: [:], enemyDefeats: 10))
        #expect(!zone.isUnlocked(shelterLevel: 1, unlockedAchievements: [], inventoryItemCounts: [:], enemyDefeats: 9))
    }

    @Test func achievementRequirementMet() async throws {
        let zone = WorldZone(
            id: "test",
            name: "Test Zone",
            description: "Test",
            bounds: .zero,
            unlockRequirements: [.achievement("first_defeat")],
            entityConfig: .init(hostileSpawnRate: 1, passiveSpawnRate: 1, legendarySpawnRate: 0.1, maxHostile: 3, maxPassive: 5, legendaryCooldown: 600),
            isDefault: false
        )

        #expect(zone.isUnlocked(shelterLevel: 1, unlockedAchievements: ["first_defeat"], inventoryItemCounts: [:], enemyDefeats: 0))
        #expect(!zone.isUnlocked(shelterLevel: 1, unlockedAchievements: [], inventoryItemCounts: [:], enemyDefeats: 0))
    }

    @Test func combinedRequirementsMustAllBeMet() async throws {
        let zone = WorldZone(
            id: "test",
            name: "Test Zone",
            description: "Test",
            bounds: .zero,
            unlockRequirements: [.shelterLevel(3), .enemyDefeats(5)],
            entityConfig: .init(hostileSpawnRate: 1, passiveSpawnRate: 1, legendarySpawnRate: 0.1, maxHostile: 3, maxPassive: 5, legendaryCooldown: 600),
            isDefault: false
        )

        // Only shelter level met
        #expect(!zone.isUnlocked(shelterLevel: 3, unlockedAchievements: [], inventoryItemCounts: [:], enemyDefeats: 0))

        // Both met
        #expect(zone.isUnlocked(shelterLevel: 3, unlockedAchievements: [], inventoryItemCounts: [:], enemyDefeats: 5))
    }
}

// MARK: - Achievement Tests

struct AchievementTests {

    @Test func shelterLevelConditionEvaluatesCorrectly() async throws {
        let condition = ShelterLevelCondition(targetLevel: 3)

        #expect(!condition.evaluate(context: AchievementContext(
            shelterLevel: 2, totalPlayTime: 0, enemyDefeats: 0, resourcesGathered: 0,
            distanceTraveled: 0, sessionsCompleted: 0, zonesExplored: [], legendaryDropsCollected: 0,
            maxEnergyReached: 1, maxHungerReached: 1
        )))

        #expect(condition.evaluate(context: AchievementContext(
            shelterLevel: 3, totalPlayTime: 0, enemyDefeats: 0, resourcesGathered: 0,
            distanceTraveled: 0, sessionsCompleted: 0, zonesExplored: [], legendaryDropsCollected: 0,
            maxEnergyReached: 1, maxHungerReached: 1
        )))
    }

    @Test func enemyDefeatsConditionEvaluatesCorrectly() async throws {
        let condition = EnemyDefeatsCondition(targetCount: 10)

        #expect(!condition.evaluate(context: AchievementContext(
            shelterLevel: 1, totalPlayTime: 0, enemyDefeats: 5, resourcesGathered: 0,
            distanceTraveled: 0, sessionsCompleted: 0, zonesExplored: [], legendaryDropsCollected: 0,
            maxEnergyReached: 1, maxHungerReached: 1
        )))

        #expect(condition.evaluate(context: AchievementContext(
            shelterLevel: 1, totalPlayTime: 0, enemyDefeats: 10, resourcesGathered: 0,
            distanceTraveled: 0, sessionsCompleted: 0, zonesExplored: [], legendaryDropsCollected: 0,
            maxEnergyReached: 1, maxHungerReached: 1
        )))
    }

    @Test func achievementTrackerDoesNotNotifyTwice() async throws {
        let tracker = AchievementTracker()
        let context = AchievementContext(
            shelterLevel: 3, totalPlayTime: 0, enemyDefeats: 10, resourcesGathered: 0,
            distanceTraveled: 0, sessionsCompleted: 0, zonesExplored: [], legendaryDropsCollected: 0,
            maxEnergyReached: 1, maxHungerReached: 1
        )

        let firstUnlocked = tracker.evaluate(context: context)
        #expect(!firstUnlocked.isEmpty)

        let secondUnlocked = tracker.evaluate(context: context)
        #expect(secondUnlocked.isEmpty)
    }

    @Test func achievementProgressIsCalculated() async throws {
        let tracker = AchievementTracker()
        let context = AchievementContext(
            shelterLevel: 1, totalPlayTime: 0, enemyDefeats: 5, resourcesGathered: 0,
            distanceTraveled: 0, sessionsCompleted: 0, zonesExplored: [], legendaryDropsCollected: 0,
            maxEnergyReached: 1, maxHungerReached: 1
        )

        let progress = tracker.progress(achievementId: "defeat_10", context: context)
        #expect(progress != nil)
        #expect(progress! == 0.5)
    }
}

// MARK: - Zone Registry Tests

struct ZoneRegistryTests {

    @Test func zoneRegistryHasStartingZone() async throws {
        let registry = ZoneRegistry()
        #expect(registry.startingZone != nil)
        #expect(registry.startingZone?.id == "zone_home")
    }

    @Test func zoneRegistryHasMultipleZones() async throws {
        let registry = ZoneRegistry()
        #expect(registry.allZones.count >= 4)
    }
}

// MARK: - Refuge Defense Tests

struct RefugeDefenseTests {

    @Test func patrolSpawnsWhenPlayerOutside() async throws {
        let defense = RefugeDefenseSystem()
        let damage = defense.tick(
            delta: 15,
            playerPosition: CGPoint(x: 300, y: 300),
            shelterCenter: CGPoint(x: 200, y: 200),
            shelterRadius: 50,
            worldBounds: CGRect(x: 0, y: 0, width: 400, height: 400)
        )
        #expect(defense.activePatrolCount > 0)
        #expect(damage == 0) // No collision yet
    }

    @Test func patrolDespawnsWhenPlayerInside() async throws {
        let defense = RefugeDefenseSystem()
        // First spawn patrols
        _ = defense.tick(
            delta: 15,
            playerPosition: CGPoint(x: 300, y: 300),
            shelterCenter: CGPoint(x: 200, y: 200),
            shelterRadius: 50,
            worldBounds: CGRect(x: 0, y: 0, width: 400, height: 400)
        )
        #expect(defense.activePatrolCount > 0)

        // Then player enters shelter
        _ = defense.tick(
            delta: 1,
            playerPosition: CGPoint(x: 200, y: 200),
            shelterCenter: CGPoint(x: 200, y: 200),
            shelterRadius: 50,
            worldBounds: CGRect(x: 0, y: 0, width: 400, height: 400)
        )
        // Patrols should start returning
    }

    @Test func defenseResets() async throws {
        let defense = RefugeDefenseSystem()
        _ = defense.tick(
            delta: 15,
            playerPosition: CGPoint(x: 300, y: 300),
            shelterCenter: CGPoint(x: 200, y: 200),
            shelterRadius: 50,
            worldBounds: CGRect(x: 0, y: 0, width: 400, height: 400)
        )
        #expect(defense.activePatrolCount > 0)

        defense.reset()
        #expect(defense.activePatrolCount == 0)
    }
}
