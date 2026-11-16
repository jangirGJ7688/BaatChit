//
//  UserCell.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/11/26.
//

import UIKit

/// A person in the New Chat list: photo, name and online status.
final class UserCell: UITableViewCell {

    static let reuseIdentifier = "UserCell"

    // MARK: - UI Components

    private let avatarView = AvatarView()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(17, weight: .semibold)
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(14)
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

    func configure(with user: User) {

        avatarView.configure(with: user)
        nameLabel.text = user.displayName

        if user.isOnline {
            statusLabel.text = "online"
            statusLabel.textColor = Theme.Colors.online
        } else if let lastSeen = user.lastSeen {
            statusLabel.text = "last seen \(lastSeen.lastSeenText)"
            statusLabel.textColor = Theme.Colors.secondaryText
        } else {
            statusLabel.text = user.email
            statusLabel.textColor = Theme.Colors.secondaryText
        }
    }
}

private extension UserCell {

    func setupUI() {

        backgroundColor = .clear

        let selectedView = UIView()
        selectedView.backgroundColor = Theme.Colors.fieldBackground
        selectedBackgroundView = selectedView

        let labelsStack = UIStackView(arrangedSubviews: [nameLabel, statusLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 2

        [avatarView, labelsStack].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([

            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            avatarView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            avatarView.widthAnchor.constraint(equalToConstant: 48),
            avatarView.heightAnchor.constraint(equalToConstant: 48),

            labelsStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 14),
            labelsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            labelsStack.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ])
    }
}
