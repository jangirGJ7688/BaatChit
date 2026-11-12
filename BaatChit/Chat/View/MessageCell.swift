//
//  MessageCell.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import UIKit

final class MessageCell: UITableViewCell {

    static let reuseIdentifier = "MessageCell"

    // MARK: - Properties

    var onImageTapped: ((UIImage) -> Void)?

    private let largeRadius: CGFloat = 18
    private let smallRadius: CGFloat = 5
    private let imageWidth: CGFloat = 240

    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var topConstraint: NSLayoutConstraint!
    private var imageWidthConstraint: NSLayoutConstraint!
    private var imageHeightConstraint: NSLayoutConstraint!
    private var stackInsetConstraints: [NSLayoutConstraint] = []

    // MARK: - UI Components

    private let bubbleView = BubbleView()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        return stackView
    }()

    private let messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 14
        imageView.backgroundColor = .systemGray5
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 11)
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

    override func prepareForReuse() {
        super.prepareForReuse()

        onImageTapped = nil
        messageImageView.image = nil
    }

    // MARK: - Configure

    func configure(
        with row: MessageRow,
        image: UIImage?
    ) {

        let message = row.message
        let isMine = row.isFromCurrentUser

        messageLabel.text = message.text
        messageLabel.isHidden = message.text.isEmpty
        timeLabel.text = message.sentAt.messageTimeText

        bubbleView.backgroundColor = isMine
        ? .systemBlue
        : .secondarySystemGroupedBackground

        messageLabel.textColor = isMine ? .white : .label
        timeLabel.textColor = isMine
        ? UIColor.white.withAlphaComponent(0.75)
        : .secondaryLabel

        configureStatus(for: message, isMine: isMine)
        configureImage(image, hasImage: message.imageData != nil)
        configureShape(for: row)

        // Deactivate first so both are never active together.
        if isMine {
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
        } else {
            trailingConstraint.isActive = false
            leadingConstraint.isActive = true
        }
    }
}

private extension MessageCell {

    func setupUI() {

        selectionStyle = .none
        backgroundColor = .clear

        // Time and ticks sit at the bottom right of the bubble.
        let spacer = UIView()

        let footerStack = UIStackView(
            arrangedSubviews: [spacer, timeLabel, statusLabel]
        )
        footerStack.axis = .horizontal
        footerStack.spacing = 4

        [messageImageView, messageLabel, footerStack].forEach {
            stackView.addArrangedSubview($0)
        }

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(stackView)

        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        messageImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        )

        leadingConstraint = bubbleView.leadingAnchor.constraint(
            equalTo: contentView.leadingAnchor,
            constant: 12
        )

        trailingConstraint = bubbleView.trailingAnchor.constraint(
            equalTo: contentView.trailingAnchor,
            constant: -12
        )

        topConstraint = bubbleView.topAnchor.constraint(
            equalTo: contentView.topAnchor,
            constant: 6
        )

        stackInsetConstraints = [
            stackView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 7),
            stackView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12)
        ]

        // Below required, so a hidden image collapses without a conflict.
        imageWidthConstraint = messageImageView.widthAnchor.constraint(
            equalToConstant: imageWidth
        )
        imageWidthConstraint.priority = .defaultHigh

        imageHeightConstraint = messageImageView.heightAnchor.constraint(
            equalToConstant: imageWidth
        )
        imageHeightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate(stackInsetConstraints + [

            leadingConstraint,
            topConstraint,

            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -1),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.78),

            stackView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -6)
        ])
    }

    /// Grouped messages get smaller corners on the side they're sent from,
    /// and extra space above the first message of each group.
    func configureShape(for row: MessageRow) {

        topConstraint.constant = row.isFirstInGroup ? 6 : 1

        let top = row.isFirstInGroup ? largeRadius : smallRadius
        let bottom = row.isLastInGroup ? largeRadius : smallRadius

        bubbleView.cornerRadii = row.isFromCurrentUser
        ? BubbleView.CornerRadii(
            topLeft: largeRadius,
            topRight: top,
            bottomLeft: largeRadius,
            bottomRight: bottom
        )
        : BubbleView.CornerRadii(
            topLeft: top,
            topRight: largeRadius,
            bottomLeft: bottom,
            bottomRight: largeRadius
        )
    }

    func configureStatus(
        for message: Message,
        isMine: Bool
    ) {

        // Ticks only on your own messages.
        guard isMine else {
            statusLabel.isHidden = true
            return
        }

        statusLabel.isHidden = false

        if message.isPending {
            statusLabel.text = "🕓"
            statusLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        } else if message.isRead {
            statusLabel.text = "✓✓"
            statusLabel.textColor = UIColor(red: 0.6, green: 0.95, blue: 1, alpha: 1)
        } else {
            statusLabel.text = "✓"
            statusLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        }
    }

    func configureImage(
        _ image: UIImage?,
        hasImage: Bool
    ) {

        messageImageView.isHidden = !hasImage
        messageImageView.image = image

        // Off for text messages, so short texts get a narrow bubble.
        imageWidthConstraint.isActive = hasImage
        imageHeightConstraint.isActive = hasImage

        // Photos sit closer to the bubble edge than text does.
        let inset: CGFloat = hasImage ? 4 : 12
        stackInsetConstraints[0].constant = hasImage ? 4 : 7
        stackInsetConstraints[1].constant = inset
        stackInsetConstraints[2].constant = -inset

        guard hasImage else { return }

        // Keep the photo's shape, within sensible limits.
        let aspectRatio = image.map { $0.size.height / max($0.size.width, 1) } ?? 0.75
        imageHeightConstraint.constant = min(max(imageWidth * aspectRatio, 140), 320)
    }

    @objc
    func imageTapped() {

        guard let image = messageImageView.image else { return }

        onImageTapped?(image)
    }
}
