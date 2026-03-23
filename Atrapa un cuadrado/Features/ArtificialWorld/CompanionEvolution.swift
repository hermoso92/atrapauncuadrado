import Foundation

/// Lógica para la evolución y detección de personalidad del companion.
enum CompanionEvolution {

    // MARK: - XP Calculation

    /// Calcula la nueva XP y actualiza las stats del companion.
    static func calculateNewXP(
        for stats: inout CompanionStats,
        survivalTime: TimeInterval,
        captures: Int,
        hostileCaptures: Int,
        deaths: Int
    ) {
        let survivalXP = survivalTime * 0.1 // 1 punto de XP por cada 10 segundos
        let captureXP = Double(captures) * 2.0
        let hostileXP = Double(hostileCaptures) * 5.0
        let deathPenalty = Double(deaths) * 25.0

        let gainedXP = survivalXP + captureXP + hostileXP - deathPenalty
        
        stats.experience += max(0, gainedXP)
        stats.totalXP += max(0, gainedXP)
        
        stats.sessionsPlayed += 1
        stats.totalDeaths += deaths
        stats.totalCaptures += captures
    }

    // MARK: - Level Up

    /// Verifica si el companion sube de nivel y actualiza las stats.
    static func checkLevelUp(for stats: inout CompanionStats) -> Bool {
        guard stats.level < 10 else { return false }
        
        let requiredXP = CompanionStats.xpPerLevel[stats.level]
        if stats.experience >= requiredXP {
            stats.level += 1
            stats.experience -= requiredXP // Resetea la XP para el nuevo nivel
            return true
        }
        return false
    }

    // MARK: - Trait Detection

    /// Detecta y actualiza los rasgos del companion basado en su historial.
    static func detectTraits(for stats: inout CompanionStats) {
        guard stats.sessionsPlayed > 5 else { // Necesita un mínimo de datos
            stats.traits = [.balanced]
            return
        }
        
        var detected: Set<CompanionTrait> = []
        
        let deathRate = Double(stats.totalDeaths) / Double(stats.sessionsPlayed)
        if deathRate > TraitDetection.deathRateForProtector {
            detected.insert(.protector)
        }
        
        if stats.totalCaptures > 0 {
            stats.hostileCaptureRate = Double(stats.hostileCaptures) / Double(stats.totalCaptures)
            if stats.hostileCaptureRate > TraitDetection.hostileRateForAggressive {
                detected.insert(.aggressive)
            }
        }
        
        // Esta lógica necesitaría más datos, por ahora es un placeholder
        // stats.resourceAccumulation = ...
        // if stats.resourceAccumulation > TraitDetection.itemsForCollector {
        //     detected.insert(.collector)
        // }
        
        if detected.isEmpty {
            stats.traits = [.balanced]
        } else {
            stats.traits = detected
        }
    }
    
    // MARK: - Unlocked Abilities
    
    /// Devuelve las habilidades desbloqueadas para un nivel de companion.
    static func unlockedAbilities(for level: Int) -> [CompanionSpecialization] {
        var abilities: [CompanionSpecialization] = []
        if level >= 3 {
            abilities.append(.gathering)
        }
        if level >= 5 {
            abilities.append(.survival)
        }
        if level >= 8 {
            abilities.append(.combat)
        }
        return abilities
    }
}
