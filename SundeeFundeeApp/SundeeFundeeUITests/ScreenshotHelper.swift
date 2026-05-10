import XCTest

@MainActor
func setupSnapshot(_ app: XCUIApplication) {
    SnapshotHarness.app = app
}

@MainActor
func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 2) {
    SnapshotHarness.snapshot(name, timeWaitingForIdle: timeout)
}

@MainActor
private enum SnapshotHarness {
    static var app: XCUIApplication?

    static func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval) {
        if timeout > 0 {
            _ = app?.wait(for: .runningForeground, timeout: timeout)
        }

        guard
            let simulatorHome = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"],
            var simulatorName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"]
        else {
            XCTFail("Fastlane snapshot simulator environment is unavailable.")
            return
        }

        simulatorName = simulatorName.replacingOccurrences(
            of: #"Clone \d+ of "#,
            with: "",
            options: .regularExpression
        )

        let screenshotsDirectory = URL(fileURLWithPath: simulatorHome)
            .appendingPathComponent("Library/Caches/tools.fastlane/screenshots", isDirectory: true)

        do {
            try FileManager.default.createDirectory(
                at: screenshotsDirectory,
                withIntermediateDirectories: true
            )
            let screenshot = XCUIScreen.main.screenshot()
            let outputURL = screenshotsDirectory.appendingPathComponent("\(simulatorName)-\(name).png")
            try screenshot.image.pngData()?.write(to: outputURL, options: .atomic)
        } catch {
            XCTFail("Unable to write screenshot \(name): \(error)")
        }
    }
}
