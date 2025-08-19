import Foundation
import FirebaseFirestore

struct Reply: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var text: String
    var author: String
    var authorUid: String
    var authorDisplayName: String = ""  // プロフィール名
    var authorProfileImage: String = "" // プロフィール画像URL（将来実装用）
    var createdAt: Date = Date()
}
