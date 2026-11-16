//
//  HomeHeaderView.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 13/11/26.
//

import UIKit

/// Top of the Home screen: greeting, your photo, the "Chats" title,
/// a glass search box and the "Online now" row.
final class HomeHeaderView: UIView {

    // MARK: - Properties

    var onProfileTapped: (() -> Void)?
    var onSearchTextChanged: ((String) -> Void)?

    var onOnlineUserSelected: ((User) -> Void)? {
        get { onlineUsersView.onUserSelected }
        set { onlineUsersView.onUserSelected = newValue }
    }

    // MARK: - UI Components

    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(15, weight: .medium)
        label.textColor = Theme.Colors.secondaryText
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Chats"
        label.font = Theme.Fonts.rounded(36, weight: .heavy)
        label.textColor = .white
        return label
    }()

    private let profileButton = UIButton(type: .custom)

    private let avatarView: AvatarView = {
        let avatarView = AvatarView()
        avatarView.isUserInteractionEnabled = false
        return avatarView
    }()

    private let searchField: UITextField = {
        let textField = UITextField()
        textField.font = Theme.Fonts.rounded(16)
        textField.textColor = .white
        textField.tintColor = Theme.Colors.brand
        textField.backgroundColor = Theme.Colors.fieldBackground
        textField.layer.cornerRadius = Theme.Radius.medium
        textField.layer.borderWidth = 1
        textField.layer.borderColor = Theme.Colors.cardBorder.cgColor
        textField.returnKeyType = .search
        textField.clearButtonMode = .whileEditing
        textField.autocorrectionType = .no
        textField.attributedPlaceholder = NSAttributedString(
            string: "Search chats",
            attributes: [.foregroundColor: Theme.Colors.secondaryText]
        )

        let icon = UIImageView(
            image: UIImage(
                systemName: "magnifyingglass",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
            )
        )
        icon.tintColor = Theme.Colors.secondaryText
        icon.contentMode = .center

        // iOS sizes `leftView` from its constraints, so give the icon a
        // fixed-width container for padding.
        let iconContainer = UIView()
        iconContainer.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 46),
            iconContainer.heightAnchor.constraint(equalToConstant: 20),
            icon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor, constant: 2),
            icon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor)
        ])

        textField.leftView = iconContainer
        textField.leftViewMode = .always

        return textField
    }()

    private let onlineUsersView = OnlineUsersView()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        updateGreeting(name: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(currentUser: User) {

        avatarView.configure(with: currentUser, showsOnlineStatus: false)
        updateGreeting(name: currentUser.displayName)
    }

    /// Hides the row when nobody is online.
    func configure(onlineUsers: [User]) {

        onlineUsersView.configure(with: onlineUsers)
        onlineUsersView.isHidden = onlineUsers.isEmpty
    }

    /// The header's parts, for the entrance animation.
    var animatableViews: [UIView] {
        stackView.arrangedSubviews.filter { !$0.isHidden }
    }
}

private extension HomeHeaderView {

    func setupUI() {

        profileButton.addSubview(avatarView)
        profileButton.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)

        // A thin gradient ring around your photo.
        let profileRing = GradientView()
        profileRing.layer.cornerRadius = 25
        profileRing.clipsToBounds = true
        profileRing.isUserInteractionEnabled = false
        profileButton.insertSubview(profileRing, at: 0)

        let profileGap = UIView()
        profileGap.backgroundColor = Theme.Colors.background
        profileGap.layer.cornerRadius = 23
        profileGap.isUserInteractionEnabled = false
        profileButton.insertSubview(profileGap, aboveSubview: profileRing)

        let titleStack = UIStackView(arrangedSubviews: [greetingLabel, titleLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 2

        let topRow = UIStackView(arrangedSubviews: [titleStack, profileButton])
        topRow.axis = .horizontal
        topRow.alignment = .center

        let topRowContainer = UIView()
        topRowContainer.addSubview(topRow)

        let searchContainer = UIView()
        searchContainer.addSubview(searchField)

        [topRowContainer, searchContainer, onlineUsersView].forEach {
            stackView.addArrangedSubview($0)
        }

        stackView.setCustomSpacing(18, after: topRowContainer)
        stackView.setCustomSpacing(24, after: searchContainer)

        addSubview(stackView)

        [stackView, topRow, searchField, avatarView, profileRing, profileGap].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        searchField.delegate = self

        NSLayoutConstraint.activate([

            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),

            topRow.topAnchor.constraint(equalTo: topRowContainer.topAnchor),
            topRow.bottomAnchor.constraint(equalTo: topRowContainer.bottomAnchor),
            topRow.leadingAnchor.constraint(equalTo: topRowContainer.leadingAnchor, constant: 20),
            topRow.trailingAnchor.constraint(equalTo: topRowContainer.trailingAnchor, constant: -20),

            searchField.topAnchor.constraint(equalTo: searchContainer.topAnchor),
            searchField.bottomAnchor.constraint(equalTo: searchContainer.bottomAnchor),
            searchField.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 20),
            searchField.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -20),
            searchField.heightAnchor.constraint(equalToConstant: 48),

            profileButton.widthAnchor.constraint(equalToConstant: 50),
            profileButton.heightAnchor.constraint(equalToConstant: 50),

            profileRing.topAnchor.constraint(equalTo: profileButton.topAnchor),
            profileRing.leadingAnchor.constraint(equalTo: profileButton.leadingAnchor),
            profileRing.trailingAnchor.constraint(equalTo: profileButton.trailingAnchor),
            profileRing.bottomAnchor.constraint(equalTo: profileButton.bottomAnchor),

            profileGap.centerXAnchor.constraint(equalTo: profileButton.centerXAnchor),
            profileGap.centerYAnchor.constraint(equalTo: profileButton.centerYAnchor),
            profileGap.widthAnchor.constraint(equalToConstant: 46),
            profileGap.heightAnchor.constraint(equalToConstant: 46),

            avatarView.centerXAnchor.constraint(equalTo: profileButton.centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: profileButton.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 42),
            avatarView.heightAnchor.constraint(equalToConstant: 42)
        ])

        onlineUsersView.isHidden = true
    }

    /// "Good morning", "Good afternoon" or "Good evening", with your first name.
    func updateGreeting(name: String?) {

        let hour = Calendar.current.component(.hour, from: Date())

        let greeting: String

        switch hour {
        case 5..<12:
            greeting = "Good morning"
        case 12..<17:
            greeting = "Good afternoon"
        default:
            greeting = "Good evening"
        }

        let firstName = name?
            .split(separator: "@").first?
            .split(separator: " ").first
            .map(String.init)

        greetingLabel.text = firstName.map { "\(greeting), \($0) ✨" } ?? greeting
    }

    @objc
    func profileTapped() {
        Haptics.tap()
        onProfileTapped?()
    }

    @objc
    func searchChanged() {
        onSearchTextChanged?(searchField.text ?? "")
    }
}

// MARK: - UITextFieldDelegate

extension HomeHeaderView: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
