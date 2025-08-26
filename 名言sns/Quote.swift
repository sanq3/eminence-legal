
import Foundation
import FirebaseFirestore

// Firestoreと連携するための名言データ構造
struct Quote: Identifiable, Codable, Hashable {
    @DocumentID var id: String? // FirestoreのドキュメントID（自動管理）
    var text: String = "" // 名言の本文
    var author: String = "" // 作者名（名言の作者）
    var likes: Int = 0 // いいねの数
    var likedBy: [String] = [] // いいねしたユーザーのIDリスト
    var bookmarkedBy: [String]? // ブックマークしたユーザーのIDリスト（古いデータ用にオプショナル）
    var replyCount: Int? // リプライの数（古いデータ用にオプショナル）
    var authorUid: String? // 投稿者のUID（匿名認証含む）- 古いデータ用にオプショナル
    var authorDisplayName: String = "" // 投稿者のプロフィール名
    var authorProfileImage: String? = "" // 投稿者のプロフィール画像URL（オプショナル）
    var authorBadges: [String]? = [] // 投稿者のバッジリスト（チェックマーク表示用）
    var createdAt: Date = Date() // 投稿日時
    
    // デフォルト値を返すヘルパーメソッド
    var bookmarkedByArray: [String] {
        return bookmarkedBy ?? []
    }
    
    var replyCountValue: Int {
        return replyCount ?? 0
    }
    
    var authorUidValue: String {
        return authorUid ?? ""
    }
}
