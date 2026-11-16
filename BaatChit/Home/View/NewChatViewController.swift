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

    private var searchText = ""

    private var visibleUsers: [User] {

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else { return viewModel.users }

        return viewModel.users.filter {
            $0.displayName.localizedCaseInsensitiveContains(query)
            || $0.email.localizedCaseInsensitiveContains(query)
        }
    }

    // MARK: - UI Components

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 78, bottom: 0, right: 0)
        tableView.separatorColor = Theme.Colors.cardBorder
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()

    private let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search people"
        return searchController
    }()

    private let emptyStateView = EmptyStateView()

    private let activityIndicator = UIActivityIndicatorView(style: .large)

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
        view.backgroundColor = Theme.Colors.background

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchResultsUpdater = self
        definesPresentationContext = true

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            UserCell.self,
            forCellReuseIdentifier: UserCell.reuseIdentifier
        )

        [tableView, emptyStateView, activityIndicator].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        emptyStateView.isHidden = true

        NSLayoutConstraint.activate([

            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc
    func cancelTapped() {
        onCancel?()
    }

    func reloadUsers() {

        tableView.reloadData()

        let isEmpty = visibleUsers.isEmpty
        emptyStateView.isHidden = !isEmpty

        guard isEmpty else { return }

        if searchText.isEmpty {
            emptyStateView.configure(
                iconName: "person.2.fill",
                title: "No one here yet",
                message: "Ask a friend to sign up for BaatChit, then start chatting."
            )
        } else {
            emptyStateView.configure(
                iconName: "magnifyingglass",
                title: "No results",
                message: "No one matches “\(searchText)”."
            )
        }
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
            self?.reloadUsers()
        }

        viewModel.onError = { [weak self] message in
            self?.showErrorAlert(message)
        }
    }
}

// MARK: - UISearchResultsUpdating

extension NewChatViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {

        searchText = searchController.searchBar.text ?? ""
        reloadUsers()
    }
}

// MARK: - UITableViewDataSource

extension NewChatViewController: UITableViewDataSource {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {

        visibleUsers.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: UserCell.reuseIdentifier,
            for: indexPath
        ) as? UserCell else {
            return UITableViewCell()
        }

        cell.configure(with: visibleUsers[indexPath.row])

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

        Haptics.tap()
        onUserSelected?(visibleUsers[indexPath.row])
    }
}
