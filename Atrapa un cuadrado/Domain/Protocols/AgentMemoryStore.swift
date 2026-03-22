import Foundation

/// Subconjunto explícito de memoria del agente (puede mapear al mismo almacén que `WorldRepository`).
@MainActor
protocol AgentMemoryStore: AnyObject {
    func append(_ entry: AgentMemoryEntry) throws
    func recent(limit: Int) throws -> [AgentMemoryEntry]
}
