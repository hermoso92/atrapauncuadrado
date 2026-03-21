//
//  Atrapa_un_cuadradoUITests.swift
//  Atrapa un cuadradoUITests
//
//  Created by Antonio Hermoso on 20/3/26.
//

import XCTest

final class Atrapa_un_cuadradoUITests: XCTestCase {

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // Terminate the app before each test so launch performance metrics
        // start from a cold state on every iteration.
        XCUIApplication().terminate()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
