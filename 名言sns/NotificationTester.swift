import Foundation
import UserNotifications
import FirebaseFirestore
import FirebaseAuth

class NotificationTester {
    static let shared = NotificationTester()
    
    private init() {}
    
    /// テスト用のローカル通知を送信（毎日のトップ名言の代替）
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "今日の名言"
        content.body = "「成功への道は、失敗への道でもある。重要なのは諦めないこと。」- 匿名"
        content.sound = UNNotificationSound.default
        
        // 30秒後に通知
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30, repeats: false)
        let request = UNNotificationRequest(identifier: "test-daily-quote", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("テスト通知エラー: \(error)")
            } else {
                print("テスト通知をスケジュールしました（30秒後）")
            }
        }
    }
    
    /// 今日のトップ名言を取得して通知
    func sendTodayTopQuoteNotification() {
        getTodayTopQuote { quote in
            let content = UNMutableNotificationContent()
            content.title = "今日の人気名言"
            content.body = quote
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "daily-top-quote", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("通知エラー: \(error)")
                } else {
                    print("今日のトップ名言通知を送信しました")
                }
            }
        }
    }
    
    private func getTodayTopQuote(completion: @escaping (String) -> Void) {
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
                    completion("今日の名言を取得できませんでした")
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
                
                completion("「\(text.prefix(80))\(text.count > 80 ? "..." : "")」- \(author) (\(likes)いいね)")
            }
    }
}