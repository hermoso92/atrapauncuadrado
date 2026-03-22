import SpriteKit
import UIKit

final class SettingsScene: BaseScene {
    private var progress = GameProgress.defaultProgress
    private var feedbackMessage: String?
    private var feedbackColor: UIColor?
    private var hasLoadedProgress = false
    private let secretCode = "amiguisimo"
#if DEBUG
    private let showsDebugControls = true
#else
    private let showsDebugControls = false
#endif

    init(sceneSize: CGSize, gameMode: GameMode) {
        super.init(sceneSize: sceneSize, gameMode: gameMode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        progress = saveManager.loadProgress()
        hasLoadedProgress = true
        buildScene()
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            await self.purchaseManager.refreshCatalog()
            await self.purchaseManager.refreshEntitlements()
            self.progress = self.saveManager.loadProgress()
            self.buildScene()
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard hasLoadedProgress else { return }
        buildScene()
    }

    private func buildScene() {
        removeAllChildren()

        setupBackdrop(title: "AJUSTES", subtitle: "Controla compra, audio, vibracion y accesos especiales sin ruido.")

        let summaryPanel = makePanel(
            size: CGSize(width: size.width - 42, height: 96),
            stroke: gameMode?.summaryAccent ?? Palette.stroke,
            fill: Palette.panel.withAlphaComponent(0.94),
            cornerRadius: 28
        )
        summaryPanel.position = CGPoint(x: size.width / 2, y: size.height - 232)
        addChild(summaryPanel)

        let summaryTitle = makeLabel(
            text: "ESTADO DEL PERFIL",
            fontNamed: GameConfig.coinFont,
            fontSize: 11,
            color: gameMode?.summaryAccent ?? Palette.stroke,
            width: summaryPanel.frame.width - 36,
            lines: 1
        )
        summaryTitle.position = CGPoint(x: 0, y: 24)
        summaryPanel.addChild(summaryTitle)

        let summaryStats = makeLabel(
            text: "Banco \(progress.coins)  •  Evolution \(progress.evolutionUnlocked ? "activo" : "cerrado")  •  Fantasma \(progress.ghostModeUnlocked ? "activo" : "cerrado")",
            fontNamed: GameConfig.titleFont,
            fontSize: 18,
            color: Palette.textPrimary,
            width: summaryPanel.frame.width - 36,
            lines: 2
        )
        summaryStats.position = CGPoint(x: 0, y: -2)
        summaryPanel.addChild(summaryStats)

        let summaryNote = makeLabel(
            text: progress.godModeEnabled ? "Modo dios encendido. Esta sesion no representa una build de produccion." : "Ajusta lo esencial y vuelve al juego.",
            fontNamed: GameConfig.coinFont,
            fontSize: 11,
            color: progress.godModeEnabled ? Palette.warning : Palette.textSecondary,
            width: summaryPanel.frame.width - 36,
            lines: 2
        )
        summaryNote.position = CGPoint(x: 0, y: -32)
        summaryPanel.addChild(summaryNote)

        let topY = size.height - 354
        let bottomY: CGFloat = 188
        let actionCount = showsDebugControls ? 6 : 4
        let rowSpacing = actionCount > 1 ? (topY - bottomY) / CGFloat(actionCount - 1) : 0

        let premium = MenuButtonNode(
            actionID: "restore.purchases",
            title: progress.evolutionUnlocked ? "Evolution activo" : "Restaurar compras",
            subtitle: progress.evolutionUnlocked
                ? "La compra premium ya esta aplicada en este dispositivo"
                : "Sincroniza App Store para recuperar Evolution"
        )
        premium.position = CGPoint(x: size.width / 2, y: topY)
        premium.setVisualStyle(
            fillColor: progress.evolutionUnlocked ? Palette.stroke.withAlphaComponent(0.18) : Palette.panel,
            strokeColor: progress.evolutionUnlocked ? Palette.stroke : Palette.textSecondary,
            titleColor: Palette.textPrimary,
            subtitleColor: progress.evolutionUnlocked ? Palette.stroke : Palette.warning
        )
        addChild(premium)

        if showsDebugControls {
            let godMode = MenuButtonNode(
                actionID: "toggle.godMode",
                title: progress.godModeEnabled ? "Modo dios total" : "Modo dios desactivado",
                subtitle: "Invencible, sin cooldown y con control de fase dentro de la run"
            )
            godMode.position = CGPoint(x: size.width / 2, y: topY - rowSpacing)
            godMode.setVisualStyle(
                fillColor: progress.godModeEnabled ? Palette.warning.withAlphaComponent(0.18) : Palette.panel,
                strokeColor: progress.godModeEnabled ? Palette.warning : Palette.stroke,
                titleColor: Palette.textPrimary,
                subtitleColor: progress.godModeEnabled ? Palette.warning : Palette.textSecondary
            )
            addChild(godMode)

            let bonusCoins = MenuButtonNode(
                actionID: "grant.coins",
                title: "Sumar 1000 monedas",
                subtitle: "Añade saldo de prueba al progreso actual"
            )
            bonusCoins.position = CGPoint(x: size.width / 2, y: topY - rowSpacing * 2)
            bonusCoins.setVisualStyle(
                fillColor: Palette.warning.withAlphaComponent(0.14),
                strokeColor: Palette.warning,
                titleColor: Palette.textPrimary,
                subtitleColor: Palette.warning
            )
            addChild(bonusCoins)
        }

        let sound = MenuButtonNode(
            actionID: "toggle.sound",
            title: progress.soundEnabled ? "Sonido activado" : "Sonido desactivado",
            subtitle: "Pulsa para alternar"
        )
        sound.position = CGPoint(x: size.width / 2, y: topY - rowSpacing * (showsDebugControls ? 3 : 1))
        addChild(sound)

        let haptics = MenuButtonNode(
            actionID: "toggle.haptics",
            title: progress.hapticsEnabled ? "Vibracion activada" : "Vibracion desactivada",
            subtitle: "Pulsa para alternar"
        )
        haptics.position = CGPoint(x: size.width / 2, y: topY - rowSpacing * (showsDebugControls ? 4 : 2))
        addChild(haptics)

        let secretCodeButton = MenuButtonNode(
            actionID: "secret.code",
            title: progress.ghostModeUnlocked ? "Codigo aceptado" : "Introducir codigo",
            subtitle: progress.ghostModeUnlocked ? "Protocolo Fantasma ya esta desbloqueado" : "Revela contenido oculto del juego"
        )
        secretCodeButton.position = CGPoint(x: size.width / 2, y: topY - rowSpacing * (showsDebugControls ? 5 : 3))
        secretCodeButton.setVisualStyle(
            fillColor: progress.ghostModeUnlocked ? gameMode?.summaryAccent.withAlphaComponent(0.18) ?? Palette.panel : Palette.panel,
            strokeColor: progress.ghostModeUnlocked ? Palette.success : Palette.accent,
            titleColor: Palette.textPrimary,
            subtitleColor: progress.ghostModeUnlocked ? Palette.success : Palette.accent
        )
        addChild(secretCodeButton)

        let notePanel = makePanel(
            size: CGSize(width: size.width - 42, height: 72),
            stroke: feedbackColor ?? Palette.textSecondary.withAlphaComponent(0.55),
            fill: Palette.panel.withAlphaComponent(0.92),
            cornerRadius: 24
        )
        notePanel.position = CGPoint(x: size.width / 2, y: 118)
        addChild(notePanel)

        let note = makeLabel(
            text: feedbackMessage ?? "Usa restaurar compras si ya pagaste Evolution en App Store.",
            fontNamed: GameConfig.coinFont,
            fontSize: 12,
            color: feedbackColor ?? Palette.textSecondary,
            width: notePanel.frame.width - 36,
            lines: 2
        )
        note.position = CGPoint(x: 0, y: 12)
        notePanel.addChild(note)

        let reset = MenuButtonNode(
            actionID: "reset.progress",
            title: "Reiniciar progreso",
            subtitle: "Borra monedas, compras y seleccion actual",
            size: CGSize(width: 300, height: 64)
        )
        reset.position = CGPoint(x: size.width / 2, y: 164)
        reset.setVisualStyle(
            fillColor: Palette.danger.withAlphaComponent(0.14),
            strokeColor: Palette.danger,
            titleColor: Palette.textPrimary,
            subtitleColor: Palette.danger
        )
        addChild(reset)

        let back = MenuButtonNode(actionID: "back", title: "Volver", subtitle: "Regresar al menu", size: CGSize(width: 180, height: 56))
        back.position = CGPoint(x: size.width / 2, y: 70)
        addChild(back)
    }

    private func makePanel(size: CGSize, stroke: UIColor, fill: UIColor, cornerRadius: CGFloat) -> SKShapeNode {
        let panel = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        panel.fillColor = fill
        panel.strokeColor = stroke
        panel.lineWidth = 2
        return panel
    }

    private func makeLabel(text: String, fontNamed: String, fontSize: CGFloat, color: UIColor, width: CGFloat, lines: Int) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontNamed)
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.verticalAlignmentMode = .top
        label.horizontalAlignmentMode = .center
        label.preferredMaxLayoutWidth = width
        label.numberOfLines = lines
        label.lineBreakMode = .byWordWrapping
        return label
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self),
              let button = button(at: location) else {
            return
        }

        switch button.actionID {
        case "restore.purchases":
            soundManager.playButtonTap()
            hapticsManager.tap()
            Task { @MainActor [weak self] in
                guard let self else {
                    return
                }
                let result = await self.purchaseManager.restorePurchases()
                self.progress = self.saveManager.loadProgress()
                self.showFeedback(for: result)
                switch result {
                case .success, .restored:
                    self.soundManager.playSuccess()
                    self.hapticsManager.success()
                case .pending, .unavailable, .failed:
                    self.soundManager.playWarning()
                    self.hapticsManager.warning()
                case .cancelled:
                    self.soundManager.playButtonTap()
                    self.hapticsManager.tap()
                }
                self.buildScene()
            }
        case "toggle.godMode":
            soundManager.playButtonTap()
            hapticsManager.tap()
            progress = saveManager.update { progress in
                progress.godModeEnabled.toggle()
            }
            feedbackMessage = nil
            feedbackColor = nil
            buildScene()
        case "grant.coins":
            soundManager.playSuccess()
            hapticsManager.success()
            progress = saveManager.update { progress in
                progress.coins += 1_000
            }
            feedbackMessage = nil
            feedbackColor = nil
            buildScene()
        case "toggle.sound":
            soundManager.playButtonTap()
            hapticsManager.tap()
            progress = saveManager.update { $0.soundEnabled.toggle() }
            feedbackMessage = nil
            feedbackColor = nil
            buildScene()
        case "toggle.haptics":
            soundManager.playButtonTap()
            progress = saveManager.update { $0.hapticsEnabled.toggle() }
            if progress.hapticsEnabled {
                hapticsManager.success()
            }
            feedbackMessage = nil
            feedbackColor = nil
            buildScene()
        case "reset.progress":
            soundManager.playWarning()
            hapticsManager.warning()
            progress = saveManager.resetProgress()
            feedbackMessage = "Progreso reiniciado."
            feedbackColor = Palette.warning
            buildScene()
        case "secret.code":
            soundManager.playButtonTap()
            hapticsManager.tap()
            presentSecretCodePrompt()
        case "back":
            soundManager.playButtonTap()
            hapticsManager.tap()
            guard let gameMode else {
                return
            }
            present(MainMenuScene(sceneSize: size, gameMode: gameMode))
        default:
            break
        }
    }

    private func showFeedback(for result: PurchaseManager.ActionResult) {
        switch result {
        case .success, .restored:
            feedbackMessage = "Compras sincronizadas. Evolution esta disponible."
            feedbackColor = Palette.success
        case .pending:
            feedbackMessage = "La compra sigue pendiente de aprobacion."
            feedbackColor = Palette.warning
        case .cancelled:
            feedbackMessage = "Restauracion cancelada."
            feedbackColor = Palette.textSecondary
        case .unavailable:
            feedbackMessage = "El producto premium aun no existe o no esta accesible en App Store Connect."
            feedbackColor = Palette.warning
        case let .failed(message):
            feedbackMessage = "No se pudo restaurar: \(message)"
            feedbackColor = Palette.danger
        }
    }

    private func presentSecretCodePrompt() {
        guard let presenter = activePresenter else {
            feedbackMessage = "No se pudo abrir la entrada de codigo."
            feedbackColor = Palette.danger
            buildScene()
            return
        }

        let alert = UIAlertController(
            title: "Codigo secreto",
            message: "Introduce la clave para revelar el modo oculto.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "codigo amiguisimo"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self, weak alert] _ in
            guard let self else {
                return
            }
            let code = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
            self.resolveSecretCode(code)
        })
        presenter.present(alert, animated: true)
    }

    private func resolveSecretCode(_ code: String) {
        guard !code.isEmpty else {
            feedbackMessage = "No has introducido ningun codigo."
            feedbackColor = Palette.warning
            soundManager.playWarning()
            hapticsManager.warning()
            buildScene()
            return
        }

        guard code == secretCode else {
            feedbackMessage = "Codigo incorrecto."
            feedbackColor = Palette.danger
            soundManager.playWarning()
            hapticsManager.error()
            buildScene()
            return
        }

        progress = saveManager.update { progress in
            progress.ghostModeUnlocked = true
        }
        feedbackMessage = "Codigo aceptado. Protocolo Fantasma ya esta disponible."
        feedbackColor = Palette.success
        soundManager.playSuccess()
        hapticsManager.success()
        buildScene()
    }

    private var activePresenter: UIViewController? {
        var presenter = view?.window?.rootViewController
        while let presented = presenter?.presentedViewController {
            presenter = presented
        }
        return presenter
    }
}
