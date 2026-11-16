//
//  AuthHeaderView.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/11/26.
//

import UIKit

/// The gradient header at the top of the login, signup and reset screens,
/// with the app logo, a title and an optional back button.
final class AuthHeaderView: UIView {

    // MARK: - Properties

    var onBack: (() -> Void)?

    /// Height of the status bar area, so the content starts below it.
    var topInset: CGFloat = 0 {
        didSet {
            backButtonTopConstraint?.constant = topInset + 8
            textTopConstraint?.constant = topInset + 64
        }
    }

    private var backButtonTopConstraint: NSLayoutConstraint?
    private var textTopConstraint: NSLayoutConstraint?

    // MARK: - UI Components

    private let gradientView = GradientView()

    private let logoView = LogoBadgeView(size: 64)

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(30, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(16, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.85)
        label.numberOfLines = 0
        return label
    }()

    private let backButton: UIButton = {
        let button = UIButton(type: .system)

        button.setImage(
            UIImage(
                systemName: "chevron.left",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
            ),
            for: .normal
        )

        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 20

        return button
    }()

    // MARK: - Init

    init(
        title: String,
        subtitle: String,
        showsBackButton: Bool = false
    ) {
        super.init(frame: .zero)

        titleLabel.text = title
        subtitleLabel.text = subtitle
        backButton.isHidden = !showsBackButton

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension AuthHeaderView {

    func setupUI() {

        // Rounded only at the bottom.
        gradientView.layer.cornerRadius = Theme.Radius.large
        gradientView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        gradientView.clipsToBounds = true

        // Soft circles for depth.
        let bubbles = [(160, 0.10), (110, 0.08)].map { size, alpha -> UIView in
            let view = UIView()
            view.backgroundColor = UIColor.white.withAlphaComponent(alpha)
            view.layer.cornerRadius = CGFloat(size) / 2
            return view
        }

        let textStack = UIStackView(arrangedSubviews: [logoView, titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 8
        textStack.setCustomSpacing(20, after: logoView)

        addSubview(gradientView)

        (bubbles + [textStack, backButton]).forEach {
            gradientView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        gradientView.translatesAutoresizingMaskIntoConstraints = false

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        let backButtonTopConstraint = backButton.topAnchor.constraint(
            equalTo: gradientView.topAnchor,
            constant: topInset + 8
        )

        let textTopConstraint = textStack.topAnchor.constraint(
            equalTo: gradientView.topAnchor,
            constant: topInset + 64
        )

        self.backButtonTopConstraint = backButtonTopConstraint
        self.textTopConstraint = textTopConstraint

        NSLayoutConstraint.activate([

            gradientView.topAnchor.constraint(equalTo: topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: bottomAnchor),

            bubbles[0].widthAnchor.constraint(equalToConstant: 160),
            bubbles[0].heightAnchor.constraint(equalToConstant: 160),
            bubbles[0].trailingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: 50),
            bubbles[0].topAnchor.constraint(equalTo: gradientView.topAnchor, constant: 30),

            bubbles[1].widthAnchor.constraint(equalToConstant: 110),
            bubbles[1].heightAnchor.constraint(equalToConstant: 110),
            bubbles[1].trailingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: -70),
            bubbles[1].bottomAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: 40),

            backButtonTopConstraint,
            backButton.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            textTopConstraint,
            textStack.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 24),
            textStack.trailingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: -24),
            textStack.bottomAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: -32)
        ])
    }

    @objc
    func backTapped() {
        Haptics.tap()
        onBack?()
    }
}

/// The app logo: the app icon as a rounded square.
final class LogoBadgeView: UIView {

    init(size: CGFloat) {
        super.init(frame: .zero)

        // The app icon, with a soft violet glow behind it.
        layer.shadowColor = Theme.Colors.gradientStart.cgColor
        layer.shadowOpacity = 0.55
        layer.shadowRadius = size * 0.25
        layer.shadowOffset = CGSize(width: 0, height: size * 0.08)

        let iconView = UIImageView(image: UIImage(named: "LaunchLogo"))
        iconView.contentMode = .scaleAspectFit

        addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size),
            heightAnchor.constraint(equalToConstant: size),
            iconView.topAnchor.constraint(equalTo: topAnchor),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconView.trailingAnchor.constraint(equalTo: trailingAnchor),
            iconView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
