// HapticFeedback.swift
// Centralized wrapper around UIKit haptic generators for consistent feedback.

#if canImport(UIKit)
import UIKit
#endif
#if os(watchOS)
import WatchKit
#endif

@MainActor
public enum HapticFeedback {
    public static func light() {
#if canImport(UIKit) && os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#elseif os(watchOS)
        WKInterfaceDevice.current().play(.click)
#endif
    }

    public static func medium() {
#if canImport(UIKit) && os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#elseif os(watchOS)
        WKInterfaceDevice.current().play(.directionUp)
#endif
    }

    public static func heavy() {
#if canImport(UIKit) && os(iOS)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
#elseif os(watchOS)
        WKInterfaceDevice.current().play(.failure)
#endif
    }

    public static func success() {
#if canImport(UIKit) && os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
#elseif os(watchOS)
        WKInterfaceDevice.current().play(.success)
#endif
    }

    public static func warning() {
#if canImport(UIKit) && os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
#elseif os(watchOS)
        WKInterfaceDevice.current().play(.retry)
#endif
    }
}
