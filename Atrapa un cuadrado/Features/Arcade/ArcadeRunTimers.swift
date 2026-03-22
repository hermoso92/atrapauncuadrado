import CoreGraphics
import Foundation

/// Estado de temporizadores de dificultad/spawn del arcade, desacoplado de SpriteKit.
struct ArcadeRunTimersState {
    var spawnTimer: TimeInterval = 0
    var difficultyTimer: TimeInterval = 0
    var spawnInterval: TimeInterval
    var squareSpeedMultiplier: CGFloat = 1
    var round: Int

    init(spawnInterval: TimeInterval, round: Int) {
        self.spawnInterval = spawnInterval
        self.round = round
    }

    mutating func advance(
        deltaTime: TimeInterval,
        profile: GameModeProfile,
        squareCount: Int
    ) -> (shouldSpawn: Bool, shouldStepDifficulty: Bool) {
        spawnTimer += deltaTime
        difficultyTimer += deltaTime
        var shouldSpawn = false
        if spawnTimer >= spawnInterval, squareCount < profile.maxSquares {
            spawnTimer = 0
            shouldSpawn = true
        }
        var shouldStepDifficulty = false
        if difficultyTimer >= profile.difficultyStepInterval {
            difficultyTimer = 0
            shouldStepDifficulty = true
        }
        return (shouldSpawn, shouldStepDifficulty)
    }

    mutating func applyDifficultyStep(profile: GameModeProfile) {
        round += 1
        squareSpeedMultiplier += profile.squareSpeedRamp
        spawnInterval = max(profile.spawnIntervalFloor, spawnInterval - profile.spawnIntervalStep)
    }
}
