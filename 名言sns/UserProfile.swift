import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var uid: String
    var displayName: String
    var bio: String // プロフィール説明
    var profileImageURL: String?
    var selectedBadges: [String] // 表示するバッジIDの配列（最大3つ）
    var allBadges: [String] // 獲得した全バッジIDの配列
    var postCount: Int
    var likesReceived: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(uid: String, displayName: String = "名無しさん") {
        self.uid = uid
        self.displayName = displayName
        self.bio = ""
        self.profileImageURL = nil
        self.selectedBadges = []
        self.allBadges = []
        self.postCount = 0
        self.likesReceived = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// バッジの定義
struct Badge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let condition: String // 獲得条件の説明
    
    static let allBadges = [
        Badge(id: "first_post", name: "初投稿", description: "初めて名言を投稿した", iconName: "star.fill", condition: "名言を1つ投稿する"),
        Badge(id: "daily_poster", name: "毎日投稿", description: "3日連続で投稿した", iconName: "calendar", condition: "3日連続で投稿する"),
        Badge(id: "like_collector", name: "いいね10個", description: "投稿でいいねを10個獲得", iconName: "heart.fill", condition: "いいねを10個獲得する"),
        Badge(id: "popular", name: "人気者", description: "投稿でいいねを50個獲得", iconName: "flame.fill", condition: "いいねを50個獲得する"),
        Badge(id: "wisdom_master", name: "名言マスター", description: "100回投稿を達成", iconName: "crown.fill", condition: "100回投稿する"),
        Badge(id: "early_adopter", name: "アーリーアダプター", description: "初期ユーザー", iconName: "leaf.fill", condition: "サービス開始から1ヶ月以内に登録"),
    ]
    
    static func getBadge(by id: String) -> Badge? {
        return allBadges.first { $0.id == id }
    }
}