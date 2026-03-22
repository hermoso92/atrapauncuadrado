import SpriteKit
import UIKit

final class StoreScene: BaseScene {
    private var progress = GameProgress.defaultProgress
    private var feedbackMessage: String?
    private var feedbackColor: UIColor?
    private var hasLoadedProgress = false
    private var currentTabIndex: Int = 0
    private var isPerformingPremiumAction = false
    private var purchaseObserver: NSObjectProtocol?
    private var contentScrollOffset: CGFloat = 0
    private var maxContentScrollOffset: CGFloat = 0
    private var contentViewportRect: CGRect = .zero
    private weak var contentNode: SKNode?
    private var contentTouchStart: CGPoint?
    private var contentScrollStartOffset: CGFloat = 0
    private var isDraggingContent = false

    init(sceneSize: CGSize, gameMode: GameMode) {
        super.init(sceneSize: sceneSize, gameMode: gameMode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        progress = saveManager.loadProgress()
        hasLoadedProgress = true
        installPurchaseObserver()
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

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        if let purchaseObserver {
            NotificationCenter.default.removeObserver(purchaseObserver)
            self.purchaseObserver = nil
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard hasLoadedProgress else { return }
        buildScene()
    }

    // MARK: - Layout

    private func buildScene() {
        guard let profile = modeProfile, let gameMode else {
            return
        }

        removeAllChildren()
        setupBackdrop(title: profile.storeTitle, subtitle: profile.storeSubtitle)

        let safeTop = view?.safeAreaInsets.top ?? 0
        let safeBottom = view?.safeAreaInsets.bottom ?? 0
        let topInset = max(safeTop, 12)
        let bottomInset = max(safeBottom, 12)
        let accentColor = profile.modeAccentColor

        // ── 1. Status bar (compact) ──────────────────────────────────
        let statusHeight: CGFloat = 60
        let statusPanel = makePanel(
            size: CGSize(width: size.width - 42, height: statusHeight),
            stroke: accentColor,
            fill: Palette.panel.withAlphaComponent(0.94)
        )
        statusPanel.position = CGPoint(x: size.width / 2, y: size.height - 178 - topInset)
        addChild(statusPanel)

        let bank = makeLabel(
            text: "\(progress.coins) monedas",
            fontNamed: GameConfig.titleFont,
            fontSize: 20,
            color: Palette.warning,
            width: (statusPanel.frame.width - 34) / 2,
            lines: 1
        )
        bank.horizontalAlignmentMode = .left
        bank.position = CGPoint(x: -statusPanel.frame.width / 2 + 18, y: 14)
        statusPanel.addChild(bank)

        let activeLoadout = currentLoadoutSummary(for: gameMode)
        let loadout = makeLabel(
            text: activeLoadout,
            fontNamed: GameConfig.coinFont,
            fontSize: 11,
            color: Palette.textSecondary,
            width: statusPanel.frame.width - 34,
            lines: 1
        )
        loadout.horizontalAlignmentMode = .left
        loadout.position = CGPoint(x: -statusPanel.frame.width / 2 + 18, y: -6)
        statusPanel.addChild(loadout)

        // ── 2. Tab bar ───────────────────────────────────────────────
        let sections = storeSections(for: gameMode, profile: profile)
        let tabBarHeight: CGFloat = 44
        let tabBarY = statusPanel.position.y - statusHeight / 2 - tabBarHeight / 2 - 8

        let tabTitles = tabTitleList(for: gameMode, sections: sections)
        let tabCount = tabTitles.count
        let tabGap: CGFloat = 8
        let totalTabWidth = size.width - 42
        let tabWidth = (totalTabWidth - tabGap * CGFloat(tabCount - 1)) / CGFloat(tabCount)

        for (index, title) in tabTitles.enumerated() {
            let isActive = index == currentTabIndex
            let pill = SKShapeNode(rectOf: CGSize(width: tabWidth, height: 34), cornerRadius: 17)
            pill.fillColor = isActive ? accentColor.withAlphaComponent(0.22) : Palette.panel.withAlphaComponent(0.6)
            pill.strokeColor = isActive ? accentColor : Palette.textSecondary.withAlphaComponent(0.4)
            pill.lineWidth = isActive ? 2 : 1
            pill.name = "store.tab.\(index)"
            let tabX = 21 + tabWidth / 2 + CGFloat(index) * (tabWidth + tabGap)
            pill.position = CGPoint(x: tabX, y: tabBarY)
            addChild(pill)

            let tabLabel = makeLabel(
                text: title,
                fontNamed: isActive ? GameConfig.titleFont : GameConfig.coinFont,
                fontSize: 12,
                color: isActive ? accentColor : Palette.textSecondary,
                width: tabWidth - 12,
                lines: 1
            )
            tabLabel.position = CGPoint(x: 0, y: 8)
            pill.addChild(tabLabel)
        }

        // ── 3. Content area ──────────────────────────────────────────
        let footerHeight: CGFloat = 48
        let backButtonHeight: CGFloat = 52
        let footerY = bottomInset + backButtonHeight + 12 + footerHeight / 2
        let contentTop = tabBarY - tabBarHeight / 2 - 8

        // Determine what to show in the current tab
        let showPremiumCard = gameMode == .original && currentTabIndex == 0
        let activeSection: StoreSection? = sectionForTab(
            currentTabIndex,
            gameMode: gameMode,
            sections: sections
        )

        let contentBottom = footerY + footerHeight / 2 + 10
        let viewportHeight = max(0, contentTop - contentBottom)
        contentViewportRect = CGRect(x: 21, y: contentBottom, width: size.width - 42, height: viewportHeight)

        let contentCropNode = SKCropNode()
        let contentMask = SKShapeNode(rect: contentViewportRect, cornerRadius: 24)
        contentMask.fillColor = .white
        contentMask.strokeColor = .clear
        contentCropNode.maskNode = contentMask
        addChild(contentCropNode)

        let contentNode = SKNode()
        contentCropNode.addChild(contentNode)
        self.contentNode = contentNode

        var cursorY = contentTop
        var lowestContentY = contentTop

        // Premium card (Original mode, tab 0)
        if showPremiumCard {
            let premiumCard = premiumEvolutionCard()
            let premiumHeight: CGFloat = 92
            cursorY -= premiumHeight / 2
            premiumCard.position = CGPoint(x: size.width / 2, y: cursorY)
            contentNode.addChild(premiumCard)
            lowestContentY = min(lowestContentY, cursorY - premiumHeight / 2)
            cursorY -= premiumHeight / 2 + 10
        }

        // Section header + item grid
        if let section = activeSection {
            // Section header
            let header = makeSectionHeader(title: section.title, subtitle: section.subtitle, y: cursorY)
            contentNode.addChild(header)
            lowestContentY = min(lowestContentY, cursorY - 20)
            cursorY -= 28

            // Items grid (2 columns)
            let rows = itemsByRows(section.items, columns: 2)
            let cardHeight: CGFloat = 82
            let rowGap: CGFloat = 8
            let colGap: CGFloat = 10
            let cardWidth = (size.width - 42 - colGap) / 2

            for (rowIndex, row) in rows.enumerated() {
                for (columnIndex, item) in row.enumerated() {
                    let card = storeCard(for: item, gameMode: gameMode, section: section.kind, cardWidth: cardWidth)
                    let x = 21 + cardWidth / 2 + CGFloat(columnIndex) * (cardWidth + colGap)
                    let y = cursorY - cardHeight / 2 - CGFloat(rowIndex) * (cardHeight + rowGap)
                    card.position = CGPoint(x: x, y: y)
                    contentNode.addChild(card)
                    lowestContentY = min(lowestContentY, y - cardHeight / 2)
                }
            }
        }

        let totalContentHeight = max(viewportHeight, contentTop - lowestContentY + 16)
        maxContentScrollOffset = max(0, totalContentHeight - viewportHeight)
        contentScrollOffset = min(max(contentScrollOffset, 0), maxContentScrollOffset)
        contentNode.position = CGPoint(x: 0, y: contentScrollOffset)

        if maxContentScrollOffset > 0 {
            let scrollHint = makeLabel(
                text: "Desliza para ver mas",
                fontNamed: GameConfig.coinFont,
                fontSize: 10,
                color: Palette.textSecondary,
                width: 140,
                lines: 1
            )
            scrollHint.position = CGPoint(x: size.width / 2, y: contentBottom + 12)
            addChild(scrollHint)
        }

        // ── 4. Footer (feedback message) ─────────────────────────────
        let footerPanel = makePanel(
            size: CGSize(width: size.width - 42, height: footerHeight),
            stroke: feedbackColor ?? Palette.textSecondary,
            fill: Palette.panel.withAlphaComponent(0.92),
            cornerRadius: 24
        )
        footerPanel.position = CGPoint(x: size.width / 2, y: footerY)
        addChild(footerPanel)

        let footerText = makeLabel(
            text: feedbackMessage ?? profile.defaultStoreFeedback,
            fontNamed: GameConfig.coinFont,
            fontSize: 11,
            color: feedbackColor ?? Palette.textSecondary,
            width: footerPanel.frame.width - 40,
            lines: 2
        )
        footerText.horizontalAlignmentMode = .left
        footerText.position = CGPoint(x: -footerPanel.frame.width / 2 + 18, y: 12)
        footerPanel.addChild(footerText)

        // ── 5. Back button ───────────────────────────────────────────
        let backButton = MenuButtonNode(actionID: "back", title: "Volver", subtitle: "Menu", size: CGSize(width: 136, height: backButtonHeight))
        backButton.position = CGPoint(x: size.width - 90, y: bottomInset + backButtonHeight / 2 + 4)
        addChild(backButton)
    }

    // MARK: - Tab helpers

    private func tabTitleList(for gameMode: GameMode, sections: [StoreSection]) -> [String] {
        if gameMode == .original {
            return ["MEJORAS"]
        }
        return sections.map { section in
            switch section.kind {
            case .character:
                "PERSONAJES"
            case .weapon:
                "ARMAS"
            case .ability:
                "HABILIDADES"
            case .upgrade:
                "MEJORAS"
            }
        }
    }

    private func sectionForTab(_ tabIndex: Int, gameMode: GameMode, sections: [StoreSection]) -> StoreSection? {
        if gameMode == .original {
            return sections.first
        }
        guard tabIndex >= 0, tabIndex < sections.count else {
            return nil
        }
        return sections[tabIndex]
    }

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard maxContentScrollOffset > 0, let location = touches.first?.location(in: self) else {
            return
        }
        guard contentViewportRect.contains(location) else {
            return
        }
        contentTouchStart = location
        contentScrollStartOffset = contentScrollOffset
        isDraggingContent = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let start = contentTouchStart, let location = touches.first?.location(in: self) else {
            return
        }

        let verticalDelta = start.y - location.y
        if abs(verticalDelta) > 8 {
            isDraggingContent = true
        }
        contentScrollOffset = min(max(contentScrollStartOffset + verticalDelta, 0), maxContentScrollOffset)
        contentNode?.position = CGPoint(x: 0, y: contentScrollOffset)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else {
            return
        }

        defer {
            contentTouchStart = nil
            contentScrollStartOffset = contentScrollOffset
            isDraggingContent = false
        }

        if isDraggingContent {
            return
        }

        if let button = button(at: location), button.actionID == "back" {
            soundManager.playButtonTap()
            hapticsManager.tap()
            guard let gameMode else {
                return
            }
            present(MainMenuScene(sceneSize: size, gameMode: gameMode))
            return
        }

        // Tab taps
        if let tabName = nodeName(at: location, withPrefix: "store.tab.") {
            let indexString = String(tabName.dropFirst("store.tab.".count))
            if let tappedIndex = Int(indexString), tappedIndex != currentTabIndex {
                soundManager.playButtonTap()
                hapticsManager.tap()
                currentTabIndex = tappedIndex
                contentScrollOffset = 0
                feedbackMessage = nil
                feedbackColor = nil
                buildScene()
            }
            return
        }

        if nodeName(at: location, withPrefix: "store.premium.restore") != nil {
            handleRestoreTap()
            return
        }

        if nodeName(at: location, withPrefix: "store.premium.evolution") != nil {
            handlePremiumTap()
            return
        }

        guard let itemName = nodeName(at: location, withPrefix: "store.item.") else {
            return
        }

        let itemID = String(itemName.dropFirst("store.item.".count))
        let result: PurchaseResult
        if let upgrade = OriginalUpgrade(rawValue: itemID) {
            result = storeManager.purchaseOriginalUpgrade(upgrade)
        } else if let character = CharacterDefinition.catalog.first(where: { $0.id == itemID }) {
            result = storeManager.purchaseCharacter(id: character.id)
        } else if let weapon = WeaponType(rawValue: itemID) {
            guard let gameMode else {
                return
            }
            result = storeManager.purchaseWeapon(weapon, for: gameMode)
        } else if let ability = AbilityType(rawValue: itemID) {
            result = storeManager.purchaseAbility(ability)
        } else {
            return
        }

        progress = saveManager.loadProgress()
        showFeedback(for: result, itemID: itemID)
        switch result {
        case .purchased, .equipped:
            soundManager.playSuccess()
            hapticsManager.success()
        case .alreadyOwned, .insufficientFunds, .unavailable:
            soundManager.playWarning()
            hapticsManager.warning()
        }
        buildScene()
    }

    // MARK: - Premium handling

    private func handlePremiumTap() {
        guard !isPerformingPremiumAction else {
            return
        }

        if progress.evolutionUnlocked {
            soundManager.playWarning()
            hapticsManager.warning()
            feedbackMessage = "Evolution ya esta activo en este dispositivo."
            feedbackColor = Palette.stroke
            buildScene()
            return
        }

        if progress.coins >= StoreManager.evolutionUnlockCoinCost {
            let result = storeManager.purchaseEvolutionUnlock()
            progress = saveManager.loadProgress()
            showFeedback(for: result, itemID: "premium.evolution.coins")
            soundManager.playSuccess()
            hapticsManager.success()
            buildScene()
            return
        }

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            self.isPerformingPremiumAction = true
            self.feedbackMessage = "Abriendo compra segura con App Store..."
            self.feedbackColor = Palette.warning
            self.buildScene()
            let result = await self.purchaseManager.purchaseEvolutionUnlock()
            self.isPerformingPremiumAction = false
            self.progress = self.saveManager.loadProgress()
            self.showPremiumFeedback(for: result)
            switch result {
            case .success, .restored:
                self.soundManager.playSuccess()
                self.hapticsManager.success()
            case .pending, .unavailable:
                self.soundManager.playWarning()
                self.hapticsManager.warning()
            case .cancelled, .failed:
                self.soundManager.playButtonTap()
                self.hapticsManager.tap()
            }
            self.buildScene()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        contentTouchStart = nil
        contentScrollStartOffset = contentScrollOffset
        isDraggingContent = false
    }

    private func handleRestoreTap() {
        guard !isPerformingPremiumAction else {
            return
        }

        soundManager.playButtonTap()
        hapticsManager.tap()
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            self.isPerformingPremiumAction = true
            self.feedbackMessage = "Buscando compras restaurables..."
            self.feedbackColor = Palette.warning
            self.buildScene()
            let result = await self.purchaseManager.restorePurchases()
            self.isPerformingPremiumAction = false
            self.progress = self.saveManager.loadProgress()
            self.showPremiumFeedback(for: result)
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
    }

    // MARK: - Premium card

    private func premiumEvolutionCard() -> SKShapeNode {
        let card = makePanel(
            size: CGSize(width: size.width - 42, height: 92),
            stroke: progress.evolutionUnlocked ? Palette.stroke : Palette.warning,
            fill: progress.evolutionUnlocked ? Palette.stroke.withAlphaComponent(0.14) : Palette.panel
        )
        card.name = "store.premium.evolution"

        let badge = makeBadge(text: "UPGRADE MAYOR", tint: progress.evolutionUnlocked ? Palette.stroke : Palette.warning)
        badge.position = CGPoint(x: -card.frame.width / 2 + 92, y: 20)
        card.addChild(badge)

        let premiumGlyph = iconBadge(symbol: "E", tint: progress.evolutionUnlocked ? Palette.stroke : Palette.warning)
        premiumGlyph.position = CGPoint(x: card.frame.width / 2 - 34, y: 20)
        card.addChild(premiumGlyph)

        let title = makeLabel(
            text: "Evolution Premium",
            fontNamed: GameConfig.titleFont,
            fontSize: 20,
            color: Palette.textPrimary,
            width: card.frame.width - 162,
            lines: 1
        )
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -card.frame.width / 2 + 18, y: -2)
        card.addChild(title)

        let subtitle = makeLabel(
            text: premiumSubtitleText,
            fontNamed: GameConfig.coinFont,
            fontSize: 11,
            color: Palette.textSecondary,
            width: card.frame.width - 174,
            lines: 2
        )
        subtitle.horizontalAlignmentMode = .left
        subtitle.position = CGPoint(x: -card.frame.width / 2 + 18, y: -24)
        card.addChild(subtitle)

        let status = makeLabel(
            text: premiumStatusText,
            fontNamed: GameConfig.coinFont,
            fontSize: 10,
            color: progress.evolutionUnlocked ? Palette.stroke : Palette.warning,
            width: 118,
            lines: 3
        )
        status.position = CGPoint(x: card.frame.width / 2 - 70, y: 12)
        card.addChild(status)

        let restore = makeLabel(
            text: isPerformingPremiumAction ? "Procesando..." : "Restaurar",
            fontNamed: GameConfig.coinFont,
            fontSize: 10,
            color: isPerformingPremiumAction ? Palette.textSecondary : Palette.stroke,
            width: 84,
            lines: 1
        )
        restore.name = "store.premium.restore"
        restore.position = CGPoint(x: card.frame.width / 2 - 70, y: -32)
        card.addChild(restore)

        return card
    }

    // MARK: - Store card

    private func storeCard(for item: StoreItem, gameMode: GameMode, section: StoreSectionKind, cardWidth: CGFloat? = nil) -> SKShapeNode {
        let width = cardWidth ?? (self.size.width - 58) / 2
        let cardSize = CGSize(width: width, height: 82)
        let card = makePanel(
            size: cardSize,
            stroke: item.strokeColor(progress: progress, gameMode: gameMode, storeManager: storeManager),
            fill: item.fillColor(progress: progress, gameMode: gameMode, storeManager: storeManager),
            cornerRadius: 22
        )
        card.name = "store.item.\(item.id)"

        let badge = makeBadge(text: section.badgeText, tint: item.tint)
        badge.setScale(0.68)
        badge.position = CGPoint(x: -cardSize.width / 2 + 52, y: 18)
        card.addChild(badge)

        let icon = iconBadge(symbol: item.symbol, tint: item.tint)
        icon.position = CGPoint(x: cardSize.width / 2 - 22, y: 18)
        icon.setScale(0.7)
        card.addChild(icon)

        let title = makeLabel(
            text: item.title,
            fontNamed: GameConfig.titleFont,
            fontSize: 14,
            color: Palette.textPrimary,
            width: cardSize.width - 28,
            lines: 1
        )
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -cardSize.width / 2 + 12, y: -2)
        card.addChild(title)

        let subtitle = makeLabel(
            text: item.subtitle,
            fontNamed: GameConfig.coinFont,
            fontSize: 9,
            color: Palette.textSecondary,
            width: cardSize.width - 28,
            lines: 2
        )
        subtitle.horizontalAlignmentMode = .left
        subtitle.position = CGPoint(x: -cardSize.width / 2 + 12, y: -18)
        card.addChild(subtitle)

        let status = makeLabel(
            text: item.statusText(progress: progress, gameMode: gameMode),
            fontNamed: GameConfig.coinFont,
            fontSize: 10,
            color: item.statusColor(progress: progress, gameMode: gameMode),
            width: cardSize.width - 44,
            lines: 1
        )
        status.horizontalAlignmentMode = .left
        status.position = CGPoint(x: -cardSize.width / 2 + 12, y: -44)
        card.addChild(status)

        return card
    }

    // MARK: - Feedback

    private func showFeedback(for result: PurchaseResult, itemID: String) {
        switch result {
        case .purchased:
            feedbackMessage = "Compra realizada: \(itemTitle(for: itemID))."
            feedbackColor = Palette.success
        case .equipped:
            feedbackMessage = "Equipado: \(itemTitle(for: itemID))."
            feedbackColor = Palette.stroke
        case .alreadyOwned:
            feedbackMessage = "\(itemTitle(for: itemID)) ya esta disponible."
            feedbackColor = Palette.warning
        case .insufficientFunds:
            feedbackMessage = "No tienes monedas suficientes para \(itemTitle(for: itemID))."
            feedbackColor = Palette.danger
        case .unavailable:
            feedbackMessage = "Elemento no disponible."
            feedbackColor = Palette.danger
        }
    }

    private func showPremiumFeedback(for result: PurchaseManager.ActionResult) {
        switch result {
        case .success:
            feedbackMessage = "Compra completada. Evolution ya esta desbloqueado."
            feedbackColor = Palette.success
        case .restored:
            feedbackMessage = "Compras restauradas. Evolution ya esta disponible."
            feedbackColor = Palette.success
        case .pending:
            feedbackMessage = "Compra pendiente. Apple confirmara el pago en cuanto pueda."
            feedbackColor = Palette.warning
        case .cancelled:
            feedbackMessage = "Compra cancelada."
            feedbackColor = Palette.textSecondary
        case .unavailable:
            feedbackMessage = "El producto premium aun no esta disponible en App Store Connect."
            feedbackColor = Palette.warning
        case let .failed(message):
            feedbackMessage = "No se pudo completar la compra: \(message)"
            feedbackColor = Palette.danger
        }
    }

    // MARK: - Helpers

    private func itemTitle(for itemID: String) -> String {
        if let character = CharacterDefinition.catalog.first(where: { $0.id == itemID }) {
            return character.title
        }
        if let upgrade = OriginalUpgrade(rawValue: itemID) {
            return upgrade.title
        }
        if let weapon = WeaponType(rawValue: itemID) {
            return weapon.title
        }
        if let ability = AbilityType(rawValue: itemID) {
            return ability.title
        }
        if itemID == "premium.evolution.coins" {
            return "Evolution"
        }
        return "Elemento"
    }

    private func storeSections(for gameMode: GameMode, profile: GameModeProfile) -> [StoreSection] {
        if gameMode == .original {
            return [
                StoreSection(
                    title: "MEJORAS PERMANENTES",
                    subtitle: "Ajustes discretos para exprimir runs clasicas sin romper el arcade.",
                    kind: .upgrade,
                    items: OriginalUpgrade.allCases.map { .originalUpgrade($0) }
                )
            ]
        }

        var sections: [StoreSection] = [
            StoreSection(
                title: "PERSONAJES",
                subtitle: "Cada uno cambia ritmo, magnetismo y lectura de combate.",
                kind: .character,
                items: CharacterDefinition.catalog.map { .character($0) }
            ),
            StoreSection(
                title: "ARMAS",
                subtitle: "Compra y equipa la pieza que define la build.",
                kind: .weapon,
                items: WeaponType.allCases.map { .weapon($0) }
            )
        ]
        if profile.showsAbilitiesInStore {
            sections.append(
                StoreSection(
                    title: "HABILIDADES",
                    subtitle: "Pulso, escudo, overdrive y utilidades para runs mas agresivas.",
                    kind: .ability,
                    items: AbilityType.allCases.map { .ability($0) }
                )
            )
        }
        return sections
    }

    private func currentLoadoutSummary(for gameMode: GameMode) -> String {
        switch gameMode {
        case .original:
            return progress.evolutionUnlocked
                ? "Evolution abierto. Puedes salir del arcade base cuando quieras."
                : "Clasico puro. Aqui compras mejoras retro o el salto a Evolution."
        case .evolution, .ghost:
            let character = CharacterDefinition.definition(for: progress.selectedCharacterID(for: gameMode))
            return "Carga activa: \(character.title) + \(progress.selectedWeapon(for: gameMode).title)"
        }
    }

    private var premiumSubtitleText: String {
        if progress.evolutionUnlocked {
            return "Ya disponible. Modo moderno desbloqueado."
        }
        return "Compra por \(purchaseManager.evolutionPriceText) o desbloquea con \(StoreManager.evolutionUnlockCoinCost) monedas."
    }

    private var premiumStatusText: String {
        if isPerformingPremiumAction {
            return "Esperando confirmacion de StoreKit."
        }
        if progress.evolutionUnlocked {
            return "Activo"
        }
        if progress.coins >= StoreManager.evolutionUnlockCoinCost {
            return "Pulsa para desbloquear con monedas."
        }
        return purchaseManager.hasLoadedProducts ? "Comprar en App Store o seguir ahorrando." : "Cargando producto..."
    }

    private func installPurchaseObserver() {
        guard purchaseObserver == nil else {
            return
        }
        purchaseObserver = NotificationCenter.default.addObserver(
            forName: .purchaseManagerDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else {
                    return
                }
                self.progress = self.saveManager.loadProgress()
                self.buildScene()
            }
        }
    }

    private func makePanel(size: CGSize, stroke: UIColor, fill: UIColor, cornerRadius: CGFloat = 28) -> SKShapeNode {
        let panel = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        panel.fillColor = fill
        panel.strokeColor = stroke
        panel.lineWidth = 2
        return panel
    }

    private func makeBadge(text: String, tint: UIColor) -> SKShapeNode {
        let badge = SKShapeNode(rectOf: CGSize(width: 132, height: 28), cornerRadius: 14)
        badge.fillColor = tint.withAlphaComponent(0.14)
        badge.strokeColor = tint
        badge.lineWidth = 1.5

        let label = makeLabel(
            text: text,
            fontNamed: GameConfig.coinFont,
            fontSize: 11,
            color: tint,
            width: 116,
            lines: 1
        )
        label.position = CGPoint(x: 0, y: 8)
        badge.addChild(label)
        return badge
    }

    private func makeSectionHeader(title: String, subtitle: String, y: CGFloat) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: size.width / 2, y: y)

        let titleNode = makeLabel(
            text: title,
            fontNamed: GameConfig.titleFont,
            fontSize: 16,
            color: Palette.textPrimary,
            width: size.width - 48,
            lines: 1
        )
        titleNode.position = CGPoint(x: 0, y: 4)
        container.addChild(titleNode)

        let subtitleNode = makeLabel(
            text: subtitle,
            fontNamed: GameConfig.coinFont,
            fontSize: 10,
            color: Palette.textSecondary,
            width: size.width - 48,
            lines: 1
        )
        subtitleNode.position = CGPoint(x: 0, y: -12)
        container.addChild(subtitleNode)

        return container
    }

    private func iconBadge(symbol: String, tint: UIColor) -> SKShapeNode {
        let badge = SKShapeNode(rectOf: CGSize(width: 30, height: 30), cornerRadius: 11)
        badge.fillColor = tint.withAlphaComponent(0.14)
        badge.strokeColor = tint.withAlphaComponent(0.65)
        badge.lineWidth = 1.2

        let label = makeLabel(
            text: symbol,
            fontNamed: GameConfig.titleFont,
            fontSize: 14,
            color: tint,
            width: 22,
            lines: 1
        )
        label.position = CGPoint(x: 0, y: 9)
        badge.addChild(label)
        return badge
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

    private func itemsByRows(_ items: [StoreItem], columns: Int) -> [[StoreItem]] {
        stride(from: 0, to: items.count, by: columns).map { start in
            Array(items[start..<min(start + columns, items.count)])
        }
    }
}

// MARK: - Private types

private struct StoreSection {
    let title: String
    let subtitle: String
    let kind: StoreSectionKind
    let items: [StoreItem]
}

private enum StoreSectionKind {
    case character
    case weapon
    case ability
    case upgrade

    var badgeText: String {
        switch self {
        case .character:
            "PERSONAJE"
        case .weapon:
            "ARMA"
        case .ability:
            "SKILL"
        case .upgrade:
            "RETRO"
        }
    }
}

private enum StoreItem {
    case character(CharacterDefinition)
    case weapon(WeaponType)
    case ability(AbilityType)
    case originalUpgrade(OriginalUpgrade)

    var id: String {
        switch self {
        case let .character(character):
            character.id
        case let .weapon(weapon):
            weapon.rawValue
        case let .ability(ability):
            ability.rawValue
        case let .originalUpgrade(upgrade):
            upgrade.rawValue
        }
    }

    var title: String {
        switch self {
        case let .character(character):
            character.title
        case let .weapon(weapon):
            weapon.title
        case let .ability(ability):
            ability.title
        case let .originalUpgrade(upgrade):
            upgrade.title
        }
    }

    var subtitle: String {
        switch self {
        case let .character(character):
            character.subtitle
        case let .weapon(weapon):
            "\(weapon.subtitle) Para Stickman y resto del modo evolucion."
        case let .ability(ability):
            ability.description
        case let .originalUpgrade(upgrade):
            upgrade.subtitle
        }
    }

    var tint: UIColor {
        switch self {
        case let .character(character):
            character.primaryColor
        case .weapon:
            Palette.stroke
        case .ability:
            Palette.accent
        case let .originalUpgrade(upgrade):
            upgrade.tint
        }
    }

    var symbol: String {
        switch self {
        case let .character(character):
            switch character.style {
            case .circle:
                return "O"
            case .stickman:
                return "Y"
            case .diamond:
                return "<>"
            }
        case .weapon:
            return "/"
        case .ability:
            return "*"
        case .originalUpgrade:
            return "+"
        }
    }

    func statusText(progress: GameProgress, gameMode: GameMode) -> String {
        switch self {
        case let .character(character):
            if progress.unlockedCharacters.contains(character.id) {
                return "Comprado"
            }
            return "\(character.price) monedas"
        case let .weapon(weapon):
            if progress.selectedWeapon(for: gameMode) == weapon {
                return "Equipada"
            }
            if progress.ownedWeapons.contains(weapon) {
                return "Comprada"
            }
            return "\(weapon.price) monedas"
        case let .ability(ability):
            if progress.ownedAbilities.contains(ability) {
                return "Comprado"
            }
            return "\(ability.price) monedas"
        case let .originalUpgrade(upgrade):
            if progress.ownedOriginalUpgrades.contains(upgrade) {
                return "Comprado"
            }
            return "\(upgrade.price) monedas"
        }
    }

    func statusColor(progress: GameProgress, gameMode: GameMode) -> UIColor {
        switch self {
        case let .character(character):
            return progress.unlockedCharacters.contains(character.id) ? Palette.success : Palette.warning
        case let .weapon(weapon):
            if progress.selectedWeapon(for: gameMode) == weapon {
                return Palette.stroke
            }
            return progress.ownedWeapons.contains(weapon) ? Palette.success : Palette.warning
        case let .ability(ability):
            return progress.ownedAbilities.contains(ability) ? Palette.success : Palette.warning
        case let .originalUpgrade(upgrade):
            return progress.ownedOriginalUpgrades.contains(upgrade) ? Palette.success : Palette.warning
        }
    }

    func fillColor(progress: GameProgress, gameMode: GameMode, storeManager: StoreManager) -> UIColor {
        switch self {
        case let .character(character):
            if progress.unlockedCharacters.contains(character.id) {
                return character.primaryColor.withAlphaComponent(0.16)
            }
            return storeManager.canAffordCharacter(id: character.id, progress: progress) ? Palette.panel : Palette.panel.withAlphaComponent(0.6)
        case let .weapon(weapon):
            if progress.selectedWeapon(for: gameMode) == weapon {
                return Palette.stroke.withAlphaComponent(0.18)
            }
            if progress.ownedWeapons.contains(weapon) {
                return Palette.success.withAlphaComponent(0.14)
            }
            return storeManager.canAffordWeapon(weapon, progress: progress) ? Palette.panel : Palette.panel.withAlphaComponent(0.6)
        case let .ability(ability):
            if progress.ownedAbilities.contains(ability) {
                return Palette.accent.withAlphaComponent(0.14)
            }
            return storeManager.canAffordAbility(ability, progress: progress) ? Palette.panel : Palette.panel.withAlphaComponent(0.6)
        case let .originalUpgrade(upgrade):
            if progress.ownedOriginalUpgrades.contains(upgrade) {
                return upgrade.tint.withAlphaComponent(0.14)
            }
            return storeManager.canAffordOriginalUpgrade(upgrade, progress: progress) ? Palette.panel : Palette.panel.withAlphaComponent(0.6)
        }
    }

    func strokeColor(progress: GameProgress, gameMode: GameMode, storeManager: StoreManager) -> UIColor {
        switch self {
        case let .character(character):
            if progress.unlockedCharacters.contains(character.id) {
                return Palette.success
            }
            return storeManager.canAffordCharacter(id: character.id, progress: progress) ? character.primaryColor : Palette.textSecondary
        case let .weapon(weapon):
            if progress.selectedWeapon(for: gameMode) == weapon {
                return Palette.stroke
            }
            if progress.ownedWeapons.contains(weapon) {
                return Palette.success
            }
            return storeManager.canAffordWeapon(weapon, progress: progress) ? Palette.stroke : Palette.textSecondary
        case let .ability(ability):
            if progress.ownedAbilities.contains(ability) {
                return Palette.success
            }
            return storeManager.canAffordAbility(ability, progress: progress) ? Palette.accent : Palette.textSecondary
        case let .originalUpgrade(upgrade):
            if progress.ownedOriginalUpgrades.contains(upgrade) {
                return Palette.success
            }
            return storeManager.canAffordOriginalUpgrade(upgrade, progress: progress) ? upgrade.tint : Palette.textSecondary
        }
    }
}
