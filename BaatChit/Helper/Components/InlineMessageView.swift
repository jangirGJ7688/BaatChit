//
//  InlineMessageView.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/11/26.
//

import UIKit

/// An error or success message shown right inside a form, instead of a
/// pop-up alert.
final class InlineMessageView: UIView {

    enum Style {
        case error
        case success
    }

    // MARK: - UI Components

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        return imageView
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(14, weight: .medium)
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Show / Hide

    func show(
        _ message: String,
        style: Style
    ) {

        let color = style == .error ? Theme.Colors.error : Theme.Colors.success

        iconView.image = UIImage(
            systemName: style == .error ? "exclamationmark.circle.fill" : "checkmark.circle.fill"
        )
        iconView.tintColor = color
        messageLabel.textColor = color
        messageLabel.text = message
        backgroundColor = color.withAlphaComponent(0.1)

        UIView.animate(withDuration: 0.25) {
            self.isHidden = false
            self.alpha = 1
            self.superview?.layoutIfNeeded()
        }

        if style == .error {
            shake()
            Haptics.error()
        } else {
            Haptics.success()
        }
    }

    func hide() {

        guard !isHidden else { return }

        UIView.animate(withDuration: 0.2) {
            self.isHidden = true
            self.alpha = 0
            self.superview?.layoutIfNeeded()
        }
    }
}

private extension InlineMessageView {

    func setupUI() {

        isHidden = true
        alpha = 0
        layer.cornerRadius = Theme.Radius.small

        let stackView = UIStackView(arrangedSubviews: [iconView, messageLabel])
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .center

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14)
        ])
    }
}
