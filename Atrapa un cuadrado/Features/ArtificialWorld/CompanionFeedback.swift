import Foundation

/// Gestiona y provee las frases de feedback del companion.
enum CompanionFeedback {

    enum Event {
        case levelUp(newLevel: Int)
        case traitDetected(trait: CompanionTrait)
        case dangerNearby(source: String)
        case lowResources
        case successfulCapture
    }
    
    /// Devuelve una frase apropiada para el evento y el trait del companion.
    static func getPhrase(for event: Event, with traits: Set<CompanionTrait>) -> String {
        switch event {
        case .levelUp(let newLevel):
            return "¡Subimos al nivel \(newLevel)! Siento que aprendo contigo."
            
        case .traitDetected(let trait):
            return phraseForTrait(trait)
            
        case .dangerNearby:
            if traits.contains(.protector) {
                return "Cuidado, detecto una amenaza. ¡Mantente alerta!"
            } else if traits.contains(.aggressive) {
                return "Un objetivo. ¿Vamos a por él?"
            } else {
                return "Zona peligrosa cerca. Mejor evitarla."
            }
            
        case .lowResources:
            if traits.contains(.collector) {
                return "Nuestras reservas son bajas. Es hora de recolectar."
            } else {
                return "Necesitamos recursos. Busca fuentes de energía o nutrientes."
            }
            
        case .successfulCapture:
            if traits.contains(.aggressive) {
                return "¡Excelente! Uno menos."
            } else {
                return "Recursos asegurados. Buen trabajo."
            }
        }
    }
    
    private static func phraseForTrait(_ trait: CompanionTrait) -> String {
        switch trait {
        case .protector:
            return "Mi prioridad es tu seguridad. Jugaré con más cautela."
        case .aggressive:
            return "Noto un patrón más agresivo. ¡Vamos a la ofensiva!"
        case .collector:
            return "Nos estamos volviendo buenos acumulando recursos. Sigamos así."
        case .balanced:
            return "Me adapto a tu estilo. Sigamos explorando juntos."
        }
    }
}
