//
//  Chat.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import Foundation
import FirebaseFirestore

/// One row of a user's inbox, stored at `users/{uid}/chats/{chatId}`.
/// Each person has their own copy, so their Home screen only reads
/// from their own inbox.
struct Chat {
    let id: String
    let otherUserId: String
    let lastMessage: String
    let lastMessageAt: Date?
    let lastSenderId: String?
    let unreadCount: Int
    let isOtherUserTyping: Bool
}

extension Chat {

    init?(
        id: String,
        dictionary: [String: Any]
    ) {

        guard let otherUserId = dictionary["otherUserId"] as? String else {
            return nil
        }

        self.init(
            id: id,
            otherUserId: otherUserId,
            lastMessage: dictionary["lastMessage"] as? String ?? "",
            lastMessageAt: (dictionary["lastMessageAt"] as? Timestamp)?.dateValue(),
            lastSenderId: dictionary["lastSenderId"] as? String,
            unreadCount: (dictionary["unreadCount"] as? NSNumber)?.intValue ?? 0,
            isOtherUserTyping: dictionary["isOtherUserTyping"] as? Bool ?? false
        )
    }
}
