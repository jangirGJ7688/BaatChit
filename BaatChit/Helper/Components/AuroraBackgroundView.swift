//
//  AuroraBackgroundView.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 13/11/26.
//

import UIKit

/// Deep navy with soft violet and blue glows that slowly drift, giving
/// screens depth instead of a flat background.
final class AuroraBackgroundView: UIView {

    /// One soft glow: a colour, where its centre sits (0–1 of the view)
    /// and how big it is compared to the view's width.
    private struct Glow {
        let color: UIColor
        let center: CGPoint
        let size: CGFloat
    }

    private let glows: [Glow]
    private var glowLayers: [CAGradientLayer] = []

    // MARK: - Init

    /// `intensity` scales how bright the glows are (busy screens like the
    /// chat use a calmer background).
    init(intensity: CGFloat = 1) {
        glows = [
            Glow(
                color: Theme.Colors.gradientStart.withAlphaComponent(0.45 * intensity),
                center: CGPoint(x: 0.05, y: 0.02),
                size: 1.3
            ),
            Glow(
                color: Theme.Colors.gradientEnd.withAlphaComponent(0.35 * intensity),
                center: CGPoint(x: 1, y: 0.18),
                size: 1.1
            ),
            Glow(
                color: UIColor(hex: 0xEC4899).withAlphaComponent(0.14 * intensity),
                center: CGPoint(x: 0.2, y: 1),
                size: 1.2
            )
        ]

        super.init(frame: .zero)

        backgroundColor = Theme.Colors.background
        isUserInteractionEnabled = false
        clipsToBounds = true

        glowLayers = glows.map { glow in
            let layer = CAGradientLayer()
            layer.type = .radial
            layer.colors = [glow.color.cgColor, glow.color.withAlphaComponent(0).cgColor]
            layer.startPoint = CGPoint(x: 0.5, y: 0.5)
            layer.endPoint = CGPoint(x: 1, y: 1)
            self.layer.addSublayer(layer)
            return layer
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        for (glow, layer) in zip(glows, glowLayers) {

            let diameter = bounds.width * glow.size

            layer.bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            layer.position = CGPoint(
                x: bounds.width * glow.center.x,
                y: bounds.height * glow.center.y
            )
        }

        CATransaction.commit()
    }

    // Animations stop when the view leaves the screen, so restart them.
    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil {
            startDrifting()
        }
    }
}

private extension AuroraBackgroundView {

    /// Each glow drifts a little and back, out of step with the others.
    func startDrifting() {

        for (index, layer) in glowLayers.enumerated() {

            layer.removeAnimation(forKey: "drift")

            let offset: CGFloat = index.isMultiple(of: 2) ? 40 : -40

            let animation = CABasicAnimation(keyPath: "transform")
            animation.fromValue = CATransform3DIdentity
            animation.toValue = CATransform3DConcat(
                CATransform3DMakeTranslation(offset, offset * 0.6, 0),
                CATransform3DMakeScale(1.12, 1.12, 1)
            )
            animation.duration = 7 + Double(index) * 2
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            layer.add(animation, forKey: "drift")
        }
    }
}
