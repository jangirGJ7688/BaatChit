//
//  ChatListCell.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import UIKit

/// One chat on Home, shown as a frosted-glass card. Chats with unread
/// messages get a glowing edge.
final class ChatListCell: UITableViewCell {

    static let reuseIdentifier = "ChatListCell"

    // MARK: - UI Components

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.card
        view.layer.cornerRadius = 22
        view.layer.borderWidth = 1
        view.layer.borderColor = Theme.Colors.cardBorder.cgColor
        return view
    }()

    private let avatarView = AvatarView()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(17, weight: .semibold)
        label.textColor = .white
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(15)
        label.textColor = Theme.Colors.secondaryText
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(13, weight: .medium)
        label.textColor = Theme.Colors.secondaryText
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let badgeView: GradientView = {
        let view = GradientView()
        view.layer.cornerRadius = 11
        view.clipsToBounds = true
        return view
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(12, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    // MARK: - Init

    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Press Feedback

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        cardView.animatePress(highlighted)

        UIView.animate(withDuration: 0.2) {
            self.cardView.backgroundColor = highlighted
            ? UIColor(white: 1, alpha: 0.11)
            : Theme.Colors.card
        }
    }

    // MARK: - Configure

    func configure(with item: ChatListItem) {

        avatarView.configure(with: item.otherUser)

        nameLabel.text = item.otherUser.displayName
        timeLabel.text = item.lastMessageAt?.chatListText

        let hasUnread = item.unreadCount > 0

        nameLabel.font = Theme.Fonts.rounded(17, weight: hasUnread ? .bold : .semibold)

        if item.isOtherUserTyping {
            messageLabel.text = "typing..."
            messageLabel.textColor = Theme.Colors.brand
            messageLabel.font = Theme.Fonts.rounded(15, weight: .semibold)
        } else {
            messageLabel.text = item.lastMessage
            messageLabel.textColor = hasUnread ? .white : Theme.Colors.secondaryText
            messageLabel.font = Theme.Fonts.rounded(15, weight: hasUnread ? .medium : .regular)
        }

        badgeView.isHidden = !hasUnread
        badgeLabel.text = item.unreadCount > 99 ? "99+" : "\(item.unreadCount)"
        timeLabel.textColor = hasUnread ? Theme.Colors.brand : Theme.Colors.secondaryText

        // Unread chats glow softly.
        cardView.layer.borderColor = hasUnread
        ? Theme.Colors.gradientStart.withAlphaComponent(0.6).cgColor
        : Theme.Colors.cardBorder.cgColor
        cardView.layer.shadowOpacity = hasUnread ? 0.35 : 0
    }
}

private extension ChatListCell {

    func setupUI() {

        backgroundColor = .clear
        selectionStyle = .none

        cardView.layer.shadowColor = Theme.Colors.gradientStart.cgColor
        cardView.layer.shadowRadius = 14
        cardView.layer.shadowOffset = .zero

        contentView.addSubview(cardView)

        [avatarView, nameLabel, messageLabel, timeLabel, badgeView].forEach {
            cardView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        badgeView.addSubview(badgeLabel)

        [cardView, badgeLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([

            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            avatarView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            avatarView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            avatarView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
            avatarView.widthAnchor.constraint(equalToConstant: 54),
            avatarView.heightAnchor.constraint(equalToConstant: 54),

            nameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 5),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),

            timeLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            timeLabel.firstBaselineAnchor.constraint(equalTo: nameLabel.firstBaselineAnchor),

            messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: badgeView.leadingAnchor, constant: -8),

            badgeView.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor),
            badgeView.centerYAnchor.constraint(equalTo: messageLabel.centerYAnchor),
            badgeView.heightAnchor.constraint(equalToConstant: 22),
            badgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 22),

            badgeLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 7),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -7),
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor)
        ])
    }
}
