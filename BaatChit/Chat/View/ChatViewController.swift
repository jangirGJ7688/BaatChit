//
//  ChatViewController.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import UIKit
import PhotosUI

final class ChatViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: ChatViewModel

    var otherUserId: String {
        viewModel.otherUser.uid
    }

    private static let typingSectionId = "typing-section"
    private static let typingItemId = "typing-item"

    private var rowsById: [String: MessageRow] = [:]
    private var hasLoadedMessages = false
    private var isNearBottom = true
    private var lastTableHeight: CGFloat = 0

    // Diffable data source animates new messages in instead of reloading.
    private lazy var dataSource = UITableViewDiffableDataSource<String, String>(
        tableView: tableView
    ) { [weak self] tableView, indexPath, itemId in

        guard let self = self else { return UITableViewCell() }

        if itemId == Self.typingItemId {
            return tableView.dequeueReusableCell(
                withIdentifier: TypingIndicatorCell.reuseIdentifier,
                for: indexPath
            )
        }

        guard let row = self.rowsById[itemId],
              let cell = tableView.dequeueReusableCell(
                withIdentifier: MessageCell.reuseIdentifier,
                for: indexPath
              ) as? MessageCell else {
            return UITableViewCell()
        }

        cell.configure(
            with: row,
            image: self.viewModel.image(for: row.message)
        )

        cell.onImageTapped = { [weak self] image in
            self?.showImageViewer(image)
        }

        return cell
    }

    // MARK: - UI Components

    private let avatarView = AvatarView()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        return label
    }()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.allowsSelection = false
        tableView.backgroundColor = .systemGroupedBackground
        tableView.sectionHeaderTopPadding = 0
        tableView.estimatedRowHeight = 50
        tableView.estimatedSectionHeaderHeight = 36
        return tableView
    }()

    private let inputBar = ChatInputBar()

    // Fills the home-indicator area under the input bar.
    private let bottomFillView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()

    // MARK: - Init

    init(viewModel: ChatViewModel) {
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

        updateHeader()
        viewModel.startListening()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.setVisible(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewModel.setVisible(false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // When the keyboard opens the table gets shorter; keep the latest
        // messages in view instead of hiding them behind the keyboard.
        let tableHeight = tableView.bounds.height

        if tableHeight != lastTableHeight {

            if isNearBottom && hasLoadedMessages {
                scrollToBottom(animated: false)
            }

            lastTableHeight = tableHeight
        }
    }
}

// MARK: - Setup UI

private extension ChatViewController {

    func setupUI() {

        view.backgroundColor = .systemGroupedBackground

        setupTitleView()

        tableView.dataSource = dataSource
        tableView.delegate = self

        tableView.register(
            MessageCell.self,
            forCellReuseIdentifier: MessageCell.reuseIdentifier
        )

        tableView.register(
            TypingIndicatorCell.self,
            forCellReuseIdentifier: TypingIndicatorCell.reuseIdentifier
        )

        tableView.register(
            DateHeaderView.self,
            forHeaderFooterViewReuseIdentifier: DateHeaderView.reuseIdentifier
        )

        [tableView, inputBar, bottomFillView].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            // Follows the keyboard; sits on the safe area when it's hidden.
            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            bottomFillView.topAnchor.constraint(equalTo: inputBar.bottomAnchor),
            bottomFillView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomFillView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomFillView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// Photo, name and "online" / "typing..." in the navigation bar.
    func setupTitleView() {

        let labelsStack = UIStackView(arrangedSubviews: [nameLabel, statusLabel])
        labelsStack.axis = .vertical
        labelsStack.alignment = .leading

        let titleStack = UIStackView(arrangedSubviews: [avatarView, labelsStack])
        titleStack.axis = .horizontal
        titleStack.alignment = .center
        titleStack.spacing = 8

        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 34),
            avatarView.heightAnchor.constraint(equalToConstant: 34)
        ])

        navigationItem.titleView = titleStack
    }

    func updateHeader() {

        avatarView.configure(with: viewModel.otherUser)
        nameLabel.text = viewModel.otherUser.displayName

        let statusText = viewModel.statusText

        statusLabel.text = statusText
        statusLabel.isHidden = statusText.isEmpty
        statusLabel.textColor = viewModel.isOtherUserTyping || viewModel.otherUser.isOnline
        ? .systemBlue
        : .secondaryLabel
    }
}

// MARK: - Actions

private extension ChatViewController {

    func setupActions() {

        inputBar.onSend = { [weak self] text in
            self?.viewModel.sendMessage(text)
        }

        inputBar.onTextChange = { [weak self] text in
            self?.viewModel.textDidChange(text)
        }

        inputBar.onAttach = { [weak self] in
            self?.showPhotoPicker()
        }

        // Don't mark messages as seen while the app is in the background.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    @objc
    func appDidBecomeActive() {

        if viewIfLoaded?.window != nil {
            viewModel.setVisible(true)
        }
    }

    @objc
    func appWillResignActive() {
        viewModel.setVisible(false)
    }

    func showPhotoPicker() {

        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self

        present(picker, animated: true)
    }

    func showImageViewer(_ image: UIImage) {

        view.endEditing(true)

        present(
            ImageViewerViewController(image: image),
            animated: true
        )
    }

    func scrollToBottom(animated: Bool) {

        let lastSection = tableView.numberOfSections - 1

        guard lastSection >= 0 else { return }

        let lastRow = tableView.numberOfRows(inSection: lastSection) - 1

        guard lastRow >= 0 else { return }

        tableView.scrollToRow(
            at: IndexPath(row: lastRow, section: lastSection),
            at: .bottom,
            animated: animated
        )
    }
}

// MARK: - Data Source

private extension ChatViewController {

    func applySnapshot() {

        let sections = viewModel.sections
        let rows = sections.flatMap(\.rows)

        let newRowsById = Dictionary(
            rows.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        // Rows that stay but changed, e.g. ✓ became ✓✓ or a group grew.
        let changedIds = newRowsById
            .filter { id, row in rowsById[id].map { $0 != row } ?? false }
            .map(\.key)

        rowsById = newRowsById

        var snapshot = NSDiffableDataSourceSnapshot<String, String>()

        sections.forEach { section in
            snapshot.appendSections([section.id])
            snapshot.appendItems(section.rows.map(\.id), toSection: section.id)
        }

        if viewModel.isOtherUserTyping {
            snapshot.appendSections([Self.typingSectionId])
            snapshot.appendItems([Self.typingItemId], toSection: Self.typingSectionId)
        }

        snapshot.reconfigureItems(changedIds)

        dataSource.apply(snapshot, animatingDifferences: hasLoadedMessages)
    }
}

// MARK: - ViewModel Binding

private extension ChatViewController {

    func bindViewModel() {

        viewModel.onMessagesUpdated = { [weak self] update in

            guard let self = self else { return }

            let isFirstLoad = !self.hasLoadedMessages

            // Follow new messages if you sent them or were already at the
            // bottom; don't yank the view away while reading older ones.
            let shouldScroll = isFirstLoad
            || (update.hasNewMessage && (update.isNewMessageFromCurrentUser || self.isNearBottom))

            self.applySnapshot()
            self.hasLoadedMessages = true

            if shouldScroll {
                self.scrollToBottom(animated: !isFirstLoad)
            }
        }

        viewModel.onTypingChanged = { [weak self] in

            guard let self = self else { return }

            self.applySnapshot()

            if self.isNearBottom {
                self.scrollToBottom(animated: true)
            }
        }

        viewModel.onHeaderUpdated = { [weak self] in
            self?.updateHeader()
        }

        viewModel.onError = { [weak self] message in
            self?.showErrorAlert(message)
        }
    }
}

// MARK: - UITableViewDelegate

extension ChatViewController: UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {

        guard let sectionId = dataSource.sectionIdentifier(for: section),
              let title = viewModel.sections.first(where: { $0.id == sectionId })?.title,
              let header = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: DateHeaderView.reuseIdentifier
              ) as? DateHeaderView else {
            return nil
        }

        header.configure(title: title)

        return header
    }

    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {

        dataSource.sectionIdentifier(for: section) == Self.typingSectionId
        ? .leastNonzeroMagnitude
        : UITableView.automaticDimension
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let distanceFromBottom = scrollView.contentSize.height
        - scrollView.contentOffset.y
        - scrollView.bounds.height

        isNearBottom = distanceFromBottom < 120
    }
}

// MARK: - PHPickerViewControllerDelegate

extension ChatViewController: PHPickerViewControllerDelegate {

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
                self?.viewModel.sendImage(image)
            }
        }
    }
}
