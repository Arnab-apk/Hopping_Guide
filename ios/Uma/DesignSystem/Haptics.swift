// DesignSystem/Haptics.swift — UIImpactFeedbackGenerator wrapper

import UIKit

enum Haptics {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func heavy() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func rigid() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
    static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    static func notifySuccess() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func notifyWarning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func notifyError()   { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}
