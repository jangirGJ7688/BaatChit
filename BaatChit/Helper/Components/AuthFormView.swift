//
//  AuthFormView.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/11/26.
//

import UIKit

/// Shared layout for the login, signup and reset screens: a gradient
/// header and a form below it, all scrollable so the keyboard never
/// covers a field.
final class AuthFormView: UIView {

    // MARK: - UI Components

    let headerView: AuthHeaderView

    let formStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 14
        return stackView
    }()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    // MARK: - Init

    init(headerView: AuthHeaderView) {
        self.headerView = headerView
        super.init(frame: .zero)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()

        headerView.topInset = safeAreaInsets.top
    }

    /// Plays the entrance animation for the form.
    func animateIn() {
        UIView.animateEntrance(
            of: formStack.arrangedSubviews.filter { !$0.isHidden },
            delay: 0.05
        )
    }
}

private extension AuthFormView {

    func setupUI() {

        backgroundColor = Theme.Colors.background

        addSubview(scrollView)

        [headerView, formStack].forEach {
            scrollView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Tap outside a field to close the keyboard.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)

        let content = scrollView.contentLayoutGuide

        NSLayoutConstraint.activate([

            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            headerView.topAnchor.constraint(equalTo: content.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            headerView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            formStack.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 32),
            formStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            formStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            formStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -32)
        ])
    }

    @objc
    func backgroundTapped() {
        endEditing(true)
    }
}
