//
//  ChatService.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import Foundation
import FirebaseFirestore

protocol ChatServiceProtocol {

    func listenForChats(
        userId: String,
        onChange: @escaping(Result<[Chat], Error>) -> Void
    ) -> ListenerRegistration

    func listenForChat(
        chatId: String,
        userId: String,
        onChange: @escaping(Result<Chat?, Error>) -> Void
    ) -> ListenerRegistration

    func listenForMessages(
        chatId: String,
        onChange: @escaping(Result<[Message], Error>) -> Void
    ) -> ListenerRegistration

    func sendMessage(
        text: String,
        imageData: Data?,
        chatId: String,
        senderId: String,
        receiverId: String,
        completion: @escaping(Error?) -> Void
    )

    func markMessagesAsRead(
        messageIds: [String],
        chatId: String,
        userId: String,
        otherUserId: String,
        completion: @escaping(Error?) -> Void
    )

    func setTyping(
        _ isTyping: Bool,
        chatId: String,
        userId: String,
        otherUserId: String
    )

    func syncInbox(
        with lastMessage: Message,
        chatId: String,
        userId: String,
        otherUserId: String
    )
}

final class ChatService: ChatServiceProtocol {

    private let db = Firestore.firestore()

    /// Both users get the same chat id, whichever of them opens the chat.
    static func chatId(
        for firstUserId: String,
        and secondUserId: String
    ) -> String {

        [firstUserId, secondUserId]
            .sorted()
            .joined(separator: "_")
    }

    // MARK: - Listeners

    func listenForChats(
        userId: String,
        onChange: @escaping(Result<[Chat], Error>) -> Void
    ) -> ListenerRegistration {

        // Sorted here rather than with `order(by:)`, so inbox rows that
        // don't have a message yet (only "typing...") aren't left out.
        inboxCollection(for: userId).addSnapshotListener { snapshot, error in

            if let error = error {
                onChange(.failure(error))
                return
            }

            let chats = (snapshot?.documents ?? [])
                .compactMap { Chat(id: $0.documentID, dictionary: $0.data(with: .estimate)) }
                .sorted {
                    ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast)
                }

            onChange(.success(chats))
        }
    }

    func listenForChat(
        chatId: String,
        userId: String,
        onChange: @escaping(Result<Chat?, Error>) -> Void
    ) -> ListenerRegistration {

        inboxCollection(for: userId).document(chatId).addSnapshotListener { snapshot, error in

            if let error = error {
                onChange(.failure(error))
                return
            }

            let chat = snapshot?.data(with: .estimate).flatMap {
                Chat(id: chatId, dictionary: $0)
            }

            onChange(.success(chat))
        }
    }

    func listenForMessages(
        chatId: String,
        onChange: @escaping(Result<[Message], Error>) -> Void
    ) -> ListenerRegistration {

        // Metadata changes tell us when a pending message reaches the server.
        messagesCollection(for: chatId)
            .order(by: "sentAt")
            .limit(toLast: 200)
            .addSnapshotListener(includeMetadataChanges: true) { snapshot, error in

                if let error = error {
                    onChange(.failure(error))
                    return
                }

                // `.estimate` gives messages that are still being sent a
                // local time, so they show up immediately.
                let messages = (snapshot?.documents ?? []).compactMap {
                    Message(
                        id: $0.documentID,
                        dictionary: $0.data(with: .estimate),
                        isPending: $0.metadata.hasPendingWrites
                    )
                }

                onChange(.success(messages))
            }
    }

    // MARK: - Writes

    func sendMessage(
        text: String,
        imageData: Data?,
        chatId: String,
        senderId: String,
        receiverId: String,
        completion: @escaping(Error?) -> Void
    ) {

        var messageData: [String: Any] = [
            "senderId": senderId,
            "text": text,
            "isRead": false,
            "sentAt": FieldValue.serverTimestamp()
        ]

        if let imageData = imageData {
            messageData["imageData"] = imageData
        }

        let summary: [String: Any] = [
            "lastMessage": imageData == nil ? text : "📷 Photo",
            "lastMessageAt": FieldValue.serverTimestamp(),
            "lastSenderId": senderId
        ]

        let batch = db.batch()

        batch.setData(
            messageData,
            forDocument: messagesCollection(for: chatId).document()
        )

        // The message and both inboxes are saved together, so Home always
        // matches the chat.
        batch.setData(
            summary.merging([
                "otherUserId": receiverId
            ]) { current, _ in current },
            forDocument: inboxCollection(for: senderId).document(chatId),
            merge: true
        )

        batch.setData(
            summary.merging([
                "otherUserId": senderId,
                "unreadCount": FieldValue.increment(Int64(1)),
                "isOtherUserTyping": false
            ]) { current, _ in current },
            forDocument: inboxCollection(for: receiverId).document(chatId),
            merge: true
        )

        batch.commit { error in
            completion(error)
        }
    }

    func markMessagesAsRead(
        messageIds: [String],
        chatId: String,
        userId: String,
        otherUserId: String,
        completion: @escaping(Error?) -> Void
    ) {

        let batch = db.batch()

        messageIds.forEach {
            batch.updateData(
                ["isRead": true],
                forDocument: messagesCollection(for: chatId).document($0)
            )
        }

        batch.setData(
            [
                "otherUserId": otherUserId,
                "unreadCount": 0
            ],
            forDocument: inboxCollection(for: userId).document(chatId),
            merge: true
        )

        batch.commit { error in
            completion(error)
        }
    }

    /// Shown in the other person's inbox, so their Home and chat screens
    /// can both show "typing...".
    func setTyping(
        _ isTyping: Bool,
        chatId: String,
        userId: String,
        otherUserId: String
    ) {

        inboxCollection(for: otherUserId).document(chatId).setData(
            [
                "otherUserId": userId,
                "isOtherUserTyping": isTyping
            ],
            merge: true
        )
    }

    /// Fills in the inbox row for chats from before inboxes existed, so
    /// they show up on Home without waiting for a new message.
    func syncInbox(
        with lastMessage: Message,
        chatId: String,
        userId: String,
        otherUserId: String
    ) {

        inboxCollection(for: userId).document(chatId).setData(
            [
                "otherUserId": otherUserId,
                "lastMessage": lastMessage.imageData == nil ? lastMessage.text : "📷 Photo",
                "lastMessageAt": Timestamp(date: lastMessage.sentAt),
                "lastSenderId": lastMessage.senderId
            ],
            merge: true
        )
    }
}

private extension ChatService {

    func inboxCollection(for userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("chats")
    }

    func messagesCollection(for chatId: String) -> CollectionReference {
        db.collection("chats").document(chatId).collection("messages")
    }
}
