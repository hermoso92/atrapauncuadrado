import Foundation

/// Mutación local pendiente de subir al servidor (futuro).
struct PendingWorldMutation: Codable, Equatable, Sendable {
    var id: UUID
    var kind: String
    var payloadJSON: String
    var createdAt: Date
}

/// Token opaco para cabeceras HTTP futuras; sin URLSession aquí.
protocol AuthTokenProviding: Sendable {
    func bearerToken() async -> String?
}

/// Sincronización de mundo remoto; implementación real sustituirá `NoOpWorldSyncService`.
protocol WorldSyncService: Sendable {
    func enqueue(_ mutation: PendingWorldMutation) async
    func pendingCount() async -> Int
}

struct NoOpAuthTokenProvider: AuthTokenProviding {
    func bearerToken() async -> String? { nil }
}

actor NoOpWorldSyncService: WorldSyncService {
    func enqueue(_ mutation: PendingWorldMutation) async {}
    func pendingCount() async -> Int { 0 }
}
