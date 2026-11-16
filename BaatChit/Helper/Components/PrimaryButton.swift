//
//  PrimaryButton.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/11/26.
//

import UIKit

/// The main call-to-action button: brand gradient, soft shadow, a press
/// animation, and a spinner while something is loading.
final class PrimaryButton: UIButton {

    // MARK: - Properties

    var isLoading = false {
        didSet {
            guard isLoading != oldValue else { return }

            isUserInteractionEnabled = !isLoading
            titleLabel?.alpha = isLoading ? 0 : 1

            isLoading
            ? spinner.startAnimating()
            : spinner.stopAnimating()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            animatePress(isHighlighted)
        }
    }

    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.5
        }
    }

    // MARK: - UI Components

    private let gradientView: GradientView = {
        let view = GradientView(
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5)
        )
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = Theme.Radius.medium
        view.clipsToBounds = true
        return view
    }()

    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        return spinner
    }()

    // MARK: - Init

    init(title: String) {
        super.init(frame: .zero)

        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = Theme.Fonts.rounded(17, weight: .bold)

        layer.shadowColor = Theme.Colors.gradientEnd.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 8)

        insertSubview(gradientView, at: 0)
        addSubview(spinner)

        gradientView.translatesAutoresizingMaskIntoConstraints = false
        spinner.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),

            heightAnchor.constraint(equalToConstant: 56)
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        // Keep the title above the gradient.
        if let titleLabel = titleLabel {
            bringSubviewToFront(titleLabel)
        }

        bringSubviewToFront(spinner)
    }

    @objc
    private func tapped() {
        Haptics.tap()
    }
}
