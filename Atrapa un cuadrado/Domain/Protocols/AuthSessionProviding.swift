import Foundation

enum AuthSessionState: String, Sendable {
    case anonymous
    case signedIn
}

/// Sesión de usuario opaca; listo para token/JWT cuando exista backend.
protocol AuthSessionProviding: Sendable {
    var state: AuthSessionState { get }
    /// Identificador estable en cliente o servidor; nil si anónimo.
    var userId: String? { get }
}

struct AnonymousAuthSession: AuthSessionProviding {
    var state: AuthSessionState { .anonymous }
    var userId: String? { nil }
}
