//
//  NewChatViewController.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import UIKit

final class NewChatViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: NewChatViewModel

    var onUserSelected: ((User) -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - UI Components

    private let tableView = UITableView()

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No other users yet.\nAsk a friend to sign up!"
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Init

    init(viewModel: NewChatViewModel = NewChatViewModel()) {
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
        bindViewModel()

        viewModel.startListening()
    }
}

// MARK: - Setup UI

private extension NewChatViewController {

    func setupUI() {

        title = "New Chat"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "UserCell"
        )

        [tableView, activityIndicator].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc
    func cancelTapped() {
        onCancel?()
    }
}

// MARK: - ViewModel Binding

private extension NewChatViewController {

    func bindViewModel() {

        viewModel.onLoadingStateChange = { [weak self] isLoading in

            isLoading
            ? self?.activityIndicator.startAnimating()
            : self?.activityIndicator.stopAnimating()
        }

        viewModel.onUsersUpdated = { [weak self] in

            guard let self = self else { return }

            self.tableView.backgroundView = self.viewModel.users.isEmpty
            ? self.emptyLabel
            : nil

            self.tableView.reloadData()
        }

        viewModel.onError = { [weak self] message in
            self?.showErrorAlert(message)
        }
    }
}

// MARK: - UITableViewDataSource

extension NewChatViewController: UITableViewDataSource {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {

        viewModel.users.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "UserCell",
            for: indexPath
        )

        let user = viewModel.users[indexPath.row]

        var content = UIListContentConfiguration.subtitleCell()
        content.text = user.displayName
        content.secondaryText = user.email
        content.secondaryTextProperties.color = .secondaryLabel
        content.image = user.photoCacheKey.flatMap {
            ImageCache.shared.image(forKey: $0, data: user.photoData)
        } ?? UIImage(systemName: "person.circle.fill")
        content.imageProperties.tintColor = .systemGray3
        content.imageProperties.maximumSize = CGSize(width: 44, height: 44)
        content.imageProperties.reservedLayoutSize = CGSize(width: 44, height: 44)
        content.imageProperties.cornerRadius = 22

        cell.contentConfiguration = content

        return cell
    }
}

// MARK: - UITableViewDelegate

extension NewChatViewController: UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {

        tableView.deselectRow(at: indexPath, animated: true)

        onUserSelected?(viewModel.users[indexPath.row])
    }
}
