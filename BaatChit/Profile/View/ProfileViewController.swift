//
//  ProfileViewController.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import UIKit
import PhotosUI

final class ProfileViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: ProfileViewModel

    var onLogout: (() -> Void)?

    // MARK: - UI Components

    private let avatarView = AvatarView()

    private let changePhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Change Photo", for: .normal)
        return button
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)

        button.setTitle("Logout", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 14
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)

        return button
    }()

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Init

    init(viewModel: ProfileViewModel = ProfileViewModel()) {
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

        viewModel.startListening()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

// MARK: - Setup UI

private extension ProfileViewController {

    func setupUI() {

        title = "Profile"
        view.backgroundColor = .systemBackground

        [
            avatarView,
            changePhotoButton,
            nameLabel,
            emailLabel,
            logoutButton,
            activityIndicator
        ].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([

            avatarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            avatarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 120),
            avatarView.heightAnchor.constraint(equalToConstant: 120),

            changePhotoButton.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 12),
            changePhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            nameLabel.topAnchor.constraint(equalTo: changePhotoButton.bottomAnchor, constant: 24),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            logoutButton.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 48),
            logoutButton.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            logoutButton.heightAnchor.constraint(equalToConstant: 56),

            activityIndicator.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ])
    }
}

// MARK: - Actions

private extension ProfileViewController {

    func setupActions() {

        changePhotoButton.addTarget(
            self,
            action: #selector(changePhotoTapped),
            for: .touchUpInside
        )

        logoutButton.addTarget(
            self,
            action: #selector(logoutTapped),
            for: .touchUpInside
        )
    }

    @objc
    func changePhotoTapped() {

        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self

        present(picker, animated: true)
    }

    @objc
    func logoutTapped() {
        viewModel.logout()
    }
}

// MARK: - ViewModel Binding

private extension ProfileViewController {

    func bindViewModel() {

        viewModel.onUserUpdated = { [weak self] in

            guard let self = self,
                  let user = self.viewModel.user else { return }

            self.avatarView.configure(with: user, showsOnlineStatus: false)
            self.nameLabel.text = user.displayName
            self.emailLabel.text = user.email
        }

        viewModel.onLoadingStateChange = { [weak self] isLoading in

            if isLoading {
                self?.activityIndicator.startAnimating()
            } else {
                self?.activityIndicator.stopAnimating()
            }

            self?.changePhotoButton.isEnabled = !isLoading
            self?.logoutButton.isEnabled = !isLoading
        }

        viewModel.onLogout = { [weak self] in
            self?.onLogout?()
        }

        viewModel.onError = { [weak self] message in
            self?.showErrorAlert(message)
        }
    }
}

// MARK: - PHPickerViewControllerDelegate

extension ProfileViewController: PHPickerViewControllerDelegate {

    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {

        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in

            guard let image = object as? UIImage else { return }

            DispatchQueue.main.async {
                self?.viewModel.uploadPhoto(image)
            }
        }
    }
}
