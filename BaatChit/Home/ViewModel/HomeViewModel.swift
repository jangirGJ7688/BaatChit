//
//  HomeViewModel.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import Foundation
import FirebaseFirestore

struct ChatListItem: Equatable {
    let chatId: String
    let otherUser: User
    let lastMessage: String
    let lastMessageAt: Date?
    let unreadCount: Int
    let isOtherUserTyping: Bool
}

final class HomeViewModel {

    // MARK: - Properties

    private let userService: UserServiceProtocol
    private let chatService: ChatServiceProtocol

    private var listeners: [ListenerRegistration] = []

    private var currentUserId: String?
    private var chats: [Chat] = []
    private var usersById: [String: User] = [:]
    private var unreadCountByChatId: [String: Int] = [:]
    private var hasLoadedChats = false

    private(set) var items: [ChatListItem] = []
    private(set) var currentUser: User?
    private(set) var onlineUsers: [User] = []

    // MARK: - Outputs

    var onLoadingStateChange: ((Bool) -> Void)?
    var onItemsUpdated: (() -> Void)?
    var onCurrentUserUpdated: (() -> Void)?
    var onIncomingMessage: ((ChatListItem) -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Init

    init(
        userService: UserServiceProtocol = UserService(),
        chatService: ChatServiceProtocol = ChatService()
    ) {
        self.userService = userService
        self.chatService = chatService
    }

    deinit {
        listeners.forEach { $0.remove() }
    }

    // MARK: - Chats

    func startListening() {

        guard let currentUser = SessionManager.shared.currentUser else {
            return
        }

        currentUserId = currentUser.uid
        self.currentUser = currentUser
        onCurrentUserUpdated?()

        // Make sure the current user has a profile, so other users can
        // find them (covers accounts created before profiles existed).
        userService.saveUser(currentUser) { _ in }
        PresenceService.shared.setOnline(true)

        listeners.forEach { $0.remove() }

        onLoadingStateChange?(true)

        listeners = [

            userService.listenForUsers { [weak self] result in

                DispatchQueue.main.async {

                    guard let self = self else { return }

                    switch result {

                    case .success(let users):

                        self.usersById = Dictionary(
                            users.map { ($0.uid, $0) },
                            uniquingKeysWith: { first, _ in first }
                        )

                        self.onlineUsers = users.filter {
                            $0.isOnline && $0.uid != currentUser.uid
                        }

                        // Your own profile, for the photo in the top bar.
                        if let me = self.usersById[currentUser.uid],
                           me != self.currentUser {
                            self.currentUser = me
                            self.onCurrentUserUpdated?()
                        }

                        self.rebuildItems()

                    case .failure(let error):

                        self.onError?(error.localizedDescription)
                    }
                }
            },

            chatService.listenForChats(userId: currentUser.uid) { [weak self] result in

                DispatchQueue.main.async {

                    guard let self = self else { return }

                    switch result {

                    case .success(let chats):

                        self.handleChatsUpdate(chats)

                    case .failure(let error):

                        self.onError?(error.localizedDescription)
                    }

                    if !self.hasLoadedChats {
                        self.hasLoadedChats = true
                        self.onLoadingStateChange?(false)
                    }
                }
            }
        ]
    }
}

private extension HomeViewModel {

    func handleChatsUpdate(_ chats: [Chat]) {

        guard let currentUserId = currentUserId else { return }

        // A chat whose unread count went up has a new message for us.
        // Skipped on the first load, so old messages don't pop up.
        let incomingChatIds = hasLoadedChats
        ? chats
            .filter {
                $0.lastSenderId != currentUserId
                && $0.unreadCount > (unreadCountByChatId[$0.id] ?? 0)
            }
            .map(\.id)
        : []

        unreadCountByChatId = Dictionary(
            chats.map { ($0.id, $0.unreadCount) },
            uniquingKeysWith: { first, _ in first }
        )

        self.chats = chats
        rebuildItems()

        incomingChatIds.forEach { chatId in

            if let item = items.first(where: { $0.chatId == chatId }) {
                onIncomingMessage?(item)
            }
        }
    }

    func rebuildItems() {

        guard let currentUserId = currentUserId else { return }

        items = chats.compactMap { chat in

            // A row with only "typing..." and no message yet isn't a chat yet.
            guard chat.lastMessageAt != nil else { return nil }

            let otherUserId = chat.otherUserId

            // Show the chat even if the profile hasn't loaded yet.
            let otherUser = usersById[otherUserId] ?? User(
                uid: otherUserId,
                email: "",
                name: "BaatChit User"
            )

            let lastMessage = chat.lastSenderId == currentUserId
            ? "You: \(chat.lastMessage)"
            : chat.lastMessage

            return ChatListItem(
                chatId: chat.id,
                otherUser: otherUser,
                lastMessage: lastMessage,
                lastMessageAt: chat.lastMessageAt,
                unreadCount: chat.unreadCount,
                isOtherUserTyping: chat.isOtherUserTyping
            )
        }

        onItemsUpdated?()
    }
}
