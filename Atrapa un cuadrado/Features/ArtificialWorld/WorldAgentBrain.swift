import CoreGraphics
import Foundation

enum WorldAgentBrainState: String, Equatable {
    case explore
    case harvest
    case retreat
    case flee
}

struct WorldSquareBody {
    let id: UUID
    var position: CGPoint
    var velocity: CGVector
    let kind: ArtificialWorldSquareKind
}

/// Agente por máquina de estados + utilidad simple (sin ML).
struct WorldAgentBrain {
    private(set) var state: WorldAgentBrainState = .explore
    private var lastChoiceAt: TimeInterval = 0
    private let minInterval: TimeInterval = 0.26
    private var wanderTarget: CGPoint = .zero

    mutating func reset() {
        state = .explore
        lastChoiceAt = 0
        wanderTarget = .zero
    }

    /// Devuelve el punto hacia el que debe moverse el jugador en modo automático, o nil para mantener el anterior.
    mutating func nextSteerTarget(
        now: TimeInterval,
        player: CGPoint,
        hunger: Double,
        energy: Double,
        shelterCenter: CGPoint,
        shelterRadius: CGFloat,
        squares: [WorldSquareBody],
        worldBounds: CGRect,
        companionStats: CompanionStats?
    ) -> CGPoint? {
        guard now - lastChoiceAt >= minInterval else {
            return nil
        }
        lastChoiceAt = now

        let distToShelter = hypot(player.x - shelterCenter.x, player.y - shelterCenter.y)
        let inShelter = distToShelter < shelterRadius + 8

        let fleeDistance: CGFloat = companionStats?.traits.contains(.protector) == true ? 125 : 95
        
        if let hostile = nearestSquare(of: .hostile, to: player, in: squares) {
            let d = hypot(hostile.position.x - player.x, hostile.position.y - player.y)
            if d < fleeDistance {
                state = .flee
                let away = CGVector(
                    dx: player.x - hostile.position.x,
                    dy: player.y - hostile.position.y
                )
                let n = away.normalized
                let fleePoint = CGPoint(x: player.x + n.dx * 120, y: player.y + n.dy * 120)
                return clamp(fleePoint, worldBounds: worldBounds, inset: 40)
            }
        }

        if !inShelter, (hunger < 0.32 || energy < 0.28) {
            state = .retreat
            return shelterCenter
        }

        if let best = bestHarvestTarget(player: player, hunger: hunger, energy: energy, squares: squares, companionStats: companionStats) {
            state = .harvest
            return best.position
        }

        state = .explore
        if wanderTarget == .zero || hypot(wanderTarget.x - player.x, wanderTarget.y - player.y) < 24 {
            wanderTarget = randomPoint(in: worldBounds, inset: 50)
        }
        return wanderTarget
    }

    func utilitySummaryLine(
        player: CGPoint,
        hunger: Double,
        energy: Double,
        squares: [WorldSquareBody],
        companionStats: CompanionStats?
    ) -> String {
        let hU = hunger
        let eU = energy
        let foodScore = squares.filter { $0.kind != .hostile }.map { s in
            let d = max(1, hypot(s.position.x - player.x, s.position.y - player.y))
            return (1 / d) * (s.kind.hungerRestore + s.kind.energyRestore) * 40
        }.max() ?? 0
        let danger = squares.filter { $0.kind == .hostile }.map { s in
            let d = max(1, hypot(s.position.x - player.x, s.position.y - player.y))
            return d < 100 ? (100 - d) : 0
        }.max() ?? 0
        
        let traitStr = companionStats?.traits.first?.rawValue ?? "balanced"
        
        return String(format: "U h:%.2f e:%.2f food:%.1f danger:%.1f | T: %@", hU, eU, foodScore, danger, traitStr)
    }

    private func nearestSquare(of kind: ArtificialWorldSquareKind, to p: CGPoint, in squares: [WorldSquareBody]) -> WorldSquareBody? {
        squares.filter { $0.kind == kind }.min(by: {
            hypot($0.position.x - p.x, $0.position.y - p.y) < hypot($1.position.x - p.x, $1.position.y - p.y)
        })
    }

    private func bestHarvestTarget(player: CGPoint, hunger: Double, energy: Double, squares: [WorldSquareBody], companionStats: CompanionStats?) -> WorldSquareBody? {
        let candidates = squares.filter { $0.kind != .hostile }
        guard !candidates.isEmpty else {
            return nil
        }
        return candidates.max(by: { scoreSquare($0, player: player, hunger: hunger, energy: energy, allSquares: squares, companionStats: companionStats) < scoreSquare($1, player: player, hunger: hunger, energy: energy, allSquares: squares, companionStats: companionStats) })
    }

    private func scoreSquare(_ s: WorldSquareBody, player: CGPoint, hunger: Double, energy: Double, allSquares: [WorldSquareBody], companionStats: CompanionStats?) -> Double {
        let d = hypot(s.position.x - player.x, s.position.y - player.y)
        let distFactor = 1 / max(24, d)

        let needFood = max(0, 0.55 - hunger)
        let needEnergy = max(0, 0.55 - energy)

        var score = distFactor * 100
        score += needFood * s.kind.hungerRestore * 80
        score += needEnergy * s.kind.energyRestore * 60
        score += (s.kind == .rare ? 12 : 0)

        // Modificadores de personalidad
        if let traits = companionStats?.traits {
            if traits.contains(.aggressive) {
                if let hostile = nearestSquare(of: .hostile, to: s.position, in: allSquares) {
                    let hostileDist = hypot(s.position.x - hostile.position.x, s.position.y - hostile.position.y)
                    if hostileDist < 200 {
                        score += 15
                    }
                }
            }
            if traits.contains(.collector) && s.kind == .rare {
                score *= 1.5 // Bonus grande para items raros si es coleccionista
            }
        }
        
        return score
    }
        return candidates.max(by: { scoreSquare($0, player: player, hunger: hunger, energy: energy, companionStats: companionStats) < scoreSquare($1, player: player, hunger: hunger, energy: energy, companionStats: companionStats) })
    }

    private func scoreSquare(_ s: WorldSquareBody, player: CGPoint, hunger: Double, energy: Double, companionStats: CompanionStats?) -> Double {
        let d = hypot(s.position.x - player.x, s.position.y - player.y)
        let distFactor = 1 / max(24, d)

        let needFood = max(0, 0.55 - hunger)
        let needEnergy = max(0, 0.55 - energy)

        var score = distFactor * 100
        score += needFood * s.kind.hungerRestore * 80
        score += needEnergy * s.kind.energyRestore * 60
        score += (s.kind == .rare ? 12 : 0)

        // Modificadores de personalidad
        if let traits = companionStats?.traits {
            if traits.contains(.aggressive) {
                // El compañero agresivo se acerca más a los hostiles (esto se maneja en la lógica de 'flee',
                // pero aquí podemos darle un pequeño bonus por estar cerca de la acción)
                if let hostile = nearestSquare(of: .hostile, to: s.position, in: []) /* passing empty array as we don't have squares here, logic needs adjustment */ {
                    let hostileDist = hypot(s.position.x - hostile.position.x, s.position.y - hostile.position.y)
                    if hostileDist < 200 {
                        score += 15
                    }
                }
            }
            if traits.contains(.collector) && s.kind == .rare {
                score *= 1.5 // Bonus grande para items raros si es coleccionista
            }
        }
        
        return score
    }

    private func randomPoint(in rect: CGRect, inset: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: (rect.minX + inset)...(rect.maxX - inset)),
            y: CGFloat.random(in: (rect.minY + inset)...(rect.maxY - inset))
        )
    }

    private func clamp(_ p: CGPoint, worldBounds: CGRect, inset: CGFloat) -> CGPoint {
        CGPoint(
            x: min(max(p.x, worldBounds.minX + inset), worldBounds.maxX - inset),
            y: min(max(p.y, worldBounds.minY + inset), worldBounds.maxY - inset)
        )
    }
}
