import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var unreadCount = 0
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    deinit {
        listenerRegistration?.remove()
    }
    
    // MARK: - 通知の監視を開始
    func startListening() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              !(Auth.auth().currentUser?.isAnonymous ?? true) else {
            print(" Anonymous user, not listening for notifications")
            return
        }
        
        print(" Starting notification listener for userId: \(currentUserId)")
        print("🔍 Query: collection('notifications').whereField('toUserId', isEqualTo: '\(currentUserId)')")
        isLoading = true
        
        listenerRegistration = db.collection("notifications")
            .whereField("toUserId", isEqualTo: currentUserId)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print(" Error listening to notifications: \(error)")
                        self?.errorMessage = "通知の読み込みに失敗しました"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print(" No notification documents")
                        return
                    }
                    
                    print("📬 通知受信: \(documents.count)件 (ユーザー: \(currentUserId))")
                    
                    // 各ドキュメントの詳細をログ出力
                    for (index, doc) in documents.enumerated() {
                        let data = doc.data()
                        print("📄 Document \(index): ID=\(doc.documentID)")
                        print("   - toUserId: \(data["toUserId"] as? String ?? "nil")")
                        print("   - type: \(data["type"] as? String ?? "nil")")
                        print("   - fromUserName: \(data["fromUserName"] as? String ?? "nil")")
                    }
                    
                    let notifications = documents.compactMap { doc -> AppNotification? in
                        do {
                            var notification = try doc.data(as: AppNotification.self)
                            notification.id = doc.documentID
                            return notification
                        } catch {
                            print(" Error decoding notification: \(error)")
                            return nil
                        }
                    }
                    
                    // アプリ側でソート（新しい順）
                    let sortedNotifications = notifications.sorted { $0.createdAt > $1.createdAt }
                    self?.notifications = sortedNotifications
                    self?.updateUnreadCount()
                    
                    print("📱 通知一覧更新: \(sortedNotifications.count)件表示")
                }
            }
    }
    
    // MARK: - 通知の監視を停止
    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
        print(" Stopped notification listener")
    }
    
    // MARK: - 未読数を更新
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
        print(" Unread notifications count: \(unreadCount)")
    }
    
    // MARK: - 通知を既読にする
    func markAsRead(_ notification: AppNotification) {
        guard let notificationId = notification.id else { return }
        
        db.collection("notifications").document(notificationId).updateData([
            "isRead": true
        ]) { error in
            if let error = error {
                print(" Error marking notification as read: \(error)")
            } else {
                print(" Marked notification as read: \(notificationId)")
            }
        }
    }
    
    // MARK: - 全ての通知を既読にする
    func markAllAsRead() {
        let unreadNotifications = notifications.filter { !$0.isRead }
        
        let batch = db.batch()
        for notification in unreadNotifications {
            if let id = notification.id {
                let ref = db.collection("notifications").document(id)
                batch.updateData(["isRead": true], forDocument: ref)
            }
        }
        
        batch.commit { error in
            if let error = error {
                print(" Error marking all notifications as read: \(error)")
            } else {
                print(" Marked all notifications as read")
            }
        }
    }
    
    // MARK: - いいね通知を作成
    static func createLikeNotification(
        fromUserId: String,
        fromUserName: String,
        fromUserProfileImage: String?,
        toUserId: String,
        quoteId: String,
        quoteText: String
    ) {
        // 自分自身への通知は作成しない
        guard fromUserId != toUserId else { return }
        
        // 匿名ユーザーは通知を受け取らない
        guard !toUserId.isEmpty else { return }
        
        let notification = AppNotification.createLikeNotification(
            fromUserId: fromUserId,
            fromUserName: fromUserName,
            fromUserProfileImage: fromUserProfileImage,
            toUserId: toUserId,
            quoteId: quoteId,
            quoteText: quoteText
        )
        
        saveNotification(notification)
    }
    
    // MARK: - リプライ通知を作成
    static func createReplyNotification(
        fromUserId: String,
        fromUserName: String,
        fromUserProfileImage: String?,
        toUserId: String,
        quoteId: String,
        quoteText: String,
        replyText: String
    ) {
        // 自分自身への通知は作成しない
        guard fromUserId != toUserId else { return }
        
        // 匿名ユーザーは通知を受け取らない
        guard !toUserId.isEmpty else { return }
        
        let notification = AppNotification.createReplyNotification(
            fromUserId: fromUserId,
            fromUserName: fromUserName,
            fromUserProfileImage: fromUserProfileImage,
            toUserId: toUserId,
            quoteId: quoteId,
            quoteText: quoteText,
            replyText: replyText
        )
        
        saveNotification(notification)
    }
    
    // MARK: - Firestoreに通知を保存
    private static func saveNotification(_ notification: AppNotification) {
        let db = Firestore.firestore()
        
        print("💾 通知をFirestoreに保存中: \(notification.type) -> \(notification.toUserId)")
        do {
            _ = try db.collection("notifications").addDocument(from: notification)
            print("✅ 通知保存成功: \(notification.type)")
        } catch {
            print("❌ 通知保存エラー: \(error)")
        }
    }
    
    // MARK: - テスト用通知作成
    static func createTestNotification(toUserId: String) {
        let testNotification = AppNotification(
            type: .like,
            message: "テストユーザーさんがあなたの名言にいいねしました",
            fromUserId: "test-user",
            fromUserName: "テストユーザー",
            fromUserProfileImage: nil,
            toUserId: toUserId,
            relatedQuoteId: "test-quote",
            relatedQuoteText: "これはテスト投稿です",
            replyText: nil,
            isRead: false
        )
        
        print("🧪 テスト通知を作成中: test-user -> \(toUserId)")
        saveNotification(testNotification)
    }
    
    // MARK: - 現在のユーザーにテスト通知を作成
    static func createTestNotificationForCurrentUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              !(Auth.auth().currentUser?.isAnonymous ?? true) else {
            print("❌ ログインユーザーが見つからないため、テスト通知をスキップ")
            return
        }
        
        print("🧪 現在のユーザーにテスト通知作成: \(currentUserId)")
        createTestNotification(toUserId: currentUserId)
    }
    
    // MARK: - その他の機能
    func fetchNotifications() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              !(Auth.auth().currentUser?.isAnonymous ?? true) else {
            print(" Anonymous user, not fetching notifications")
            return
        }
        
        isLoading = true
        
        db.collection("notifications")
            .whereField("toUserId", isEqualTo: currentUserId)
            .limit(to: 50)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print(" Error fetching notifications: \(error)")
                        self?.errorMessage = "通知の読み込みに失敗しました"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print(" No notification documents")
                        return
                    }
                    
                    let notifications = documents.compactMap { doc -> AppNotification? in
                        do {
                            var notification = try doc.data(as: AppNotification.self)
                            notification.id = doc.documentID
                            return notification
                        } catch {
                            print(" Error decoding notification: \(error)")
                            return nil
                        }
                    }
                    
                    // アプリ側でソート（新しい順）
                    let sortedNotifications = notifications.sorted { $0.createdAt > $1.createdAt }
                    self?.notifications = sortedNotifications
                    self?.updateUnreadCount()
                }
            }
    }
    
    func refreshNotifications() async {
        await MainActor.run {
            fetchNotifications()
        }
    }
    
    // 特定のQuoteをIDで取得
    func fetchQuoteById(_ quoteId: String, completion: @escaping (Quote?) -> Void) {
        db.collection("quotes").document(quoteId).getDocument { document, error in
            if let error = error {
                print(" Error fetching quote: \(error)")
                completion(nil)
                return
            }
            
            guard let document = document, document.exists else {
                completion(nil)
                return
            }
            
            do {
                var quote = try document.data(as: Quote.self)
                quote.id = document.documentID
                completion(quote)
            } catch {
                print(" Error decoding quote: \(error)")
                completion(nil)
            }
        }
    }
    
    func clearAllData() {
        notifications = []
        unreadCount = 0
        errorMessage = nil
        stopListening()
        print(" All notification data cleared")
    }
}