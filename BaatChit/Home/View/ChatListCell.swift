//
//  ChatListCell.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import UIKit

final class ChatListCell: UITableViewCell {

    static let reuseIdentifier = "ChatListCell"

    // MARK: - UI Components

    private let avatarView = AvatarView()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let badgeView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 10
        return view
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 12)
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

    // MARK: - Configure

    func configure(with item: ChatListItem) {

        avatarView.configure(with: item.otherUser)

        nameLabel.text = item.otherUser.displayName
        timeLabel.text = item.lastMessageAt?.chatListText

        let hasUnread = item.unreadCount > 0

        // Unread chats stand out, like in other chat apps.
        nameLabel.font = .systemFont(ofSize: 17, weight: hasUnread ? .bold : .semibold)

        if item.isOtherUserTyping {
            messageLabel.text = "typing..."
            messageLabel.textColor = .systemBlue
            messageLabel.font = .italicSystemFont(ofSize: 15)
        } else {
            messageLabel.text = item.lastMessage
            messageLabel.textColor = hasUnread ? .label : .secondaryLabel
            messageLabel.font = .systemFont(ofSize: 15, weight: hasUnread ? .medium : .regular)
        }

        badgeView.isHidden = !hasUnread
        badgeLabel.text = item.unreadCount > 99 ? "99+" : "\(item.unreadCount)"
        timeLabel.textColor = hasUnread ? .systemBlue : .secondaryLabel
    }
}

private extension ChatListCell {

    func setupUI() {

        [avatarView, nameLabel, messageLabel, timeLabel, badgeView].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        badgeView.addSubview(badgeLabel)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            avatarView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            avatarView.widthAnchor.constraint(equalToConstant: 52),
            avatarView.heightAnchor.constraint(equalToConstant: 52),

            nameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),

            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.firstBaselineAnchor.constraint(equalTo: nameLabel.firstBaselineAnchor),

            messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: badgeView.leadingAnchor, constant: -8),

            badgeView.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor),
            badgeView.centerYAnchor.constraint(equalTo: messageLabel.centerYAnchor),
            badgeView.heightAnchor.constraint(equalToConstant: 20),
            badgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),

            badgeLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 6),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -6),
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor)
        ])
    }
}
