//
//  HomeViewController.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 13/06/26.
//

import UIKit

final class HomeViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: HomeViewModel

    var onChatSelected: ((User) -> Void)?
    var onNewChatTapped: (() -> Void)?
    var onProfileTapped: (() -> Void)?
    var onIncomingMessage: ((ChatListItem) -> Void)?

    private var itemsById: [String: ChatListItem] = [:]
    private var hasLoadedItems = false

    // Diffable data source animates rows moving up when a new message arrives.
    private lazy var dataSource = UITableViewDiffableDataSource<Int, String>(
        tableView: tableView
    ) { [weak self] tableView, indexPath, chatId in

        guard let item = self?.itemsById[chatId],
              let cell = tableView.dequeueReusableCell(
                withIdentifier: ChatListCell.reuseIdentifier,
                for: indexPath
              ) as? ChatListCell else {
            return UITableViewCell()
        }

        cell.configure(with: item)

        return cell
    }

    // MARK: - UI Components

    private let tableView = UITableView()

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No chats yet.\nTap ✎ to start a new chat."
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Init

    init(viewModel: HomeViewModel = HomeViewModel()) {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: animated)

        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }
}

// MARK: - Setup UI

private extension HomeViewController {

    func setupUI() {

        title = "Chats"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "person.crop.circle"),
            style: .plain,
            target: self,
            action: #selector(profileTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(newChatTapped)
        )

        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 0)
        tableView.register(
            ChatListCell.self,
            forCellReuseIdentifier: ChatListCell.reuseIdentifier
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
}

// MARK: - Actions

private extension HomeViewController {

    @objc
    func profileTapped() {
        onProfileTapped?()
    }

    @objc
    func newChatTapped() {
        onNewChatTapped?()
    }
}

// MARK: - ViewModel Binding

private extension HomeViewController {

    func bindViewModel() {

        viewModel.onLoadingStateChange = { [weak self] isLoading in

            isLoading
            ? self?.activityIndicator.startAnimating()
            : self?.activityIndicator.stopAnimating()
        }

        viewModel.onItemsUpdated = { [weak self] in
            self?.applySnapshot()
        }

        viewModel.onIncomingMessage = { [weak self] item in
            self?.onIncomingMessage?(item)
        }

        viewModel.onError = { [weak self] message in
            self?.showErrorAlert(message)
        }
    }
}

// MARK: - Data Source

private extension HomeViewController {

    func applySnapshot() {

        let items = viewModel.items

        let newItemsById = Dictionary(
            items.map { ($0.chatId, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        // Rows that stay in the list but whose content changed.
        let changedIds = newItemsById
            .filter { id, item in itemsById[id].map { $0 != item } ?? false }
            .map(\.key)

        itemsById = newItemsById

        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(items.map(\.chatId))
        snapshot.reconfigureItems(changedIds)

        dataSource.apply(snapshot, animatingDifferences: hasLoadedItems)

        hasLoadedItems = true
        tableView.backgroundView = items.isEmpty ? emptyLabel : nil
    }
}

// MARK: - UITableViewDelegate

extension HomeViewController: UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {

        guard let chatId = dataSource.itemIdentifier(for: indexPath),
              let item = itemsById[chatId] else { return }

        onChatSelected?(item.otherUser)
    }
}
