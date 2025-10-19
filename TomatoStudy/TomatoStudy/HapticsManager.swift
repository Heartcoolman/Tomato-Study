import UIKit

final class HapticsManager {
    static let shared = HapticsManager()
    private let generator = UINotificationFeedbackGenerator()

    private init() {}

    func prepare() {
        generator.prepare()
    }

    func success() {
        generator.notificationOccurred(.success)
    }

    func impact() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        impact.impactOccurred()
    }
}
