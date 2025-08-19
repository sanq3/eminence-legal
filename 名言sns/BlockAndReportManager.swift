import Foundation
import FirebaseFirestore
import FirebaseAuth

// ブロックと報告機能を管理するクラス
class BlockAndReportManager: ObservableObject {
    private let db = Firestore.firestore()
    @Published var blockedUsers: Set<String> = []
    
    init() {
        loadBlockedUsers()
    }
    
    // MARK: - ブロック機能
    
    // ブロックしたユーザーを読み込む
    func loadBlockedUsers() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let data = snapshot?.data(),
               let blocked = data["blockedUsers"] as? [String] {
                self?.blockedUsers = Set(blocked)
            }
        }
    }
    
    // ユーザーをブロック
    func blockUser(_ targetUserId: String, completion: @escaping (Bool, String) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, "ログインが必要です")
            return
        }
        
        guard userId != targetUserId else {
            completion(false, "自分自身はブロックできません")
            return
        }
        
        db.collection("users").document(userId).setData([
            "blockedUsers": FieldValue.arrayUnion([targetUserId])
        ], merge: true) { [weak self] error in
            if let error = error {
                print("Block error: \(error)")
                completion(false, "ブロックに失敗しました")
            } else {
                self?.blockedUsers.insert(targetUserId)
                completion(true, "ユーザーをブロックしました")
            }
        }
    }
    
    // ブロック解除
    func unblockUser(_ targetUserId: String, completion: @escaping (Bool, String) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, "ログインが必要です")
            return
        }
        
        db.collection("users").document(userId).setData([
            "blockedUsers": FieldValue.arrayRemove([targetUserId])
        ], merge: true) { [weak self] error in
            if let error = error {
                print("Unblock error: \(error)")
                completion(false, "ブロック解除に失敗しました")
            } else {
                self?.blockedUsers.remove(targetUserId)
                completion(true, "ブロックを解除しました")
            }
        }
    }
    
    // ユーザーがブロックされているか確認
    func isUserBlocked(_ userId: String) -> Bool {
        return blockedUsers.contains(userId)
    }
    
    // MARK: - 報告機能
    
    // 投稿を報告
    func reportQuote(_ quoteId: String, reason: ReportReason, additionalInfo: String? = nil, completion: @escaping (Bool, String) -> Void) {
        let reporterId = Auth.auth().currentUser?.uid ?? "anonymous"
        
        let reportData: [String: Any] = [
            "quoteId": quoteId,
            "reporterId": reporterId,
            "reason": reason.rawValue,
            "additionalInfo": additionalInfo ?? "",
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("reports").addDocument(data: reportData) { error in
            if let error = error {
                print("Report error: \(error)")
                completion(false, "報告の送信に失敗しました")
            } else {
                completion(true, "報告を送信しました。確認後、適切に対処いたします。")
            }
        }
    }
    
    // ユーザーを報告
    func reportUser(_ userId: String, reason: ReportReason, additionalInfo: String? = nil, completion: @escaping (Bool, String) -> Void) {
        let reporterId = Auth.auth().currentUser?.uid ?? "anonymous"
        
        let reportData: [String: Any] = [
            "reportedUserId": userId,
            "reporterId": reporterId,
            "reason": reason.rawValue,
            "additionalInfo": additionalInfo ?? "",
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("reports").addDocument(data: reportData) { error in
            if let error = error {
                print("Report user error: \(error)")
                completion(false, "報告の送信に失敗しました")
            } else {
                completion(true, "報告を送信しました。確認後、適切に対処いたします。")
            }
        }
    }
}

// 報告理由の列挙型
enum ReportReason: String, CaseIterable {
    case spam = "スパム"
    case harassment = "嫌がらせ・いじめ"
    case inappropriate = "不適切なコンテンツ"
    case violence = "暴力的な内容"
    case misinformation = "誤情報"
    case copyright = "著作権侵害"
    case other = "その他"
    
    var description: String {
        return self.rawValue
    }
}