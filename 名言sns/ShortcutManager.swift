import Foundation
import Intents
import FirebaseAuth
import FirebaseFirestore

// Siri Shortcut用の名言取得機能
class ShortcutManager {
    static let shared = ShortcutManager()
    
    private init() {}
    
    /// ランダムな名言を取得してSiri Shortcutで使用
    func getRandomBookmarkedQuote(completion: @escaping (String) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid,
              !Auth.auth().currentUser!.isAnonymous else {
            completion("名言を見つけるにはアプリでブックマークをしてください")
            return
        }
        
        Firestore.firestore()
            .collection("quotes")
            .whereField("bookmarkedBy", arrayContains: userId)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion("名言の取得に失敗しました: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion("ブックマークした名言がありません。アプリで名言をブックマークしてください。")
                    return
                }
                
                let randomDoc = documents.randomElement()!
                let data = randomDoc.data()
                let text = data["text"] as? String ?? ""
                let author = data["author"] as? String ?? "匿名"
                
                let formattedQuote = "「\(text)」\n\n- \(author)"
                completion(formattedQuote)
            }
    }
    
    /// 今日のトップ名言を取得
    func getTodayTopQuote(completion: @escaping (String) -> Void) {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        Firestore.firestore()
            .collection("quotes")
            .whereField("createdAt", isGreaterThanOrEqualTo: today)
            .whereField("createdAt", isLessThan: tomorrow)
            .order(by: "likes", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion("今日の名言を取得できませんでした: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    completion("今日はまだ名言が投稿されていません")
                    return
                }
                
                let data = document.data()
                let text = data["text"] as? String ?? ""
                let author = data["author"] as? String ?? "匿名"
                let likes = data["likes"] as? Int ?? 0
                
                let formattedQuote = "【今日の人気名言】\n「\(text)」\n\n- \(author) (\(likes)いいね)"
                completion(formattedQuote)
            }
    }
}