//
//  Theme.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/11/26.
//

import UIKit

/// Colours, fonts and sizes shared by every screen, so the app looks
/// consistent in light and dark mode.
enum Theme {

    // MARK: - Colors

    enum Colors {

        /// The neon brand gradient (violet → blue), used for buttons,
        /// headers, glows and your own message bubbles.
        static let gradientStart = UIColor(hex: 0x8B5CF6)
        static let gradientEnd = UIColor(hex: 0x3B82F6)
        static let gradient = [gradientStart, gradientEnd]

        /// A single colour from the middle of the gradient, for tints.
        static let brand = UIColor(hex: 0x8B7BFF)

        /// Deep navy, the base of every screen.
        static let background = UIColor(hex: 0x08091A)
        static let groupedBackground = background
        static let chatBackground = background

        /// Frosted glass: a see-through white layer with a faint edge.
        static let card = UIColor(white: 1, alpha: 0.06)
        static let cardBorder = UIColor(white: 1, alpha: 0.09)
        static let fieldBackground = UIColor(white: 1, alpha: 0.07)

        static let incomingBubble = UIColor(hex: 0x1C1E33)

        static let secondaryText = UIColor(hex: 0x9097B5)

        static let online = UIColor(hex: 0x34D399)
        static let error = UIColor(hex: 0xF87171)
        static let success = UIColor(hex: 0x34D399)

        /// Pairs for initials avatars; each person always gets the same one.
        static let avatarGradients: [[UIColor]] = [
            [UIColor(hex: 0xF472B6), UIColor(hex: 0x8B5CF6)],
            [UIColor(hex: 0x38BDF8), UIColor(hex: 0x6366F1)],
            [UIColor(hex: 0x34D399), UIColor(hex: 0x0EA5E9)],
            [UIColor(hex: 0xFBBF24), UIColor(hex: 0xF97316)],
            [UIColor(hex: 0xA78BFA), UIColor(hex: 0xEC4899)],
            [UIColor(hex: 0x22D3EE), UIColor(hex: 0x14B8A6)]
        ]
    }

    // MARK: - Fonts

    enum Fonts {

        /// SF Rounded, which gives the app a friendlier look.
        static func rounded(
            _ size: CGFloat,
            weight: UIFont.Weight = .regular
        ) -> UIFont {

            let font = UIFont.systemFont(ofSize: size, weight: weight)

            guard let descriptor = font.fontDescriptor.withDesign(.rounded) else {
                return font
            }

            return UIFont(descriptor: descriptor, size: size)
        }
    }

    // MARK: - Sizes

    enum Radius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 28
    }

    // MARK: - Appearance

    static func applyGlobalAppearance() {

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = Colors.background.withAlphaComponent(0.6)
        appearance.shadowColor = Colors.cardBorder
        appearance.titleTextAttributes = [
            .font: Fonts.rounded(17, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        appearance.largeTitleTextAttributes = [
            .font: Fonts.rounded(34, weight: .bold)
        ]

        // No bar background while a large title is fully showing.
        let scrollEdgeAppearance = appearance.copy()
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.titleTextAttributes = appearance.titleTextAttributes
        scrollEdgeAppearance.largeTitleTextAttributes = appearance.largeTitleTextAttributes

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
    }
}

// MARK: - Haptics

enum Haptics {

    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// MARK: - UIColor

extension UIColor {

    convenience init(
        hex: UInt32,
        alpha: CGFloat = 1
    ) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    static func dynamic(
        light: UIColor,
        dark: UIColor
    ) -> UIColor {

        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}

// MARK: - Animations

extension UIView {

    /// Fades and slides views up into place one after another.
    static func animateEntrance(
        of views: [UIView],
        delay: TimeInterval = 0
    ) {

        views.forEach {
            $0.alpha = 0
            $0.transform = CGAffineTransform(translationX: 0, y: 18)
        }

        for (index, view) in views.enumerated() {

            UIView.animate(
                withDuration: 0.55,
                delay: delay + Double(index) * 0.06,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.4,
                options: [.curveEaseOut, .allowUserInteraction]
            ) {
                view.alpha = 1
                view.transform = .identity
            }
        }
    }

    /// A quick side-to-side shake, used to point at a mistake.
    func shake() {

        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [-10, 10, -7, 7, -4, 4, 0]
        animation.duration = 0.4
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        layer.add(animation, forKey: "shake")
    }

    /// Shrinks slightly while pressed, and springs back when released.
    func animatePress(_ isPressed: Bool) {

        UIView.animate(
            withDuration: isPressed ? 0.1 : 0.35,
            delay: 0,
            usingSpringWithDamping: isPressed ? 1 : 0.5,
            initialSpringVelocity: 0.5,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.transform = isPressed
            ? CGAffineTransform(scaleX: 0.96, y: 0.96)
            : .identity
        }
    }
}
