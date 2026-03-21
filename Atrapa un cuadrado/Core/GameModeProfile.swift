import CoreGraphics
import Foundation
import UIKit

/// Immutable ruleset and presentation contract for a concrete game mode.
struct GameModeProfile {
    let mode: GameMode
    let initialSpawnInterval: TimeInterval
    let initialSquares: Int
    let maxSquares: Int
    let difficultyStepInterval: TimeInterval
    let spawnIntervalFloor: TimeInterval
    let spawnIntervalStep: TimeInterval
    let squareSpeedRamp: CGFloat
    let startingRound: Int
    let availableSquareKinds: [SquareKind]
    let allowsObstacles: Bool
    let enabledAbilities: Set<AbilityType>
    let showsCharacters: Bool
    let showsAbilitiesInStore: Bool
    let runCoinsMultiplier: CGFloat
    let arenaFillColor: UIColor
    let arenaStrokeColor: UIColor
    let hudSubtitle: String
    let menuFooter: String
    let roundLabelTitle: String
    let modeAccentColor: UIColor
    let storeTitle: String
    let storeSubtitle: String
    let storeTip: String
    let defaultStoreFeedback: String
    let gameOverSubtitle: String
    let pauseStrokeColor: UIColor
    let arenaCornerRadius: CGFloat
    let arenaLineWidth: CGFloat
    let arenaGlowWidth: CGFloat
    let targetIndicatorColor: UIColor
    let squareStrokeColor: UIColor
    let squareGlowWidth: CGFloat
    let captureBurstRadius: CGFloat
    let captureBurstScale: CGFloat
    let captureBurstDuration: TimeInterval
    let respawnThreshold: Int

    static func profile(for mode: GameMode) -> GameModeProfile {
        switch mode {
        case .original:
            return GameModeProfile(
                mode: mode,
                initialSpawnInterval: 1.95,
                initialSquares: 4,
                maxSquares: 9,
                difficultyStepInterval: 22,
                spawnIntervalFloor: 1.0,
                spawnIntervalStep: 0.10,
                squareSpeedRamp: 0.12,
                startingRound: 1,
                availableSquareKinds: [.normal, .fast],
                allowsObstacles: false,
                enabledAbilities: [],
                showsCharacters: false,
                showsAbilitiesInStore: false,
                runCoinsMultiplier: 1,
                arenaFillColor: UIColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 0.95),
                arenaStrokeColor: Palette.warning,
                hudSubtitle: "La lectura original: ritmo limpio, contacto directo y cero build.",
                menuFooter: "El corazon del juego. Todo depende de tus manos.",
                roundLabelTitle: "Oleada",
                modeAccentColor: Palette.warning,
                storeTitle: "TIENDA ORIGINAL",
                storeSubtitle: "Mejoras pequeñas para runs mas largas y puntuaciones mas finas.",
                storeTip: "Refuerza tus runs clasicas sin romper el arcade.",
                defaultStoreFeedback: "Todo lo que compres aqui solo afecta al modo Clasico.",
                gameOverSubtitle: "El Clasico siempre te pide una partida mas.",
                pauseStrokeColor: Palette.warning,
                arenaCornerRadius: 18,
                arenaLineWidth: 3,
                arenaGlowWidth: 0,
                targetIndicatorColor: Palette.warning,
                squareStrokeColor: Palette.warning,
                squareGlowWidth: 0,
                captureBurstRadius: 7,
                captureBurstScale: 1.8,
                captureBurstDuration: 0.14,
                respawnThreshold: 42
            )
        case .evolution:
            return GameModeProfile(
                mode: mode,
                initialSpawnInterval: GameConfig.initialSpawnInterval,
                initialSquares: GameConfig.initialSquares,
                maxSquares: GameConfig.maxSquares,
                difficultyStepInterval: GameConfig.difficultyStepInterval,
                spawnIntervalFloor: 0.7,
                spawnIntervalStep: 0.14,
                squareSpeedRamp: 0.18,
                startingRound: 1,
                availableSquareKinds: SquareKind.allCases,
                allowsObstacles: true,
                enabledAbilities: Set(AbilityType.allCases),
                showsCharacters: true,
                showsAbilitiesInStore: true,
                runCoinsMultiplier: 1,
                arenaFillColor: UIColor(red: 0.05, green: 0.08, blue: 0.12, alpha: 0.85),
                arenaStrokeColor: Palette.stroke,
                hudSubtitle: "La lectura moderna: personajes, armas, habilidades y decisiones reales.",
                menuFooter: "El modo donde la build importa tanto como tus reflejos.",
                roundLabelTitle: "Ronda",
                modeAccentColor: Palette.stroke,
                storeTitle: "TIENDA EVOLUCION",
                storeSubtitle: "Convierte monedas en arsenal, identidad y herramientas.",
                storeTip: "Compra, equipa y entra con una build pensada.",
                defaultStoreFeedback: "Dash viene activo desde el inicio. Aqui montas tu build completa.",
                gameOverSubtitle: "Arsenal no perdona, pero siempre deja margen para volver mejor.",
                pauseStrokeColor: Palette.stroke,
                arenaCornerRadius: 26,
                arenaLineWidth: 2,
                arenaGlowWidth: 2,
                targetIndicatorColor: Palette.stroke,
                squareStrokeColor: .white,
                squareGlowWidth: 2,
                captureBurstRadius: 10,
                captureBurstScale: 2.6,
                captureBurstDuration: 0.18,
                respawnThreshold: 46
            )
        case .ghost:
            return GameModeProfile(
                mode: mode,
                initialSpawnInterval: 1.25,
                initialSquares: 6,
                maxSquares: 18,
                difficultyStepInterval: 14,
                spawnIntervalFloor: 0.52,
                spawnIntervalStep: 0.12,
                squareSpeedRamp: 0.22,
                startingRound: 1,
                availableSquareKinds: SquareKind.allCases,
                allowsObstacles: true,
                enabledAbilities: Set(AbilityType.allCases),
                showsCharacters: true,
                showsAbilitiesInStore: true,
                runCoinsMultiplier: 1.35,
                arenaFillColor: UIColor(red: 0.03, green: 0.08, blue: 0.07, alpha: 0.90),
                arenaStrokeColor: UIColor(red: 0.56, green: 1.00, blue: 0.70, alpha: 1),
                hudSubtitle: "Modo oculto: la señal se rompe, la arena se acelera y todo castiga mas.",
                menuFooter: "La version torcida del juego. Ruido, presion y sangre fria.",
                roundLabelTitle: "Fase",
                modeAccentColor: UIColor(red: 0.56, green: 1.00, blue: 0.70, alpha: 1),
                storeTitle: "ARSENAL FANTASMA",
                storeSubtitle: "Build agresiva para un modo que no te deja respirar.",
                storeTip: "En Fantasma todo pega mas fuerte. Preparate antes de entrar.",
                defaultStoreFeedback: "Fantasma premia ritmo, lectura y descaro. Ajusta tu carga con cabeza.",
                gameOverSubtitle: "La señal cae, pero el modo sigue llamandote.",
                pauseStrokeColor: UIColor(red: 0.56, green: 1.00, blue: 0.70, alpha: 1),
                arenaCornerRadius: 30,
                arenaLineWidth: 2.5,
                arenaGlowWidth: 4,
                targetIndicatorColor: UIColor(red: 0.56, green: 1.00, blue: 0.70, alpha: 1),
                squareStrokeColor: UIColor(red: 0.80, green: 1.00, blue: 0.89, alpha: 1),
                squareGlowWidth: 4,
                captureBurstRadius: 12,
                captureBurstScale: 3.1,
                captureBurstDuration: 0.22,
                respawnThreshold: 36
            )
        }
    }
}
