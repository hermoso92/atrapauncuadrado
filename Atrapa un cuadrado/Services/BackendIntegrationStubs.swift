import Foundation

/// Sesión local hasta integrar autenticación real (OAuth / token backend).
@MainActor
final class LocalAuthSessionProvider: AuthSessionProviding {
    static let shared = LocalAuthSessionProvider()

    var state: AuthSessionState { .anonymous }
    var userId: String? { nil }
}

/// Documentación viva de puntos donde enganchar red más adelante (sin URLs ni SDK).
enum BackendIntegrationPoints {
    /// `WorldRepository` debe poder serializar `ArtificialWorldSnapshot` para subir/bajar.
    static let worldRepositoryProtocol = "Domain/Protocols/WorldRepository.swift"
    /// Memoria del agente alineada con sync incremental.
    static let agentMemoryProtocol = "Domain/Protocols/AgentMemoryStore.swift"
    /// Eventos ya centralizados en `TelemetryLogging` (`AppTelemetry` en debug).
    static let telemetryProtocol = "Domain/Protocols/TelemetryLogging.swift"
    /// Sustituir `LocalAuthSessionProvider` por proveedor con token y `userId` estable.
    static let authProtocol = "Domain/Protocols/AuthSessionProviding.swift"
}
