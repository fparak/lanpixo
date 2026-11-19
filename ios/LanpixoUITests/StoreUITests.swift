import XCTest

/// Real UI interactions and screenshots; no fabricated network or speed results.
final class StoreUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func capture(_ name: String, _ app: XCUIApplication) {
        // Allow rotation/SwiftUI transitions to settle, then capture the actual
        // screen. app.screenshot() can retain portrait bounds during rotation.
        Thread.sleep(forTimeInterval: 1.5)
        let screenshot = XCUIScreen.main.screenshot()
        if name.contains("landscape") {
            XCTAssertGreaterThan(screenshot.image.size.width, screenshot.image.size.height)
        }
        let image = XCTAttachment(screenshot: screenshot)
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }

    private func tab(_ name: String, app: XCUIApplication) {
        let button = app.buttons[name].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 15), "Missing tab: \(name)")
        XCTAssertTrue(button.isHittable, "Unreachable tab: \(name)")
        button.tap()
    }

    func testEnglishScreensAndRotation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-language", "en", "-theme", "light"]
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        XCTAssertTrue(app.buttons["Scan network"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts["No devices yet"].exists)
        capture("en-01-network-portrait", app)
        tab("Speed", app: app)
        XCTAssertTrue(app.buttons["Start speed test"].waitForExistence(timeout: 10))
        capture("en-02-speed-portrait", app)
        tab("History", app: app)
        XCTAssertTrue(app.staticTexts["No scans yet"].waitForExistence(timeout: 10))
        capture("en-03-history-portrait", app)
        tab("Settings", app: app)
        XCTAssertTrue(app.staticTexts["Language"].waitForExistence(timeout: 10))
        capture("en-04-settings-portrait", app)
        let privacy = app.buttons["Privacy information"].firstMatch
        for _ in 0..<6 {
            if privacy.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(privacy.isHittable)
        privacy.tap()
        XCTAssertTrue(app.navigationBars["Privacy"].waitForExistence(timeout: 10))
        capture("en-05-privacy-portrait", app)
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let bounds = app.windows.firstMatch.frame
            return bounds.width > bounds.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 15), .completed)
        tab("Network", app: app)
        XCTAssertTrue(app.buttons["Scan network"].waitForExistence(timeout: 10))
        capture("en-06-network-landscape", app)
        tab("Speed", app: app)
        XCTAssertTrue(app.buttons["Start speed test"].waitForExistence(timeout: 10))
        capture("en-07-speed-landscape", app)
        app.terminate()
        XCUIDevice.shared.orientation = .portrait
    }

    func testTurkishDarkScreens() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-language", "tr", "-theme", "dark"]
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        XCTAssertTrue(app.buttons["Ağı tara"].waitForExistence(timeout: 30))
        capture("tr-01-network-portrait", app)
        tab("Hız testi", app: app)
        XCTAssertTrue(app.buttons["Hız testini başlat"].waitForExistence(timeout: 10))
        capture("tr-02-speed-portrait", app)
        tab("Geçmiş", app: app)
        XCTAssertTrue(app.staticTexts["Henüz tarama yok"].waitForExistence(timeout: 10))
        capture("tr-03-history-portrait", app)
        tab("Ayarlar", app: app)
        XCTAssertTrue(app.staticTexts["Dil"].waitForExistence(timeout: 10))
        capture("tr-04-settings-portrait", app)
        app.terminate()
    }

    func testAccessibilityTextSize() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-language", "en", "-theme", "light", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["Scan network"].waitForExistence(timeout: 30))
        capture("qa-accessibility-network", app)
        tab("Speed", app: app)
        let start = app.buttons["Start speed test"]
        if !start.isHittable { app.swipeUp() }
        XCTAssertTrue(start.isHittable)
        capture("qa-accessibility-speed", app)
        app.terminate()
    }
}
