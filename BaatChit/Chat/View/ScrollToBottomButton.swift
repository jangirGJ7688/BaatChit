//
//  ScrollToBottomButton.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/11/26.
//

import UIKit

/// Shown while you're reading older messages. Jumps back to the newest,
/// with a badge counting messages that arrived in the meantime.
final class ScrollToBottomButton: UIButton {

    // MARK: - Properties

    var unreadCount = 0 {
        didSet {
            badgeLabel.text = unreadCount > 99 ? "99+" : "\(unreadCount)"
            badgeView.isHidden = unreadCount == 0
        }
    }

    override var isHighlighted: Bool {
        didSet {
            animatePress(isHighlighted)
        }
    }

    // MARK: - UI Components

    private let blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(
                systemName: "chevron.down",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
            )
        )
        imageView.tintColor = Theme.Colors.brand
        return imageView
    }()

    private let badgeView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.brand
        view.layer.cornerRadius = 10
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(11, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
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

    func setVisible(_ isVisible: Bool) {

        guard isVisible == isHidden else { return }

        if isVisible {
            isHidden = false
        }

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: [.beginFromCurrentState]
        ) {
            self.alpha = isVisible ? 1 : 0
            self.transform = isVisible ? .identity : CGAffineTransform(scaleX: 0.6, y: 0.6)
        } completion: { _ in
            if !isVisible {
                self.isHidden = true
            }
        }
    }
}

private extension ScrollToBottomButton {

    func setupUI() {

        isHidden = true
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.6, y: 0.6)

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 3)

        [blurView, iconView, badgeView].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        badgeView.addSubview(badgeLabel)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            widthAnchor.constraint(equalToConstant: 40),
            heightAnchor.constraint(equalToConstant: 40),

            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1),

            badgeView.centerXAnchor.constraint(equalTo: centerXAnchor),
            badgeView.centerYAnchor.constraint(equalTo: topAnchor),
            badgeView.heightAnchor.constraint(equalToConstant: 20),
            badgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),

            badgeLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 5),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -5),
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor)
        ])
    }
}
