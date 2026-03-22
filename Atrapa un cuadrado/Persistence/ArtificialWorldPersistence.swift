import Foundation
import SwiftData

/// Arranque único del contenedor SwiftData para Artificial World.
enum ArtificialWorldPersistence {
    @MainActor private static var repository: SwiftDataWorldRepository?

    @MainActor
    static func bootstrapIfNeeded() {
        guard repository == nil else {
            return
        }
        do {
            let schema = Schema([PersistedWorldState.self, PersistedAgentMemoryRecord.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            repository = SwiftDataWorldRepository(context: context)
        } catch {
            assertionFailure("SwiftData bootstrap failed: \(error)")
            do {
                let schema = Schema([PersistedWorldState.self, PersistedAgentMemoryRecord.self])
                let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: schema, configurations: [configuration])
                let context = ModelContext(container)
                repository = SwiftDataWorldRepository(context: context)
            } catch {
                fatalError("SwiftData in-memory fallback failed: \(error)")
            }
        }
    }

    @MainActor
    static func worldRepository() -> WorldRepository {
        bootstrapIfNeeded()
        return repository!
    }

    @MainActor
    static func agentMemoryStore() -> AgentMemoryStore {
        bootstrapIfNeeded()
        return repository!
    }
}
