//
//  ChatInputBar.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 11/11/26.
//

import UIKit

/// Photo button, a text box that grows up to five lines, and a round
/// gradient send button that pops in once there's something to send.
final class ChatInputBar: UIView {

    // MARK: - Properties

    var onSend: ((String) -> Void)?
    var onAttach: (() -> Void)?
    var onTextChange: ((String) -> Void)?

    private let minTextHeight: CGFloat = 38
    private let maxTextHeight: CGFloat = 120

    private var textViewHeightConstraint: NSLayoutConstraint!
    private var isSendVisible = false

    // MARK: - UI Components

    private let blurView = UIVisualEffectView(
        effect: UIBlurEffect(style: .systemChromeMaterial)
    )

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let attachButton: UIButton = {
        let button = UIButton(type: .system)

        button.setImage(
            UIImage(
                systemName: "plus",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            ),
            for: .normal
        )

        button.tintColor = Theme.Colors.brand
        button.backgroundColor = Theme.Colors.brand.withAlphaComponent(0.12)
        button.layer.cornerRadius = 19

        return button
    }()

    private let textContainer: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.fieldBackground
        view.layer.cornerRadius = 19
        return view
    }()

    private let textView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 9, left: 10, bottom: 9, right: 10)
        return textView
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Message"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .placeholderText
        return label
    }()

    private let sendButton: UIButton = {
        let button = UIButton(type: .custom)

        button.setImage(
            UIImage(
                systemName: "arrow.up",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .bold)
            ),
            for: .normal
        )

        button.tintColor = .white
        button.layer.cornerRadius = 19
        button.clipsToBounds = true

        return button
    }()

    private let sendGradientView: GradientView = {
        let view = GradientView()
        view.isUserInteractionEnabled = false
        return view
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        setupActions()
        setSendVisible(false, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ChatInputBar {

    func setupUI() {

        textView.delegate = self

        sendButton.insertSubview(sendGradientView, at: 0)

        [blurView, separatorView, attachButton, textContainer, sendButton].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        [textView, placeholderLabel].forEach {
            textContainer.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        sendGradientView.translatesAutoresizingMaskIntoConstraints = false

        textViewHeightConstraint = textView.heightAnchor.constraint(
            equalToConstant: minTextHeight
        )

        NSLayoutConstraint.activate([

            // The blur reaches below the bar, behind the home indicator.
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 100),

            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),

            // Buttons stay next to the last line as the text box grows.
            attachButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            attachButton.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),
            attachButton.widthAnchor.constraint(equalToConstant: 38),
            attachButton.heightAnchor.constraint(equalToConstant: 38),

            textContainer.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            textContainer.leadingAnchor.constraint(equalTo: attachButton.trailingAnchor, constant: 8),
            textContainer.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),

            textView.topAnchor.constraint(equalTo: textContainer.topAnchor),
            textView.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor, constant: 4),
            textView.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor, constant: -4),
            textViewHeightConstraint,

            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 15),
            placeholderLabel.centerYAnchor.constraint(equalTo: textContainer.centerYAnchor),

            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            sendButton.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 38),
            sendButton.heightAnchor.constraint(equalToConstant: 38),

            sendGradientView.topAnchor.constraint(equalTo: sendButton.topAnchor),
            sendGradientView.leadingAnchor.constraint(equalTo: sendButton.leadingAnchor),
            sendGradientView.trailingAnchor.constraint(equalTo: sendButton.trailingAnchor),
            sendGradientView.bottomAnchor.constraint(equalTo: sendButton.bottomAnchor)
        ])
    }

    func setupActions() {

        attachButton.addTarget(self, action: #selector(attachTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
    }

    @objc
    func attachTapped() {
        Haptics.tap()
        onAttach?()
    }

    @objc
    func sendTapped() {

        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else { return }

        Haptics.tap()

        onSend?(text)

        textView.text = ""
        textViewDidChange(textView)
    }

    /// The send button pops in when there's text, and shrinks away when not.
    func setSendVisible(
        _ isVisible: Bool,
        animated: Bool
    ) {

        guard isVisible != isSendVisible || !animated else { return }

        isSendVisible = isVisible
        sendButton.isEnabled = isVisible

        let changes = {
            self.sendButton.alpha = isVisible ? 1 : 0.35
            self.sendButton.transform = isVisible
            ? .identity
            : CGAffineTransform(scaleX: 0.75, y: 0.75)
            self.sendGradientView.alpha = isVisible ? 1 : 0
            self.sendButton.backgroundColor = isVisible ? .clear : .systemGray3
        }

        guard animated else {
            changes()
            return
        }

        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.8,
            options: [.beginFromCurrentState, .allowUserInteraction],
            animations: changes
        )
    }

    func updateTextViewHeight() {

        let fittingSize = textView.sizeThatFits(
            CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        )

        let height = min(max(fittingSize.height, minTextHeight), maxTextHeight)

        // Past five lines, scroll inside the box instead of growing.
        textView.isScrollEnabled = fittingSize.height > maxTextHeight

        guard textViewHeightConstraint.constant != height else { return }

        textViewHeightConstraint.constant = height

        UIView.animate(withDuration: 0.15) {
            self.superview?.layoutIfNeeded()
        }
    }
}

// MARK: - UITextViewDelegate

extension ChatInputBar: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {

        let hasText = !textView.text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        placeholderLabel.isHidden = !textView.text.isEmpty
        setSendVisible(hasText, animated: true)

        updateTextViewHeight()

        onTextChange?(textView.text)
    }
}
