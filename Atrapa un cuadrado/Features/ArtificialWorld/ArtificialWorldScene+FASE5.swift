import SpriteKit
import Foundation

// MARK: - FASE5 Integration Extensions

extension ArtificialWorldScene {
    // MARK: - Zone System Integration

    /// Checks if player can enter a zone based on current progress.
    func canEnterZone(_ zone: WorldZone, enemyDefeats: Int = 0) -> Bool {
        let inventoryCounts = Dictionary(grouping: snapshot.inventoryItemIds, by: { $0 })
            .mapValues { $0.count }
        
        return zone.isUnlocked(
            shelterLevel: snapshot.shelterLevel,
            unlockedAchievements: [],
            inventoryItemCounts: inventoryCounts,
            enemyDefeats: enemyDefeats
        )
    }

    /// Tries to enter a zone, returns true if successful.
    func tryEnterZone(_ zone: WorldZone) -> Bool {
        guard canEnterZone(zone) else {
            showBriefStatus("Zona bloqueada: requisitos no cumplidos.", color: Palette.warning)
            return false
        }
        
        telemetry.logEvent("zone_entered", parameters: ["zoneId": zone.id])
        return true
    }

    // MARK: - Entity Spawner Integration

    /// Spawns entities for the current zone.
    func spawnEntitiesForCurrentZone(deltaTime: TimeInterval) {
        let spawner = EntitySpawner(worldBounds: worldBounds)
        let zone = WorldZone(
            id: "zone_home",
            name: "Home",
            description: "Home zone",
            bounds: worldBounds,
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
        let spawned = spawner.spawnForZone(zone, delta: deltaTime)
        
        for entity in spawned {
            let body = WorldSquareBody(
                id: entity.id,
                position: entity.position,
                velocity: entity.velocity,
                kind: entityKindToSquareKind(entity.kind)
            )
            squares.append(body)
            
            let node = SKShapeNode(rectOf: CGSize(width: squareSize, height: squareSize), cornerRadius: 4)
            node.fillColor = fillColorForEntity(entity)
            node.strokeColor = .white
            node.lineWidth = 1.2
            node.position = entity.position
            node.zPosition = 4
            worldNode.addChild(node)
            squareNodes[entity.id] = node
        }
    }

    private func fillColorForEntity(_ entity: Entity) -> UIColor {
        switch entity.kind {
        case .hostile:
            return Palette.danger
        case .passive(let yield, _):
            return yield > 2 ? Palette.warning : Palette.success
        case .legendary:
            return UIColor(red: 0.60, green: 0.53, blue: 1.00, alpha: 1)
        }
    }

    private func entityKindToSquareKind(_ kind: EntityKind) -> ArtificialWorldSquareKind {
        switch kind {
        case .hostile:
            return .hostile
        case .passive(let yield, _):
            return yield > 2 ? .resource : .nutritious
        case .legendary:
            return .rare
        }
    }

    // MARK: - Refuge Defense Integration

    /// Updates refuge defense system.
    func updateRefugeDefense(deltaTime: TimeInterval) -> Double {
        let defense = RefugeDefenseSystem()
        return defense.tick(
            delta: deltaTime,
            playerPosition: playerNode.position,
            shelterCenter: shelterCenter,
            shelterRadius: shelterRadius,
            worldBounds: worldBounds
        )
    }

    /// Renders patrol entities in the scene.
    func renderPatrolEntities() {
        worldNode.childNode(withName: "patrolLayer")?.removeFromParent()
    }

    // MARK: - Achievement Integration

    /// Evaluates achievements and shows notifications.
    func evaluateAchievements() {
        let tracker = AchievementTracker()
        let context = AchievementContext(
            shelterLevel: snapshot.shelterLevel,
            totalPlayTime: 0,
            enemyDefeats: 0,
            resourcesGathered: snapshot.inventoryItemIds.count,
            distanceTraveled: 0,
            sessionsCompleted: 0,
            zonesExplored: [],
            legendaryDropsCollected: 0,
            maxEnergyReached: snapshot.energy,
            maxHungerReached: snapshot.hunger
        )

        let newlyUnlocked = tracker.evaluate(context: context)
        
        for achievement in newlyUnlocked {
            showAchievementToast(achievement)
            telemetry.logEvent("achievement_unlocked", parameters: ["id": achievement.id, "name": achievement.name])
        }
    }

    /// Shows achievement unlock toast.
    func showAchievementToast(_ achievement: AchievementDefinition) {
        let toast = SKLabelNode(fontNamed: GameConfig.coinFont)
        toast.text = "🏆 \(achievement.name)"
        toast.fontSize = 18
        toast.fontColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        toast.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
        toast.zPosition = 100
        toast.alpha = 0
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        toast.run(.sequence([fadeIn, wait, fadeOut, remove]))
        
        addChild(toast)
    }

    // MARK: - Danger Memory Integration

    /// Records a danger zone where the player took damage.
    func recordDangerZone(at position: CGPoint, sourceEntityId: UUID) {
        let memory = DangerMemoryStore()
        memory.addDanger(at: position, radius: 60, sourceEntityId: sourceEntityId)
        telemetry.logEvent("danger_zone_recorded", parameters: [
            "x": "\(Int(position.x))",
            "y": "\(Int(position.y))"
        ])
    }

    /// Gets safe direction away from danger zones.
    func safeDirectionFromDangers(at position: CGPoint) -> CGPoint? {
        let memory = DangerMemoryStore()
        return memory.nearestSafeDirection(from: position, worldBounds: worldBounds)
    }
}
