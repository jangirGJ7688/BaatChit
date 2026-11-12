//
//  AvatarView.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import UIKit

/// Round profile photo with an optional green "online" dot.
final class AvatarView: UIView {

    // MARK: - Properties

    private let placeholderImage = UIImage(systemName: "person.circle.fill")

    // MARK: - UI Components

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.tintColor = .systemGray3
        return imageView
    }()

    /// A background-coloured ring around the green dot.
    private let onlineDot: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.isHidden = true
        return view
    }()

    private let onlineDotFill: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
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

        imageView.layer.cornerRadius = bounds.width / 2
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

        imageView.image = user.photoCacheKey.flatMap {
            ImageCache.shared.image(forKey: $0, data: user.photoData)
        } ?? placeholderImage
    }
}

private extension AvatarView {

    func setupUI() {

        [imageView, onlineDot].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        onlineDot.addSubview(onlineDotFill)
        onlineDotFill.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            onlineDot.trailingAnchor.constraint(equalTo: trailingAnchor),
            onlineDot.bottomAnchor.constraint(equalTo: bottomAnchor),
            onlineDot.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.28),
            onlineDot.heightAnchor.constraint(equalTo: onlineDot.widthAnchor),

            onlineDotFill.centerXAnchor.constraint(equalTo: onlineDot.centerXAnchor),
            onlineDotFill.centerYAnchor.constraint(equalTo: onlineDot.centerYAnchor),
            onlineDotFill.widthAnchor.constraint(equalTo: onlineDot.widthAnchor, constant: -4),
            onlineDotFill.heightAnchor.constraint(equalTo: onlineDotFill.widthAnchor)
        ])
    }
}
