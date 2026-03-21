import UIKit

@MainActor
final class HapticsManager {
    static let shared = HapticsManager(saveManager: .shared)

    private let saveManager: SaveManager
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    init(saveManager: SaveManager) {
        self.saveManager = saveManager
        prepareGenerators()
    }

    func tap() {
        guard isEnabled else { return }
        lightImpact.impactOccurred(intensity: 0.8)
        lightImpact.prepare()
    }

    func capture(strength: Int) {
        guard isEnabled else { return }
        if strength > 2 {
            mediumImpact.impactOccurred(intensity: 0.9)
            mediumImpact.prepare()
        } else {
            lightImpact.impactOccurred(intensity: 0.7)
            lightImpact.prepare()
        }
    }

    func damage() {
        guard isEnabled else { return }
        heavyImpact.impactOccurred(intensity: 1)
        heavyImpact.prepare()
    }

    func success() {
        guard isEnabled else { return }
        notificationFeedback.notificationOccurred(.success)
        notificationFeedback.prepare()
    }

    func warning() {
        guard isEnabled else { return }
        notificationFeedback.notificationOccurred(.warning)
        notificationFeedback.prepare()
    }

    func error() {
        guard isEnabled else { return }
        notificationFeedback.notificationOccurred(.error)
        notificationFeedback.prepare()
    }

    private var isEnabled: Bool {
        saveManager.loadProgress().hapticsEnabled
    }

    private func prepareGenerators() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notificationFeedback.prepare()
    }
}
