//
//  ForgotPasswordViewController.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/06/26.
//

import UIKit

final class ForgotPasswordViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: ForgotPasswordViewModel

    var onBackToLogin: (() -> Void)?

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Forgot Password?"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter your email address and we'll send you a password reset link."
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private lazy var emailTextField = createTextField(
        placeholder: "Email Address",
        imageName: "envelope"
    )

    private let resetButton: UIButton = {
        let button = UIButton(type: .system)

        button.setTitle("Send Reset Link", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue

        button.layer.cornerRadius = 14
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)

        return button
    }()

    private let backButton: UIButton = {
        let button = UIButton(type: .system)

        button.setTitle("Back to Login", for: .normal)

        return button
    }()

    private let activityIndicator = UIActivityIndicatorView(
        style: .large
    )

    // MARK: - Init

    init(
        viewModel: ForgotPasswordViewModel = ForgotPasswordViewModel()
    ) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupActions()
        bindViewModel()
    }
}

private extension ForgotPasswordViewController {

    func setupUI() {

        view.backgroundColor = .systemBackground

        [
            titleLabel,
            subtitleLabel,
            emailTextField,
            resetButton,
            backButton,
            activityIndicator
        ].forEach {

            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([

            titleLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 80
            ),

            titleLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24
            ),

            subtitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 12
            ),

            subtitleLabel.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),

            subtitleLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24
            ),

            emailTextField.topAnchor.constraint(
                equalTo: subtitleLabel.bottomAnchor,
                constant: 40
            ),

            emailTextField.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),

            emailTextField.trailingAnchor.constraint(
                equalTo: subtitleLabel.trailingAnchor
            ),

            emailTextField.heightAnchor.constraint(
                equalToConstant: 56
            ),

            resetButton.topAnchor.constraint(
                equalTo: emailTextField.bottomAnchor,
                constant: 30
            ),

            resetButton.leadingAnchor.constraint(
                equalTo: emailTextField.leadingAnchor
            ),

            resetButton.trailingAnchor.constraint(
                equalTo: emailTextField.trailingAnchor
            ),

            resetButton.heightAnchor.constraint(
                equalToConstant: 56
            ),

            backButton.topAnchor.constraint(
                equalTo: resetButton.bottomAnchor,
                constant: 20
            ),

            backButton.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            activityIndicator.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            activityIndicator.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            )
        ])
    }

    func createTextField(
        placeholder: String,
        imageName: String
    ) -> UITextField {

        let textField = UITextField()

        textField.placeholder = placeholder
        textField.backgroundColor = .secondarySystemBackground

        textField.layer.cornerRadius = 14
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray5.cgColor
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no

        let icon = UIImageView(
            image: UIImage(systemName: imageName)
        )

        icon.tintColor = .secondaryLabel
        icon.frame = CGRect(x: 12, y: 0, width: 20, height: 20)

        let container = UIView(
            frame: CGRect(x: 0, y: 0, width: 44, height: 20)
        )

        container.addSubview(icon)

        textField.leftView = container
        textField.leftViewMode = .always

        return textField
    }
}

private extension ForgotPasswordViewController {

    func setupActions() {

        resetButton.addTarget(
            self,
            action: #selector(resetTapped),
            for: .touchUpInside
        )

        backButton.addTarget(
            self,
            action: #selector(backTapped),
            for: .touchUpInside
        )
    }

    @objc
    func resetTapped() {

        viewModel.resetPassword(
            email: emailTextField.text
        )
    }

    @objc
    func backTapped() {

        onBackToLogin?()
    }

    func bindViewModel() {

        viewModel.onLoadingStateChange = { [weak self] isLoading in

            if isLoading {
                self?.activityIndicator.startAnimating()
                self?.resetButton.isEnabled = false
            } else {
                self?.activityIndicator.stopAnimating()
                self?.resetButton.isEnabled = true
            }
        }

        viewModel.onSuccess = { [weak self] message in

            let alert = UIAlertController(
                title: "Success",
                message: message,
                preferredStyle: .alert
            )

            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default
                ) { _ in
                    self?.onBackToLogin?()
                }
            )

            self?.present(alert, animated: true)
        }

        viewModel.onError = { [weak self] message in

            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert
            )

            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default
                )
            )

            self?.present(alert, animated: true)
        }
    }
}
