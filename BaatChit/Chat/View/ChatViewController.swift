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
    private var newMessagesWhileScrolledUp = 0
    private var isScrollingToBottom = false

    /// Whether the "•••" row is in the table. It follows the other person's
    /// typing, but stays briefly after they stop, so their message can take
    /// its place in one step instead of the table shrinking and growing.
    private var showsTypingRow = false
    private var hideTypingRowWorkItem: DispatchWorkItem?
    private var isAnimatingToBottom = false
    private var contentSizeObservation: NSKeyValueObservation?

    /// Real row heights, so the table can work out where the bottom is
    /// before every row has been on screen.
    private var rowHeights: [String: CGFloat] = [:]

    /// Rows that just arrived and should animate in when first shown.
    private var itemIdsToAnimate = Set<String>()

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
        label.font = Theme.Fonts.rounded(16, weight: .semibold)
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(12, weight: .medium)
        return label
    }()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        tableView.sectionHeaderTopPadding = 0
        tableView.estimatedRowHeight = 50
        tableView.estimatedSectionHeaderHeight = 36
        tableView.contentInset.bottom = 8
        return tableView
    }()

    private let backgroundView = AuroraBackgroundView(intensity: 0.45)

    private let inputBar = ChatInputBar()

    private let scrollToBottomButton = ScrollToBottomButton()

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

        // The keyboard, the input bar growing and the push transition all
        // resize the table; keep the latest messages in view through them.
        keepPinnedToBottom()
    }
}

// MARK: - Setup UI

private extension ChatViewController {

    func setupUI() {

        view.backgroundColor = Theme.Colors.chatBackground
        navigationItem.largeTitleDisplayMode = .never

        setupTitleView()

        // Hidden until the first messages are in place at the bottom.
        tableView.alpha = 0

        // iOS 26 blurs content under the top bar, which smudges the bubbles
        // passing behind the date pills.
        if #available(iOS 26.0, *) {
            tableView.topEdgeEffect.isHidden = true
        }

        // Rows and headers find their real height after being laid out,
        // which makes the content taller; stay at the bottom when it does.
        contentSizeObservation = tableView.observe(\.contentSize, options: [.old, .new]) { [weak self] _, change in

            guard change.oldValue != change.newValue else { return }

            DispatchQueue.main.async {
                self?.keepPinnedToBottom()
            }
        }

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

        [backgroundView, tableView, inputBar, scrollToBottomButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([

            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            // Follows the keyboard; sits on the safe area when it's hidden.
            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            scrollToBottomButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollToBottomButton.bottomAnchor.constraint(equalTo: inputBar.topAnchor, constant: -14)
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
        statusLabel.textColor = viewModel.isOtherUserTyping
        ? Theme.Colors.brand
        : viewModel.otherUser.isOnline ? Theme.Colors.online : .secondaryLabel
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

        scrollToBottomButton.addTarget(
            self,
            action: #selector(scrollToBottomTapped),
            for: .touchUpInside
        )

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

    @objc
    func scrollToBottomTapped() {

        Haptics.tap()

        // Rows on the way may turn out taller than estimated, so finish
        // with a correction once the scroll animation ends.
        isScrollingToBottom = true
        tableView.setContentOffset(bottomOffset, animated: true)
    }

    var bottomOffset: CGPoint {

        let insets = tableView.adjustedContentInset
        let y = tableView.contentSize.height + insets.bottom - tableView.bounds.height

        return CGPoint(x: 0, y: max(y, -insets.top))
    }

    func scrollToBottom(animated: Bool) {

        isNearBottom = true

        let startOffset = tableView.contentOffset

        // Rows only know their real height once laid out, and that changes
        // where the bottom is, so settle there over a few passes.
        tableView.layoutIfNeeded()

        for _ in 0..<4 {

            let offset = bottomOffset

            guard abs(tableView.contentOffset.y - offset.y) > 0.5 else { break }

            tableView.contentOffset = offset
            tableView.layoutIfNeeded()
        }

        let endOffset = tableView.contentOffset

        // Glide the last stretch, e.g. when a new message pushes things up.
        guard animated,
              abs(endOffset.y - startOffset.y) > 0.5,
              abs(endOffset.y - startOffset.y) < tableView.bounds.height else {
            return
        }

        tableView.contentOffset = startOffset
        isAnimatingToBottom = true

        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState]
        ) {
            self.tableView.contentOffset = endOffset
        } completion: { _ in
            self.isAnimatingToBottom = false
            self.keepPinnedToBottom()
        }
    }

    func keepPinnedToBottom() {

        guard hasLoadedMessages,
              isNearBottom,
              !isAnimatingToBottom,
              !isScrollingToBottom,
              !tableView.isDragging,
              !tableView.isDecelerating else { return }

        let offset = bottomOffset

        guard abs(tableView.contentOffset.y - offset.y) > 0.5 else { return }

        // During the push transition this runs inside UIKit's animation, and
        // the table would slowly drift instead of sitting at the bottom.
        if transitionCoordinator != nil {
            UIView.performWithoutAnimation {
                tableView.contentOffset = offset
            }
        } else {
            tableView.contentOffset = offset
        }
    }

    func setTypingRowVisible(_ isVisible: Bool) {

        guard isVisible != showsTypingRow else { return }

        showsTypingRow = isVisible
        applySnapshot()

        if isNearBottom {
            scrollToBottom(animated: true)
        }
    }

    /// New messages rise and fade in, instead of the table's default slide.
    func animateEntrance(of cell: UITableViewCell) {

        cell.contentView.alpha = 0
        cell.contentView.transform = CGAffineTransform(translationX: 0, y: 16)
            .scaledBy(x: 0.96, y: 0.96)

        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.4,
            options: [.allowUserInteraction]
        ) {
            cell.contentView.alpha = 1
            cell.contentView.transform = .identity
        }
    }

    /// A close guess at a row's height before it has been laid out.
    func estimatedHeight(for row: MessageRow) -> CGFloat {

        let groupSpacing: CGFloat = row.isFirstInGroup ? 6 : 1
        let footerHeight: CGFloat = 16

        if let image = viewModel.image(for: row.message) {

            let aspectRatio = image.size.height / max(image.size.width, 1)
            let imageHeight = min(max(240 * aspectRatio, 140), 320)

            return groupSpacing + 1 + 4 + imageHeight + 2 + footerHeight + 6
        }

        let maxTextWidth = tableView.bounds.width * 0.78 - 24

        let textHeight = (row.message.text as NSString).boundingRect(
            with: CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: UIFont.systemFont(ofSize: 16)],
            context: nil
        ).height

        return groupSpacing + 1 + 7 + ceil(textHeight) + 2 + footerHeight + 6
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

        // Animate rows that weren't there before (not on the first load).
        if hasLoadedMessages {
            itemIdsToAnimate = Set(newRowsById.keys).subtracting(rowsById.keys)

            let wasTyping = dataSource.snapshot().indexOfSection(Self.typingSectionId) != nil

            if showsTypingRow && !wasTyping {
                itemIdsToAnimate.insert(Self.typingItemId)
            }
        }

        rowsById = newRowsById

        var snapshot = NSDiffableDataSourceSnapshot<String, String>()

        sections.forEach { section in
            snapshot.appendSections([section.id])
            snapshot.appendItems(section.rows.map(\.id), toSection: section.id)
        }

        if showsTypingRow {
            snapshot.appendSections([Self.typingSectionId])
            snapshot.appendItems([Self.typingItemId], toSection: Self.typingSectionId)
        }

        snapshot.reconfigureItems(changedIds)

        // Applied without the table's own animation: its row slides fight
        // with scrolling to the bottom. New rows animate in themselves.
        dataSource.apply(snapshot, animatingDifferences: false)

        tableView.layoutIfNeeded()
        itemIdsToAnimate.removeAll()
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

            // Their new message replaces the "•••" row in the same update.
            if update.hasNewMessage && !update.isNewMessageFromCurrentUser {
                self.hideTypingRowWorkItem?.cancel()
                self.showsTypingRow = false
            }

            // Messages can arrive before the screen has its final size;
            // lay it out first so the bottom is worked out correctly.
            if isFirstLoad {
                self.view.layoutIfNeeded()
            }

            self.applySnapshot()
            self.hasLoadedMessages = true

            if isFirstLoad {
                UIView.performWithoutAnimation {
                    self.scrollToBottom(animated: false)
                }
            } else if shouldScroll {
                self.scrollToBottom(animated: true)
            }

            if isFirstLoad {
                UIView.animate(withDuration: 0.2) {
                    self.tableView.alpha = 1
                }
            } else if !shouldScroll && update.hasNewMessage {
                // Count what arrived while you were reading older messages.
                self.newMessagesWhileScrolledUp += 1
                self.scrollToBottomButton.unreadCount = self.newMessagesWhileScrolledUp
                Haptics.tap()
            }
        }

        viewModel.onTypingChanged = { [weak self] in

            guard let self = self else { return }

            self.hideTypingRowWorkItem?.cancel()

            if self.viewModel.isOtherUserTyping {
                self.setTypingRowVisible(true)
                return
            }

            // Sending a message also stops "typing", and that update usually
            // lands just before the message itself. Wait for it.
            let workItem = DispatchWorkItem { [weak self] in
                self?.setTypingRowVisible(false)
            }

            self.hideTypingRowWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
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

    func tableView(
        _ tableView: UITableView,
        estimatedHeightForRowAt indexPath: IndexPath
    ) -> CGFloat {

        guard let itemId = dataSource.itemIdentifier(for: indexPath) else {
            return 50
        }

        if let height = rowHeights[itemId] {
            return height
        }

        return rowsById[itemId].map(estimatedHeight(for:)) ?? 50
    }

    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {

        guard let itemId = dataSource.itemIdentifier(for: indexPath) else { return }

        rowHeights[itemId] = cell.bounds.height

        if itemIdsToAnimate.remove(itemId) != nil {
            animateEntrance(of: cell)
        }
    }

    func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {

        // Clear any entrance animation cut short, so reused cells look right.
        cell.contentView.layer.removeAllAnimations()
        cell.contentView.alpha = 1
        cell.contentView.transform = .identity
    }

    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        keepPinnedToBottom()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {

        guard isScrollingToBottom else { return }

        isScrollingToBottom = false
        scrollToBottom(animated: true)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrollingToBottom = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let distanceFromBottom = bottomOffset.y - scrollView.contentOffset.y

        // Only you scrolling decides whether we stay pinned to the bottom.
        // Layout changes (first load, keyboard, rows resizing) also move the
        // offset, and must not unpin it.
        if scrollView.isDragging || scrollView.isDecelerating {
            isNearBottom = distanceFromBottom < 120
        }

        if isNearBottom {
            newMessagesWhileScrolledUp = 0
            scrollToBottomButton.unreadCount = 0
        }

        // Only offer the button once you're well away from the newest messages.
        scrollToBottomButton.setVisible(distanceFromBottom > 400)
    }

    // MARK: - Long-Press Menu

    func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {

        guard let itemId = dataSource.itemIdentifier(for: indexPath),
              let message = rowsById[itemId]?.message else {
            return nil
        }

        return UIContextMenuConfiguration(
            identifier: indexPath as NSIndexPath,
            previewProvider: nil
        ) { [weak self] _ in

            var actions: [UIAction] = []

            if !message.text.isEmpty {
                actions.append(
                    UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in
                        UIPasteboard.general.string = message.text
                    }
                )
            }

            if let image = self?.viewModel.image(for: message) {
                actions.append(
                    UIAction(title: "Copy Photo", image: UIImage(systemName: "photo")) { _ in
                        UIPasteboard.general.image = image
                    }
                )

                actions.append(
                    UIAction(title: "View Photo", image: UIImage(systemName: "arrow.up.left.and.arrow.down.right")) { _ in
                        self?.showImageViewer(image)
                    }
                )
            }

            return UIMenu(children: actions)
        }
    }

    /// Lifts just the bubble, not the whole row, when long-pressed.
    func tableView(
        _ tableView: UITableView,
        previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {

        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = tableView.cellForRow(at: indexPath) as? MessageCell else {
            return nil
        }

        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear

        return UITargetedPreview(view: cell.bubbleView, parameters: parameters)
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
