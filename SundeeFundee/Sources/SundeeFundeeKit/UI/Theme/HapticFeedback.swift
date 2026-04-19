// HapticFeedback.swift
// Centralized wrapper around UIKit haptic generators for consistent feedback.

#if canImport(UIKit)
import UIKit
#endif

@MainActor
public enum HapticFeedback {
    public static func light() {
#if canImport(UIKit) && os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
    }

    public static func medium() {
#if canImport(UIKit) && os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
    }

    public static func heavy() {
#if canImport(UIKit) && os(iOS)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
#endif
    }

    public static func success() {
#if canImport(UIKit) && os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
#endif
    }

    public static func warning() {
#if canImport(UIKit) && os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
#endif
    }
}
