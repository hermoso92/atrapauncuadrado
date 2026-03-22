//
//  ArcadeTelemetryTests.swift
//  Atrapa un cuadradoTests
//

import CoreGraphics
import Foundation
import SpriteKit
import Testing
import UIKit
@testable import AtrapaUnCuadrado

@MainActor
final class TelemetryTestSpy: TelemetryLogging {
    private(set) var events: [(name: String, parameters: [String: String])] = []

    func logEvent(_ name: String, parameters: [String: String]) {
        events.append((name, parameters))
    }

    func reset() {
        events.removeAll()
    }
}

@MainActor
struct ArcadeTelemetryTests {

    private func saveManagerForTelemetryTest(suite: String) -> SaveManager {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return SaveManager(userDefaults: defaults)
    }

    @Test func modeSelectScene_logsArcadeModeSelectShown() {
        let spy = TelemetryTestSpy()
        let saveManager = saveManagerForTelemetryTest(suite: "Atrapa_un_cuadradoTests.telemetry.modeSelect")
        let deps = SceneDependencies(saveManager: saveManager, telemetry: spy)
        let frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let skView = SKView(frame: frame)
        let scene = ModeSelectScene(sceneSize: frame.size, dependencies: deps)
        skView.presentScene(scene)
        let match = spy.events.first { $0.name == "arcade_mode_select_shown" }
        #expect(match != nil)
    }

    @Test func mainMenuScene_logsArcadeMainMenuShownWithMode() {
        let spy = TelemetryTestSpy()
        let saveManager = saveManagerForTelemetryTest(suite: "Atrapa_un_cuadradoTests.telemetry.mainMenu")
        let deps = SceneDependencies(saveManager: saveManager, telemetry: spy)
        let frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let skView = SKView(frame: frame)
        let scene = MainMenuScene(sceneSize: frame.size, gameMode: .evolution, dependencies: deps)
        skView.presentScene(scene)
        let match = spy.events.first { $0.name == "arcade_main_menu_shown" }
        #expect(match != nil)
        #expect(match?.parameters["mode"] == GameMode.evolution.rawValue)
    }

    @Test func gameScene_logsArcadeRunStartedFromHub() {
        let spy = TelemetryTestSpy()
        let previousBridge = ArcadeWorldBridge.returnToArtificialWorldAfterRun
        ArcadeWorldBridge.returnToArtificialWorldAfterRun = false
        defer { ArcadeWorldBridge.returnToArtificialWorldAfterRun = previousBridge }

        let saveManager = saveManagerForTelemetryTest(suite: "Atrapa_un_cuadradoTests.telemetry.runHub")
        let deps = SceneDependencies(saveManager: saveManager, telemetry: spy)
        let frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let skView = SKView(frame: frame)
        let scene = GameScene(sceneSize: frame.size, gameMode: .original, dependencies: deps)
        skView.presentScene(scene)
        let match = spy.events.first { $0.name == "arcade_run_started" }
        #expect(match != nil)
        #expect(match?.parameters["mode"] == GameMode.original.rawValue)
        #expect(match?.parameters["source"] == "hub")
    }

    @Test func gameScene_logsArcadeRunStartedFromWorld() {
        let spy = TelemetryTestSpy()
        let previousBridge = ArcadeWorldBridge.returnToArtificialWorldAfterRun
        ArcadeWorldBridge.returnToArtificialWorldAfterRun = true
        defer { ArcadeWorldBridge.returnToArtificialWorldAfterRun = previousBridge }

        let saveManager = saveManagerForTelemetryTest(suite: "Atrapa_un_cuadradoTests.telemetry.runWorld")
        let deps = SceneDependencies(saveManager: saveManager, telemetry: spy)
        let frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let skView = SKView(frame: frame)
        let scene = GameScene(sceneSize: frame.size, gameMode: .ghost, dependencies: deps)
        skView.presentScene(scene)
        let match = spy.events.first { $0.name == "arcade_run_started" }
        #expect(match != nil)
        #expect(match?.parameters["mode"] == GameMode.ghost.rawValue)
        #expect(match?.parameters["source"] == "world")
    }

    @Test func gameScene_triggerGameOver_logsArcadeRunGameOver() {
        let spy = TelemetryTestSpy()
        let saveManager = saveManagerForTelemetryTest(suite: "Atrapa_un_cuadradoTests.telemetry.gameOver")
        let deps = SceneDependencies(saveManager: saveManager, telemetry: spy)
        let frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let skView = SKView(frame: frame)
        let scene = GameScene(sceneSize: frame.size, gameMode: .original, dependencies: deps)
        skView.presentScene(scene)
        scene.triggerGameOver(force: true)
        let match = spy.events.first { $0.name == "arcade_run_game_over" }
        #expect(match != nil)
        #expect(match?.parameters["mode"] == GameMode.original.rawValue)
        #expect(match?.parameters["score"] == "0")
        #expect(match?.parameters["coins_earned"] == "0")
        #expect(match?.parameters["round"] != nil)
    }
}
