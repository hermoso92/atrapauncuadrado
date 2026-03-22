import Foundation
import os
import SwiftData

/// Arranque único del contenedor SwiftData para Artificial World.
enum ArtificialWorldPersistence {
    @MainActor private static var repository: SwiftDataWorldRepository?

    /// Garantiza `Application Support` antes del store SQLite (evita fallos en simulador / primer arranque).
    private static func ensureApplicationSupportDirectory() {
        guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    @MainActor
    static func bootstrapIfNeeded() {
        guard repository == nil else {
            return
        }
        ensureApplicationSupportDirectory()
        do {
            let schema = Schema([PersistedWorldState.self, PersistedAgentMemoryRecord.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            repository = SwiftDataWorldRepository(context: context)
            AppLog.persistence.info("SwiftData store ready (on disk)")
        } catch {
            AppLog.persistence.error("SwiftData on-disk bootstrap failed: \(String(describing: error), privacy: .public)")
            assertionFailure("SwiftData bootstrap failed: \(error)")
            do {
                let schema = Schema([PersistedWorldState.self, PersistedAgentMemoryRecord.self])
                let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: schema, configurations: [configuration])
                let context = ModelContext(container)
                repository = SwiftDataWorldRepository(context: context)
                AppLog.persistence.warning("SwiftData using in-memory fallback")
            } catch {
                AppLog.persistence.critical("SwiftData in-memory fallback failed: \(String(describing: error), privacy: .public)")
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
