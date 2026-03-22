import CoreGraphics
import Foundation

/// Lógica de tick del mundo sin SpriteKit (tests y escena delgada).
enum ArtificialWorldSimulation {
    static func shelterScale(level: Int) -> CGFloat {
        1 + min(5, CGFloat(max(0, level - 1))) * 0.07
    }

    static func shelterRegenMultiplier(level: Int) -> Double {
        1 + 0.12 * Double(max(0, min(level, 6) - 1))
    }

    static func decayOutsideShelter(delta: TimeInterval, hunger: inout Double, energy: inout Double) {
        hunger = max(0, hunger - 0.014 * delta)
        energy = max(0, energy - 0.011 * delta)
    }

    static func regenInsideShelter(delta: TimeInterval, multiplier: Double, hunger: inout Double, energy: inout Double) {
        hunger = min(1, hunger + 0.006 * delta * multiplier)
        energy = min(1, energy + 0.008 * delta * multiplier)
    }

    static func resourceItemCount(inventoryItemIds: [String]) -> Int {
        inventoryItemIds.filter { $0.hasPrefix("res_") }.count
    }

    static func shelterUpgradeCost(currentLevel: Int) -> Int {
        max(2, currentLevel * 2)
    }

    static func effectiveCaptureRadius(base: CGFloat, wideCaptureActive: Bool) -> CGFloat {
        wideCaptureActive ? base * 1.48 : base
    }

    static func speedMultiplier(sprintActive: Bool) -> CGFloat {
        sprintActive ? 1.55 : 1
    }
}
