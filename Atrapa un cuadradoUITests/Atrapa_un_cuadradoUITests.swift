//
//  Atrapa_un_cuadradoUITests.swift
//  Atrapa un cuadradoUITests
//
//  Created by Antonio Hermoso on 20/3/26.
//

import XCTest

final class Atrapa_un_cuadradoUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
    }

    /// Selector de modos → Mundo artificial → espera 5 s → captura (útil para revisar logs/UI en CI o local).
    @MainActor
    func testNavigateToArtificialWorldAndWait() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), "La app debería estar en primer plano tras launch")

        let worldLabel = NSPredicate(format: "label CONTAINS[c] %@", "Mundo artificial")
        let worldCard = app.descendants(matching: .any).matching(worldLabel).element(boundBy: 0)
        if worldCard.waitForExistence(timeout: 15) {
            worldCard.tap()
        } else {
            let c = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.64))
            c.tap()
            if !worldCard.waitForExistence(timeout: 3) {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.70)).tap()
            }
        }

        let inWorldPredicate = NSPredicate(format: "label CONTAINS[c] %@", "UITest Pantalla Mundo artificial")
        let inWorld = app.descendants(matching: .any).matching(inWorldPredicate).element(boundBy: 0)
        XCTAssertTrue(inWorld.waitForExistence(timeout: 15), "Tras tocar la tarjeta debería mostrarse Artificial World")

        let idle = XCTestExpectation(description: "espera en mundo")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            idle.fulfill()
        }
        wait(for: [idle], timeout: 8)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "ArtificialWorld_after_5s"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
