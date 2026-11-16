//
//  FloatingActionButton.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/11/26.
//

import UIKit

/// A round gradient button that floats above the content.
final class FloatingActionButton: UIButton {

    private let size: CGFloat = 60

    override var isHighlighted: Bool {
        didSet {
            animatePress(isHighlighted)
        }
    }

    private let gradientView: GradientView = {
        let view = GradientView()
        view.isUserInteractionEnabled = false
        view.clipsToBounds = true
        return view
    }()

    // MARK: - Init

    init(systemImageName: String) {
        super.init(frame: .zero)

        setImage(
            UIImage(
                systemName: systemImageName,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
            ),
            for: .normal
        )

        tintColor = .white

        gradientView.layer.cornerRadius = size / 2

        layer.shadowColor = Theme.Colors.gradientEnd.cgColor
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 8)

        insertSubview(gradientView, at: 0)
        gradientView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size),
            heightAnchor.constraint(equalToConstant: size),

            gradientView.topAnchor.constraint(equalTo: topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Keep the icon above the gradient.
        if let imageView = imageView {
            bringSubviewToFront(imageView)
        }
    }

    @objc
    private func tapped() {
        Haptics.tap()
    }
}
