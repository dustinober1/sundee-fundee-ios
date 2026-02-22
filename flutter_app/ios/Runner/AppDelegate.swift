import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let legacyMigrationChannelName = "com.sundeefundee.app/legacy_migration"
  private let migrationKeyPrefix = "com.sundeefundee.legacyMigrationComplete"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerLegacyMigrationChannel()
    return didFinish
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func registerLegacyMigrationChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: legacyMigrationChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleLegacyMigration(call: call, result: result)
    }
  }

  private func handleLegacyMigration(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isMigrationComplete":
      guard
        let arguments = call.arguments as? [String: Any],
        let userId = arguments["userId"] as? String,
        !userId.isEmpty
      else {
        result(
          FlutterError(
            code: "missing-user-id",
            message: "Expected a non-empty userId for isMigrationComplete.",
            details: nil
          )
        )
        return
      }

      result(UserDefaults.standard.bool(forKey: migrationKey(for: userId)))

    case "markMigrationComplete":
      guard
        let arguments = call.arguments as? [String: Any],
        let userId = arguments["userId"] as? String,
        !userId.isEmpty
      else {
        result(
          FlutterError(
            code: "missing-user-id",
            message: "Expected a non-empty userId for markMigrationComplete.",
            details: nil
          )
        )
        return
      }

      UserDefaults.standard.set(true, forKey: migrationKey(for: userId))
      result(nil)

    case "readLegacySnapshot":
      guard
        let arguments = call.arguments as? [String: Any],
        let userId = arguments["userId"] as? String,
        !userId.isEmpty
      else {
        result(
          FlutterError(
            code: "missing-user-id",
            message: "Expected a non-empty userId for readLegacySnapshot.",
            details: nil
          )
        )
        return
      }

      do {
        result(try readLegacySnapshot(for: userId))
      } catch {
        result(
          FlutterError(
            code: "snapshot-read-failed",
            message: "Failed to read legacy snapshot.",
            details: String(describing: error)
          )
        )
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func readLegacySnapshot(for userId: String) throws -> [String: Any] {
    for url in candidateSnapshotURLs(for: userId) {
      guard FileManager.default.fileExists(atPath: url.path) else {
        continue
      }

      let data = try Data(contentsOf: url)
      let decoded = try JSONSerialization.jsonObject(with: data)
      guard let snapshot = decoded as? [String: Any] else {
        throw NSError(
          domain: "LegacyMigration",
          code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Snapshot JSON root must be an object."]
        )
      }

      return snapshot
    }

    return defaultSnapshot(for: userId)
  }

  private func candidateSnapshotURLs(for userId: String) -> [URL] {
    let fileManager = FileManager.default
    let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first

    let names = [
      "legacy-migration-\(userId).json",
      "legacy-migration.json",
      "swiftdata-export-\(userId).json",
      "swiftdata-export.json"
    ]

    var urls: [URL] = []
    for name in names {
      if let appSupport {
        urls.append(appSupport.appendingPathComponent(name))
      }
      if let documents {
        urls.append(documents.appendingPathComponent(name))
      }
    }

    return urls
  }

  private func defaultSnapshot(for userId: String) -> [String: Any] {
    return [
      "version": 1,
      "generatedAt": ISO8601DateFormatter().string(from: Date()),
      "userId": userId,
      "source": "empty",
      "metadata": [
        "legacyStoreFiles": legacyStoreFiles()
      ],
      "workouts": [],
      "completedSets": [],
      "cycles": [],
      "maxLifts": [],
      "oneRepMaxes": [],
      "records": [],
      "customPrograms": []
    ]
  }

  private func legacyStoreFiles() -> [String] {
    let fileManager = FileManager.default
    guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      return []
    }

    guard let files = try? fileManager.contentsOfDirectory(
      at: appSupport,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }

    return files
      .filter { $0.pathExtension == "sqlite" || $0.pathExtension == "store" }
      .map { $0.lastPathComponent }
      .sorted()
  }

  private func migrationKey(for userId: String) -> String {
    return "\(migrationKeyPrefix).\(userId)"
  }
}
