//
//  EmptyStateView.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/11/26.
//

import UIKit

/// A friendly "nothing here yet" message with an icon and an optional button.
final class EmptyStateView: UIView {

    // MARK: - Properties

    var onAction: (() -> Void)?

    // MARK: - UI Components

    private let iconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.brand.withAlphaComponent(0.12)
        view.layer.cornerRadius = 48
        return view
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = Theme.Colors.brand
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(22, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let actionButton = PrimaryButton(title: "")

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 10
        return stackView
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(
        iconName: String,
        title: String,
        message: String,
        actionTitle: String? = nil
    ) {

        iconView.image = UIImage(
            systemName: iconName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 38, weight: .semibold)
        )

        titleLabel.text = title
        messageLabel.text = message

        actionButton.setTitle(actionTitle, for: .normal)
        actionButton.isHidden = actionTitle == nil
    }

    /// Plays the entrance animation (call when the view is shown).
    func animateIn() {
        UIView.animateEntrance(of: stackView.arrangedSubviews.filter { !$0.isHidden })
    }
}

private extension EmptyStateView {

    func setupUI() {

        iconContainer.addSubview(iconView)

        [iconContainer, titleLabel, messageLabel, actionButton].forEach {
            stackView.addArrangedSubview($0)
        }

        stackView.setCustomSpacing(20, after: iconContainer)
        stackView.setCustomSpacing(28, after: messageLabel)

        addSubview(stackView)

        [iconView, iconContainer, stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([

            iconContainer.widthAnchor.constraint(equalToConstant: 96),
            iconContainer.heightAnchor.constraint(equalToConstant: 96),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),

            actionButton.widthAnchor.constraint(equalToConstant: 200),

            stackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -40),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40)
        ])
    }

    @objc
    func actionTapped() {
        onAction?()
    }
}
