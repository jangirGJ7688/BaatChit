//
//  BubbleView.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 11/11/26.
//

import UIKit

/// A message bubble whose four corners can each have their own radius,
/// so grouped messages look connected.
final class BubbleView: UIView {

    struct CornerRadii: Equatable {
        var topLeft: CGFloat
        var topRight: CGFloat
        var bottomLeft: CGFloat
        var bottomRight: CGFloat

        static func all(_ radius: CGFloat) -> CornerRadii {
            CornerRadii(
                topLeft: radius,
                topRight: radius,
                bottomLeft: radius,
                bottomRight: radius
            )
        }
    }

    // MARK: - Properties

    var cornerRadii = CornerRadii.all(18) {
        didSet {
            if cornerRadii != oldValue {
                setNeedsLayout()
            }
        }
    }

    /// Fills the bubble with a gradient instead of a plain colour.
    var gradientColors: [UIColor]? {
        didSet {
            updateGradient()
        }
    }

    private let maskLayer = CAShapeLayer()
    private var gradientLayer: CAGradientLayer?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.mask = maskLayer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        // No implicit animation, or the shape lags behind during scrolling.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        maskLayer.frame = bounds
        maskLayer.path = makePath(in: bounds).cgPath
        gradientLayer?.frame = bounds
        CATransaction.commit()
    }
}

private extension BubbleView {

    func updateGradient() {

        guard let gradientColors = gradientColors else {
            gradientLayer?.removeFromSuperlayer()
            gradientLayer = nil
            return
        }

        let gradientLayer = self.gradientLayer ?? {
            let layer = CAGradientLayer()
            layer.startPoint = CGPoint(x: 0, y: 0)
            layer.endPoint = CGPoint(x: 1, y: 1)
            self.layer.insertSublayer(layer, at: 0)
            self.gradientLayer = layer
            return layer
        }()

        // Applied instantly, so reused cells don't fade between colours.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.colors = gradientColors.map(\.cgColor)
        gradientLayer.frame = bounds
        CATransaction.commit()
    }

    func makePath(in rect: CGRect) -> UIBezierPath {

        let maxRadius = min(rect.width, rect.height) / 2

        let topLeft = min(cornerRadii.topLeft, maxRadius)
        let topRight = min(cornerRadii.topRight, maxRadius)
        let bottomLeft = min(cornerRadii.bottomLeft, maxRadius)
        let bottomRight = min(cornerRadii.bottomRight, maxRadius)

        let path = UIBezierPath()

        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))

        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight),
            radius: topRight,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight),
            radius: bottomRight,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: true
        )

        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft),
            radius: bottomLeft,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: true
        )

        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft),
            radius: topLeft,
            startAngle: .pi,
            endAngle: 3 * .pi / 2,
            clockwise: true
        )

        path.close()

        return path
    }
}
