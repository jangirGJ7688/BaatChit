//
//  FormField.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/11/26.
//

import UIKit

/// A rounded text field with an icon that lights up while you type,
/// and a show/hide button for passwords.
final class FormField: UIView {

    enum Kind {
        case name
        case email
        case password
        case newPassword
    }

    // MARK: - Properties

    var onReturn: (() -> Void)?
    var onTextChange: (() -> Void)?

    var text: String? {
        textField.text
    }

    var returnKeyType: UIReturnKeyType {
        get { textField.returnKeyType }
        set { textField.returnKeyType = newValue }
    }

    // MARK: - UI Components

    let textField: UITextField = {
        let textField = UITextField()
        textField.font = Theme.Fonts.rounded(17)
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        return textField
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let visibilityButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .secondaryLabel
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.isHidden = true
        return button
    }()

    // MARK: - Init

    init(
        placeholder: String,
        iconName: String,
        kind: Kind
    ) {
        super.init(frame: .zero)

        textField.placeholder = placeholder
        iconView.image = UIImage(
            systemName: iconName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        )

        configure(for: kind)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - First Responder

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }
}

private extension FormField {

    func configure(for kind: Kind) {

        switch kind {

        case .name:
            textField.textContentType = .name
            textField.autocapitalizationType = .words

        case .email:
            textField.textContentType = .emailAddress
            textField.keyboardType = .emailAddress

        case .password:
            textField.textContentType = .password
            textField.isSecureTextEntry = true
            visibilityButton.isHidden = false

        case .newPassword:
            textField.textContentType = .newPassword
            textField.isSecureTextEntry = true
            visibilityButton.isHidden = false
        }
    }

    func setupUI() {

        backgroundColor = Theme.Colors.fieldBackground
        layer.cornerRadius = Theme.Radius.medium
        layer.borderWidth = 1.5
        layer.borderColor = UIColor.clear.cgColor

        textField.delegate = self
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        visibilityButton.addTarget(
            self,
            action: #selector(visibilityTapped),
            for: .touchUpInside
        )

        let stackView = UIStackView(
            arrangedSubviews: [iconView, textField, visibilityButton]
        )
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            heightAnchor.constraint(equalToConstant: 56),

            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.widthAnchor.constraint(equalToConstant: 22),
            visibilityButton.widthAnchor.constraint(equalToConstant: 36),
            visibilityButton.heightAnchor.constraint(equalToConstant: 36)
        ])

        // Tapping anywhere on the field starts typing.
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(fieldTapped))
        )
    }

    func setFocused(_ isFocused: Bool) {

        UIView.animate(withDuration: 0.2) {
            self.layer.borderColor = isFocused
            ? Theme.Colors.brand.cgColor
            : UIColor.clear.cgColor
            self.iconView.tintColor = isFocused ? Theme.Colors.brand : .secondaryLabel
        }
    }

    @objc
    func fieldTapped() {
        textField.becomeFirstResponder()
    }

    @objc
    func textChanged() {
        onTextChange?()
    }

    @objc
    func visibilityTapped() {

        textField.isSecureTextEntry.toggle()

        visibilityButton.setImage(
            UIImage(systemName: textField.isSecureTextEntry ? "eye.slash" : "eye"),
            for: .normal
        )

        Haptics.tap()
    }
}

// MARK: - UITextFieldDelegate

extension FormField: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        setFocused(true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        setFocused(false)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn?()
        return true
    }
}
