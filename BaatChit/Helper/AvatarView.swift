//
//  AvatarView.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import UIKit

/// Round profile photo with an optional "online" dot. People without a
/// photo get their initials on a colourful gradient.
final class AvatarView: UIView {

    // MARK: - UI Components

    private let gradientView: GradientView = {
        let view = GradientView()
        view.clipsToBounds = true
        return view
    }()

    private let initialsLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    /// A background-coloured ring around the green dot.
    private let onlineDot: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.background
        view.isHidden = true
        return view
    }()

    private let onlineDotFill: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.online
        return view
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientView.layer.cornerRadius = bounds.width / 2
        imageView.layer.cornerRadius = bounds.width / 2
        initialsLabel.font = Theme.Fonts.rounded(bounds.width * 0.38, weight: .bold)

        onlineDot.layer.cornerRadius = onlineDot.bounds.width / 2
        // The fill isn't laid out yet at this point, so size it from the ring.
        onlineDotFill.layer.cornerRadius = (onlineDot.bounds.width - 4) / 2
    }

    // MARK: - Configure

    func configure(
        with user: User,
        showsOnlineStatus: Bool = true
    ) {

        onlineDot.isHidden = !(showsOnlineStatus && user.isOnline)

        let photo = user.photoCacheKey.flatMap {
            ImageCache.shared.image(forKey: $0, data: user.photoData)
        }

        imageView.image = photo
        imageView.isHidden = photo == nil

        initialsLabel.text = Self.initials(for: user.displayName)
        gradientView.colors = Self.gradient(for: user.uid)
    }
}

private extension AvatarView {

    func setupUI() {

        [gradientView, initialsLabel, imageView, onlineDot].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        onlineDot.addSubview(onlineDotFill)
        onlineDotFill.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate(
            [gradientView, imageView].flatMap {
                [
                    $0.topAnchor.constraint(equalTo: topAnchor),
                    $0.leadingAnchor.constraint(equalTo: leadingAnchor),
                    $0.trailingAnchor.constraint(equalTo: trailingAnchor),
                    $0.bottomAnchor.constraint(equalTo: bottomAnchor)
                ]
            } + [

                initialsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                initialsLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                initialsLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),

                onlineDot.trailingAnchor.constraint(equalTo: trailingAnchor),
                onlineDot.bottomAnchor.constraint(equalTo: bottomAnchor),
                onlineDot.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.3),
                onlineDot.heightAnchor.constraint(equalTo: onlineDot.widthAnchor),

                onlineDotFill.centerXAnchor.constraint(equalTo: onlineDot.centerXAnchor),
                onlineDotFill.centerYAnchor.constraint(equalTo: onlineDot.centerYAnchor),
                onlineDotFill.widthAnchor.constraint(equalTo: onlineDot.widthAnchor, constant: -4),
                onlineDotFill.heightAnchor.constraint(equalTo: onlineDotFill.widthAnchor)
            ]
        )
    }

    /// "Ganpat Jangir" → "GJ", "xyz" → "X", "ravi.k@gmail.com" → "RK".
    static func initials(for name: String) -> String {

        // For an email, only the part before "@" is the person's name.
        let localPart = name.split(separator: "@").first.map(String.init) ?? name

        let words = localPart
            .split(whereSeparator: { $0 == " " || $0 == "." || $0 == "_" })
            .prefix(2)

        let letters = words.compactMap(\.first).map(String.init).joined()

        return letters.isEmpty ? "?" : letters.uppercased()
    }

    /// The same person always gets the same colours. (`hashValue` changes
    /// on every launch, so add up the characters instead.)
    static func gradient(for uid: String) -> [UIColor] {

        let gradients = Theme.Colors.avatarGradients
        let sum = uid.unicodeScalars.reduce(0) { $0 + Int($1.value) }

        return gradients[sum % gradients.count]
    }
}
