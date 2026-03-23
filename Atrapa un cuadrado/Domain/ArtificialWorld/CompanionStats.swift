import Foundation

// Companion Stats - se persiste en el snapshot del mundo
struct CompanionStats: Codable {
    var level: Int = 1
    var experience: Double = 0
    var totalXP: Double = 0
    var traits: Set<CompanionTrait> = []
    var specializations: Set<CompanionSpecialization> = []
    var sessionsPlayed: Int = 0
    var totalDeaths: Int = 0
    var totalCaptures: Int = 0
    var hostileCaptureRate: Double = 0
    var resourceAccumulation: Double = 0
    
    // XP necesaria para cada nivel
    static let xpPerLevel: [Double] = [0, 100, 250, 450, 700, 1000, 1350, 1800, 2300, 2900]
}

// Rasgos de personalidad detectados
enum CompanionTrait: String, Codable, CaseIterable {
    case protector  // Muertes frecuentes
    case aggressive // Caza hostiles intencionalmente
    case collector  // Acumula recursos
    case balanced   // Sin patrón claro
}

// Especializaciones del companion
enum CompanionSpecialization: String, Codable, CaseIterable {
    case survival    // Supervivencia, evasión
    case gathering   // Eficiencia de recolección
    case combat      // Tácticas de combate
}

// Umbrales para detectar rasgos
struct TraitDetection {
    static let deathRateForProtector: Double = 0.3    // >30% de las partidas con al menos una muerte
    static let hostileRateForAggressive: Double = 0.4 // >40% de las capturas son hostiles
    static let itemsForCollector: Int = 30         // >30 items en inventario en promedio
}
