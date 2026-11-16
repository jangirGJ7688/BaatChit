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
    private var hasAnimatedIn = false
    private var isAnimatingRowEntrance = true
    private var searchText = ""

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

    private let backgroundView = AuroraBackgroundView()

    private let headerView = HomeHeaderView()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionHeaderTopPadding = 0

        // Room for the floating button under the last row.
        tableView.contentInset.bottom = 100

        return tableView
    }()

    private let newChatButton = FloatingActionButton(systemImageName: "square.and.pencil")

    private let emptyStateView = EmptyStateView()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        return indicator
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
        setupActions()
        bindViewModel()

        viewModel.startListening()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Home draws its own header instead of the navigation bar.
        navigationController?.setNavigationBarHidden(true, animated: animated)

        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasAnimatedIn else { return }

        hasAnimatedIn = true
        UIView.animateEntrance(of: headerView.animatableViews + [newChatButton])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateHeaderSize()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}

// MARK: - Setup UI

private extension HomeViewController {

    func setupUI() {

        view.backgroundColor = Theme.Colors.background

        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.tableHeaderView = headerView
        tableView.register(
            ChatListCell.self,
            forCellReuseIdentifier: ChatListCell.reuseIdentifier
        )

        [backgroundView, tableView, emptyStateView, newChatButton, activityIndicator].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        emptyStateView.isHidden = true

        NSLayoutConstraint.activate([

            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Below the header, so the search box stays usable.
            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 160),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            newChatButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            newChatButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -12
            ),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    /// Table headers don't size themselves with Auto Layout, so measure
    /// it whenever the width or the "Online now" row changes.
    func updateHeaderSize() {

        let width = tableView.bounds.width

        guard width > 0 else { return }

        let height = headerView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        guard headerView.frame.size != CGSize(width: width, height: height) else { return }

        headerView.frame.size = CGSize(width: width, height: height)
        tableView.tableHeaderView = headerView
    }
}

// MARK: - Actions

private extension HomeViewController {

    func setupActions() {

        newChatButton.addTarget(self, action: #selector(newChatTapped), for: .touchUpInside)

        headerView.onProfileTapped = { [weak self] in
            self?.onProfileTapped?()
        }

        headerView.onSearchTextChanged = { [weak self] text in
            self?.searchText = text
            self?.applySnapshot()
        }

        headerView.onOnlineUserSelected = { [weak self] user in
            self?.onChatSelected?(user)
        }

        emptyStateView.onAction = { [weak self] in
            self?.onNewChatTapped?()
        }
    }

    @objc
    func newChatTapped() {
        onNewChatTapped?()
    }
}

// MARK: - Data Source

private extension HomeViewController {

    var visibleItems: [ChatListItem] {

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else { return viewModel.items }

        return viewModel.items.filter {
            $0.otherUser.displayName.localizedCaseInsensitiveContains(query)
            || $0.lastMessage.localizedCaseInsensitiveContains(query)
        }
    }

    func applySnapshot() {

        let items = visibleItems
        let visibleIds = Set(items.map(\.chatId))

        let newItemsById = Dictionary(
            viewModel.items.map { ($0.chatId, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        // Visible rows that stay in the list but whose content changed.
        let changedIds = newItemsById
            .filter { id, item in
                visibleIds.contains(id) && (itemsById[id].map { $0 != item } ?? false)
            }
            .map(\.key)

        itemsById = newItemsById

        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(items.map(\.chatId))
        snapshot.reconfigureItems(changedIds)

        dataSource.apply(snapshot, animatingDifferences: hasLoadedItems)

        // Rows slide in only when the list first loads.
        if !hasLoadedItems {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.isAnimatingRowEntrance = false
            }
        }

        hasLoadedItems = true
        updateEmptyState(isEmpty: items.isEmpty)
    }

    func updateEmptyState(isEmpty: Bool) {

        let wasHidden = emptyStateView.isHidden

        emptyStateView.isHidden = !isEmpty

        guard isEmpty else { return }

        if searchText.isEmpty {
            emptyStateView.configure(
                iconName: "bubble.left.and.bubble.right.fill",
                title: "No chats yet",
                message: "Start a conversation with someone on BaatChit.",
                actionTitle: "Start a Chat"
            )
        } else {
            emptyStateView.configure(
                iconName: "magnifyingglass",
                title: "No results",
                message: "No chats match “\(searchText)”."
            )
        }

        if wasHidden {
            emptyStateView.animateIn()
        }
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

            guard let self = self else { return }

            self.headerView.configure(onlineUsers: self.viewModel.onlineUsers)
            self.view.setNeedsLayout()
            self.applySnapshot()
        }

        viewModel.onCurrentUserUpdated = { [weak self] in

            guard let self = self,
                  let user = self.viewModel.currentUser else { return }

            self.headerView.configure(currentUser: user)
        }

        viewModel.onIncomingMessage = { [weak self] item in
            self?.onIncomingMessage?(item)
        }

        viewModel.onError = { [weak self] message in
            self?.showErrorAlert(message)
        }
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

        Haptics.tap()
        onChatSelected?(item.otherUser)
    }

    /// Rows slide in gently the first time they appear.
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {

        guard isAnimatingRowEntrance else { return }

        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 20)

        UIView.animate(
            withDuration: 0.5,
            delay: 0.05 * Double(min(indexPath.row, 8)),
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.4,
            options: [.allowUserInteraction]
        ) {
            cell.alpha = 1
            cell.transform = .identity
        }
    }
}
