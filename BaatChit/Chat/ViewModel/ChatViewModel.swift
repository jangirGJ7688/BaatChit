//
//  ChatViewModel.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import UIKit
import FirebaseFirestore

/// One message plus how it sits next to its neighbours.
struct MessageRow: Equatable {
    let message: Message
    let isFromCurrentUser: Bool
    let isFirstInGroup: Bool
    let isLastInGroup: Bool

    var id: String { message.id }
}

/// All messages of one day, shown under a "Today" / "Yesterday" header.
struct MessageSection: Equatable {
    let id: String
    let title: String
    let rows: [MessageRow]
}

struct MessagesUpdate {
    let hasNewMessage: Bool
    let isNewMessageFromCurrentUser: Bool
}

final class ChatViewModel {

    // MARK: - Properties

    private(set) var otherUser: User

    private let currentUserId: String
    private let chatId: String
    private let chatService: ChatServiceProtocol
    private let userService: UserServiceProtocol

    private var listeners: [ListenerRegistration] = []

    private(set) var sections: [MessageSection] = []
    private(set) var isOtherUserTyping = false

    private var messages: [Message] = []
    private var isVisible = false
    private var isTyping = false
    private var typingTimer: Timer?
    private var messageIdsBeingMarkedRead = Set<String>()
    private var hasSyncedInbox = false

    // MARK: - Outputs

    var onMessagesUpdated: ((MessagesUpdate) -> Void)?
    var onHeaderUpdated: (() -> Void)?
    var onTypingChanged: (() -> Void)?
    var onError: ((String) -> Void)?

    /// "typing...", "online", "last seen today at 5:30 PM" or "".
    var statusText: String {

        if isOtherUserTyping {
            return "typing..."
        }

        if otherUser.isOnline {
            return "online"
        }

        if let lastSeen = otherUser.lastSeen {
            return "last seen \(lastSeen.lastSeenText)"
        }

        return ""
    }

    // MARK: - Init

    init(
        otherUser: User,
        currentUserId: String,
        chatService: ChatServiceProtocol = ChatService(),
        userService: UserServiceProtocol = UserService()
    ) {
        self.otherUser = otherUser
        self.currentUserId = currentUserId
        self.chatService = chatService
        self.userService = userService
        self.chatId = ChatService.chatId(
            for: currentUserId,
            and: otherUser.uid
        )
    }

    deinit {
        typingTimer?.invalidate()
        listeners.forEach { $0.remove() }
    }

    // MARK: - Listening

    func startListening() {

        listeners.forEach { $0.remove() }

        listeners = [

            chatService.listenForMessages(chatId: chatId) { [weak self] result in

                DispatchQueue.main.async {

                    guard let self = self else { return }

                    switch result {

                    case .success(let messages):

                        self.handleMessagesUpdate(messages)

                    case .failure(let error):

                        self.onError?(error.localizedDescription)
                    }
                }
            },

            chatService.listenForChat(
                chatId: chatId,
                userId: currentUserId
            ) { [weak self] result in

                DispatchQueue.main.async {

                    guard let self = self,
                          case .success(let chat) = result else { return }

                    let isOtherUserTyping = chat?.isOtherUserTyping ?? false

                    guard isOtherUserTyping != self.isOtherUserTyping else { return }

                    self.isOtherUserTyping = isOtherUserTyping
                    self.onHeaderUpdated?()
                    self.onTypingChanged?()
                }
            },

            userService.listenForUser(uid: otherUser.uid) { [weak self] result in

                DispatchQueue.main.async {

                    guard let self = self,
                          case .success(let user) = result else { return }

                    self.otherUser = user
                    self.onHeaderUpdated?()
                }
            }
        ]
    }

    /// Messages are only marked as seen while the chat is on screen.
    func setVisible(_ isVisible: Bool) {

        self.isVisible = isVisible

        if isVisible {
            markMessagesAsRead()
        } else {
            stopTyping()
        }
    }

    func image(for message: Message) -> UIImage? {

        guard let imageData = message.imageData else { return nil }

        return ImageCache.shared.image(
            forKey: "message-\(message.id)",
            data: imageData
        )
    }

    // MARK: - Sending

    func sendMessage(_ text: String) {

        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else { return }

        stopTyping()
        send(text: text, imageData: nil)
    }

    func sendImage(_ image: UIImage) {

        // A Firestore document can hold up to 1 MB, so keep photos well below.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in

            let imageData = image.jpegData(maxDimension: 1024, maxBytes: 600_000)

            DispatchQueue.main.async {

                guard let self = self else { return }

                guard let imageData = imageData else {
                    self.onError?("This photo is too large to send. Please try another one.")
                    return
                }

                self.send(text: "", imageData: imageData)
            }
        }
    }

    // MARK: - Typing

    func textDidChange(_ text: String) {

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            stopTyping()
            return
        }

        if !isTyping {
            isTyping = true
            chatService.setTyping(
                true,
                chatId: chatId,
                userId: currentUserId,
                otherUserId: otherUser.uid
            )
        }

        // Stop "typing..." after 3 seconds without a keystroke.
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(
            withTimeInterval: 3,
            repeats: false
        ) { [weak self] _ in
            self?.stopTyping()
        }
    }
}

private extension ChatViewModel {

    func handleMessagesUpdate(_ messages: [Message]) {

        let previousLastId = self.messages.last?.id
        let newLast = messages.last

        self.messages = messages
        sections = makeSections(from: messages)

        onMessagesUpdated?(
            MessagesUpdate(
                hasNewMessage: newLast != nil && newLast?.id != previousLastId,
                isNewMessageFromCurrentUser: newLast?.senderId == currentUserId
            )
        )

        syncInboxIfNeeded()
        markMessagesAsRead()
    }

    /// Once per visit, make sure this chat is in the inbox (for chats
    /// started before inboxes existed).
    func syncInboxIfNeeded() {

        guard !hasSyncedInbox,
              let lastMessage = messages.last,
              !lastMessage.isPending else { return }

        hasSyncedInbox = true

        chatService.syncInbox(
            with: lastMessage,
            chatId: chatId,
            userId: currentUserId,
            otherUserId: otherUser.uid
        )
    }

    func makeSections(from messages: [Message]) -> [MessageSection] {

        var sections: [MessageSection] = []
        var currentRows: [MessageRow] = []

        for (index, message) in messages.enumerated() {

            let previous = index > 0 ? messages[index - 1] : nil
            let next = index < messages.count - 1 ? messages[index + 1] : nil

            currentRows.append(
                MessageRow(
                    message: message,
                    isFromCurrentUser: message.senderId == currentUserId,
                    isFirstInGroup: previous.map { !isSameGroup($0, message) } ?? true,
                    isLastInGroup: next.map { !isSameGroup(message, $0) } ?? true
                )
            )

            let isLastOfDay = next.map {
                !Calendar.current.isDate($0.sentAt, inSameDayAs: message.sentAt)
            } ?? true

            if isLastOfDay {

                // Section ids must be unique for the table. Pending messages
                // can be slightly out of order around midnight.
                let dayKey = message.sentAt.dayKey
                let isDuplicateDay = sections.contains { $0.id == dayKey }

                sections.append(
                    MessageSection(
                        id: isDuplicateDay ? "\(dayKey)-\(sections.count)" : dayKey,
                        title: message.sentAt.daySectionTitle,
                        rows: currentRows
                    )
                )
                currentRows = []
            }
        }

        return sections
    }

    /// Messages from the same person within two minutes are grouped.
    func isSameGroup(_ first: Message, _ second: Message) -> Bool {

        first.senderId == second.senderId
        && Calendar.current.isDate(first.sentAt, inSameDayAs: second.sentAt)
        && second.sentAt.timeIntervalSince(first.sentAt) < 120
    }

    func send(
        text: String,
        imageData: Data?
    ) {

        chatService.sendMessage(
            text: text,
            imageData: imageData,
            chatId: chatId,
            senderId: currentUserId,
            receiverId: otherUser.uid
        ) { [weak self] error in

            guard let error = error else { return }

            DispatchQueue.main.async {
                self?.onError?(error.localizedDescription)
            }
        }
    }

    func stopTyping() {

        typingTimer?.invalidate()
        typingTimer = nil

        guard isTyping else { return }

        isTyping = false
        chatService.setTyping(
            false,
            chatId: chatId,
            userId: currentUserId,
            otherUserId: otherUser.uid
        )
    }

    func markMessagesAsRead() {

        guard isVisible else { return }

        let unreadIds = messages
            .filter {
                $0.senderId != currentUserId
                && !$0.isRead
                && !messageIdsBeingMarkedRead.contains($0.id)
            }
            .map(\.id)

        guard !unreadIds.isEmpty else { return }

        messageIdsBeingMarkedRead.formUnion(unreadIds)

        chatService.markMessagesAsRead(
            messageIds: unreadIds,
            chatId: chatId,
            userId: currentUserId,
            otherUserId: otherUser.uid
        ) { [weak self] error in

            guard error != nil else { return }

            // Allow another attempt on the next update.
            DispatchQueue.main.async {
                self?.messageIdsBeingMarkedRead.subtract(unreadIds)
            }
        }
    }
}
