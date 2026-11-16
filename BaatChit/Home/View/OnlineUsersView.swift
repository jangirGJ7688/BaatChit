//
//  OnlineUsersView.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 13/11/26.
//

import UIKit

/// "Online now": a sideways-scrolling row of people who are online,
/// each with a glowing gradient ring. Tap someone to chat.
final class OnlineUsersView: UIView {

    // MARK: - Properties

    var onUserSelected: ((User) -> Void)?

    private var users: [User] = []

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "ONLINE NOW"
        label.font = Theme.Fonts.rounded(12, weight: .bold)
        label.textColor = Theme.Colors.secondaryText
        return label
    }()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        return scrollView
    }()

    private let itemsStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
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

    func configure(with users: [User]) {

        guard users != self.users else { return }

        self.users = users

        itemsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        users.forEach { user in

            let item = OnlineUserItem(user: user)

            item.addAction(
                UIAction { [weak self] _ in
                    Haptics.tap()
                    self?.onUserSelected?(user)
                },
                for: .touchUpInside
            )

            itemsStack.addArrangedSubview(item)
        }
    }
}

private extension OnlineUsersView {

    func setupUI() {

        [titleLabel, scrollView].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        scrollView.addSubview(itemsStack)
        itemsStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),

            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.heightAnchor.constraint(equalTo: itemsStack.heightAnchor),

            itemsStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            itemsStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            itemsStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            itemsStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
}

/// One person in the row: photo inside a gradient ring, first name below.
private final class OnlineUserItem: UIControl {

    override var isHighlighted: Bool {
        didSet {
            animatePress(isHighlighted)
        }
    }

    init(user: User) {
        super.init(frame: .zero)

        // Gradient ring, a thin navy gap, then the photo.
        let ringView = GradientView()
        ringView.layer.cornerRadius = 33
        ringView.clipsToBounds = true
        ringView.isUserInteractionEnabled = false

        // Soft glow behind the ring (the ring itself has to clip, which
        // would cut off its own shadow).
        let glowView = UIView()
        glowView.backgroundColor = Theme.Colors.gradientStart
        glowView.layer.cornerRadius = 33
        glowView.layer.shadowColor = Theme.Colors.gradientStart.cgColor
        glowView.layer.shadowOpacity = 0.7
        glowView.layer.shadowRadius = 10
        glowView.layer.shadowOffset = .zero
        glowView.isUserInteractionEnabled = false

        let gapView = UIView()
        gapView.backgroundColor = Theme.Colors.background
        gapView.layer.cornerRadius = 30.5
        gapView.isUserInteractionEnabled = false

        let avatarView = AvatarView()
        avatarView.configure(with: user)
        avatarView.isUserInteractionEnabled = false

        let nameLabel = UILabel()
        nameLabel.text = user.displayName.split(separator: " ").first.map(String.init)
        nameLabel.font = Theme.Fonts.rounded(13, weight: .medium)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center

        [glowView, ringView, gapView, avatarView, nameLabel].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([

            widthAnchor.constraint(equalToConstant: 70),

            ringView.topAnchor.constraint(equalTo: topAnchor),
            ringView.centerXAnchor.constraint(equalTo: centerXAnchor),
            ringView.widthAnchor.constraint(equalToConstant: 66),
            ringView.heightAnchor.constraint(equalToConstant: 66),

            glowView.centerXAnchor.constraint(equalTo: ringView.centerXAnchor),
            glowView.centerYAnchor.constraint(equalTo: ringView.centerYAnchor),
            glowView.widthAnchor.constraint(equalTo: ringView.widthAnchor),
            glowView.heightAnchor.constraint(equalTo: ringView.heightAnchor),

            gapView.centerXAnchor.constraint(equalTo: ringView.centerXAnchor),
            gapView.centerYAnchor.constraint(equalTo: ringView.centerYAnchor),
            gapView.widthAnchor.constraint(equalToConstant: 61),
            gapView.heightAnchor.constraint(equalToConstant: 61),

            avatarView.centerXAnchor.constraint(equalTo: ringView.centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: ringView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 56),
            avatarView.heightAnchor.constraint(equalToConstant: 56),

            nameLabel.topAnchor.constraint(equalTo: ringView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
