//
//  ChatInputBar.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 11/11/26.
//

import UIKit

/// Photo button, a text box that grows up to five lines, and a send button
/// that only lights up when there's something to send.
final class ChatInputBar: UIView {

    // MARK: - Properties

    var onSend: ((String) -> Void)?
    var onAttach: (() -> Void)?
    var onTextChange: ((String) -> Void)?

    private let minTextHeight: CGFloat = 36
    private let maxTextHeight: CGFloat = 120

    private var textViewHeightConstraint: NSLayoutConstraint!

    // MARK: - UI Components

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let attachButton: UIButton = {
        let button = UIButton(type: .system)

        button.setImage(
            UIImage(
                systemName: "photo.on.rectangle",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 20)
            ),
            for: .normal
        )

        return button
    }()

    private let textContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 18
        return view
    }()

    private let textView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
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
        let button = UIButton(type: .system)

        button.setImage(
            UIImage(
                systemName: "arrow.up.circle.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 30)
            ),
            for: .normal
        )

        button.isEnabled = false

        return button
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ChatInputBar {

    func setupUI() {

        backgroundColor = .systemBackground

        textView.delegate = self

        [separatorView, attachButton, textContainer, sendButton].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        [textView, placeholderLabel].forEach {
            textContainer.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        textViewHeightConstraint = textView.heightAnchor.constraint(
            equalToConstant: minTextHeight
        )

        NSLayoutConstraint.activate([

            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),

            // Buttons stay next to the last line as the text box grows.
            attachButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            attachButton.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),
            attachButton.widthAnchor.constraint(equalToConstant: 36),
            attachButton.heightAnchor.constraint(equalToConstant: 36),

            textContainer.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            textContainer.leadingAnchor.constraint(equalTo: attachButton.trailingAnchor, constant: 4),
            textContainer.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -6),

            textView.topAnchor.constraint(equalTo: textContainer.topAnchor),
            textView.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor, constant: 4),
            textView.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor, constant: -4),
            textViewHeightConstraint,

            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 13),
            placeholderLabel.centerYAnchor.constraint(equalTo: textContainer.centerYAnchor),

            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            sendButton.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    func setupActions() {

        attachButton.addTarget(
            self,
            action: #selector(attachTapped),
            for: .touchUpInside
        )

        sendButton.addTarget(
            self,
            action: #selector(sendTapped),
            for: .touchUpInside
        )
    }

    @objc
    func attachTapped() {
        onAttach?()
    }

    @objc
    func sendTapped() {

        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        onSend?(text)

        textView.text = ""
        textViewDidChange(textView)
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
        sendButton.isEnabled = hasText

        updateTextViewHeight()

        onTextChange?(textView.text)
    }
}
