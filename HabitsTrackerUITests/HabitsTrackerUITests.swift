//
//  HabitsTrackerUITests.swift
//  HabitsTrackerUITests
//
//  Created by Gabriel Nielsen on 2/19/26.
//

import XCTest

final class HabitsTrackerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingIntroducesTheCoreExperience() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-onboardingStateV1", "completed",
            "-uiTestingShowOnboarding"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Build a life that feels like yours."].waitForExistence(timeout: 5))
        app.buttons["See how it feels"].tap()

        XCTAssertTrue(app.staticTexts["Start with what’s next."].waitForExistence(timeout: 2))
        app.buttons["Mark complete"].tap()
        XCTAssertTrue(app.staticTexts["You showed up."].waitForExistence(timeout: 2))
        app.buttons["Keep going"].tap()

        XCTAssertTrue(app.staticTexts["Keep the whole picture."].waitForExistence(timeout: 2))
        app.buttons["Make it yours"].tap()

        XCTAssertTrue(app.staticTexts["What matters right now?"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Productivity, selected"].exists)
        app.buttons["Enter your day"].tap()

        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
