//
//  InAppBanner.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 11/11/26.
//

import UIKit

/// A notification-style banner that slides down from the top when a
/// message arrives for a chat that isn't open. Tap to open, swipe up to hide.
final class InAppBanner: UIView {

    // MARK: - Properties

    private static weak var currentBanner: InAppBanner?

    private let onTap: () -> Void

    // MARK: - UI Components

    private let blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        return view
    }()

    private let avatarView = AvatarView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    // MARK: - Show

    static func show(
        from user: User,
        message: String,
        in window: UIWindow,
        onTap: @escaping () -> Void
    ) {

        currentBanner?.hide()

        let banner = InAppBanner(onTap: onTap)
        banner.avatarView.configure(with: user, showsOnlineStatus: false)
        banner.titleLabel.text = user.displayName
        banner.messageLabel.text = message

        window.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 4),
            banner.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 12),
            banner.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -12)
        ])

        window.layoutIfNeeded()

        banner.transform = CGAffineTransform(translationX: 0, y: -(banner.frame.maxY + 20))

        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5
        ) {
            banner.transform = .identity
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        currentBanner = banner

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak banner] in
            banner?.hide()
        }
    }

    // MARK: - Init

    private init(onTap: @escaping () -> Void) {
        self.onTap = onTap
        super.init(frame: .zero)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension InAppBanner {

    func setupUI() {

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 4)

        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 2

        addSubview(blurView)

        [avatarView, labelsStack].forEach {
            blurView.contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        blurView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            avatarView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 12),
            avatarView.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),

            labelsStack.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 12),
            labelsStack.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -12),
            labelsStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            labelsStack.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -12),

            heightAnchor.constraint(greaterThanOrEqualToConstant: 64)
        ])

        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tapped))
        )

        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipedUp))
        swipeUp.direction = .up
        addGestureRecognizer(swipeUp)
    }

    @objc
    func tapped() {
        hide()
        onTap()
    }

    @objc
    func swipedUp() {
        hide()
    }

    func hide() {

        guard superview != nil else { return }

        UIView.animate(withDuration: 0.25) {
            self.transform = CGAffineTransform(translationX: 0, y: -(self.frame.maxY + 20))
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
}
