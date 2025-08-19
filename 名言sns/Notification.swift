import Foundation
import FirebaseFirestore

struct AppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    let type: NotificationType
    let message: String
    let fromUserId: String
    let fromUserName: String
    let fromUserProfileImage: String?
    let toUserId: String
    let relatedQuoteId: String?
    let relatedQuoteText: String?
    let replyText: String? // リプライの内容
    let createdAt: Date
    var isRead: Bool
    
    enum NotificationType: String, Codable, CaseIterable {
        case like = "like"
        case reply = "reply"
        case follow = "follow" // 将来用
        
        var icon: String {
            switch self {
            case .like:
                return "heart.fill"
            case .reply:
                return "text.bubble"
            case .follow:
                return "person.badge.plus"
            }
        }
        
        var color: String {
            switch self {
            case .like:
                return "pink"
            case .reply:
                return "blue"
            case .follow:
                return "green"
            }
        }
    }
    
    init(
        type: NotificationType,
        message: String,
        fromUserId: String,
        fromUserName: String,
        fromUserProfileImage: String? = nil,
        toUserId: String,
        relatedQuoteId: String? = nil,
        relatedQuoteText: String? = nil,
        replyText: String? = nil,
        isRead: Bool = false
    ) {
        self.type = type
        self.message = message
        self.fromUserId = fromUserId
        self.fromUserName = fromUserName
        self.fromUserProfileImage = fromUserProfileImage
        self.toUserId = toUserId
        self.relatedQuoteId = relatedQuoteId
        self.relatedQuoteText = relatedQuoteText
        self.replyText = replyText
        self.createdAt = Date()
        self.isRead = isRead
    }
}

// 通知作成用のヘルパー関数
extension AppNotification {
    static func createLikeNotification(
        fromUserId: String,
        fromUserName: String,
        fromUserProfileImage: String?,
        toUserId: String,
        quoteId: String,
        quoteText: String
    ) -> AppNotification {
        let message = "\(fromUserName)さんがあなたの名言にいいねしました"
        return AppNotification(
            type: .like,
            message: message,
            fromUserId: fromUserId,
            fromUserName: fromUserName,
            fromUserProfileImage: fromUserProfileImage,
            toUserId: toUserId,
            relatedQuoteId: quoteId,
            relatedQuoteText: quoteText
        )
    }
    
    static func createReplyNotification(
        fromUserId: String,
        fromUserName: String,
        fromUserProfileImage: String?,
        toUserId: String,
        quoteId: String,
        quoteText: String,
        replyText: String
    ) -> AppNotification {
        let message = "\(fromUserName)さんが返信しました"
        return AppNotification(
            type: .reply,
            message: message,
            fromUserId: fromUserId,
            fromUserName: fromUserName,
            fromUserProfileImage: fromUserProfileImage,
            toUserId: toUserId,
            relatedQuoteId: quoteId,
            relatedQuoteText: quoteText,
            replyText: replyText
        )
    }
}