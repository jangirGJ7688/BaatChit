//
//  GradientView.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/11/26.
//

import UIKit

/// A view filled with a diagonal gradient (the brand gradient by default).
final class GradientView: UIView {

    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    private var gradientLayer: CAGradientLayer? {
        layer as? CAGradientLayer
    }

    var colors: [UIColor] = [] {
        didSet {
            gradientLayer?.colors = colors.map(\.cgColor)
        }
    }

    // MARK: - Init

    init(
        colors: [UIColor] = Theme.Colors.gradient,
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1)
    ) {
        super.init(frame: .zero)

        self.colors = colors
        gradientLayer?.colors = colors.map(\.cgColor)
        gradientLayer?.startPoint = startPoint
        gradientLayer?.endPoint = endPoint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
