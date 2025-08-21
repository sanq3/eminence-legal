
import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class QuoteViewModel: ObservableObject {
    @Published var quotes = [Quote]()
    @Published var replies = [Reply]()
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMoreData = true
    
    private var db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 5 // 🚨 PRODUCTION FIX: 20→5に削減してコスト削減
    private var listener: ListenerRegistration?
    private let badgeManager = BadgeManager()
    private let blockReportManager = BlockAndReportManager()

    func signInAnonymouslyIfNeeded() {
        if Auth.auth().currentUser == nil {
            print("Attempting anonymous sign-in from ViewModel...")
            Auth.auth().signInAnonymously { [weak self] authResult, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("ViewModel - DETAILED ERROR: \(error)")
                        print("ViewModel - Error code: \((error as NSError).code)")
                        print("ViewModel - Error domain: \((error as NSError).domain)")
                        // Firebase認証エラーをログ出力
                        print("Firebase Auth: ViewModel authentication failed - \(error)")
                        
                        // 認証が必要な機能のためにユーザーにメッセージ表示
                        self?.errorMessage = "接続中です。しばらくお待ちください。"
                    } else {
                        print("ViewModel - 匿名サインインに成功しました: UID - \(authResult?.user.uid ?? "N/A")")
                        self?.errorMessage = nil
                    }
                }
            }
        } else {
            print("User already signed in: \(Auth.auth().currentUser?.uid ?? "N/A")")
        }
    }

    // データを読み込む（リアルタイム更新を削除してコスト削減）
    func fetchData() {
        isLoading = true
        errorMessage = nil
        lastDocument = nil
        hasMoreData = true
        
        // ブロックリストを再読み込み
        blockReportManager.loadBlockedUsers()
        
        // 🚨 PRODUCTION FIX: リアルタイムリスナーをワンタイム取得に変更
        // リアルタイムリスナーはコストが高く、100ユーザーで月額数万円になる可能性
        // 既存のリスナーがあれば削除
        listener?.remove()
        
        
        // ワンタイム取得（リアルタイム更新なし）
        db.collection("quotes")
            .order(by: "createdAt", descending: true)
            .limit(to: 10) // 🚨 50→10に削減してパフォーマンス向上
            .getDocuments { [weak self] (querySnapshot, error) in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        // ネットワークエラーを判定
                        let nsError = error as NSError
                        if nsError.domain == NSURLErrorDomain {
                            switch nsError.code {
                            case NSURLErrorNotConnectedToInternet:
                                self?.errorMessage = "インターネットに接続されていません。\n接続を確認してください。"
                            case NSURLErrorTimedOut:
                                self?.errorMessage = "接続がタイムアウトしました。\nもう一度お試しください。"
                            default:
                                self?.errorMessage = "ネットワークエラーが発生しました。\nもう一度お試しください。"
                            }
                        } else {
                            self?.errorMessage = "データの読み込みに失敗しました。\nもう一度お試しください。"
                        }
                        print("Error loading quotes: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        self?.errorMessage = "データが見つかりませんでした。"
                        print("No documents")
                        return
                    }
                    
                    let newQuotes = documents.compactMap { queryDocumentSnapshot -> Quote? in
                        try? queryDocumentSnapshot.data(as: Quote.self)
                    }
                    
                    // ブロックしたユーザーの投稿をフィルタリング
                    let filteredQuotes = newQuotes.filter { quote in
                        !(self?.blockReportManager.isUserBlocked(quote.authorUid) ?? false)
                    }
                    
                    self?.quotes = filteredQuotes
                    self?.lastDocument = documents.last
                    self?.hasMoreData = documents.count >= 10
                    
                    print("📊 Loaded \(newQuotes.count) quotes (cost-optimized)")
                }
            }
    }
    
    // 追加データを読み込む（無限スクロール）
    func loadMoreData() {
        guard !isLoadingMore, hasMoreData, let lastDoc = lastDocument else { return }
        
        isLoadingMore = true
        
        db.collection("quotes")
            .order(by: "createdAt", descending: true)
            .start(afterDocument: lastDoc)
            .limit(to: 5) // 🚨 PRODUCTION FIX: 無限スクロール1回につき5件
            .getDocuments { [weak self] (querySnapshot, error) in
                DispatchQueue.main.async {
                    self?.isLoadingMore = false
                    
                    if let error = error {
                        print("Error loading more data: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        self?.hasMoreData = false
                        return
                    }
                    
                    let newQuotes = documents.compactMap { queryDocumentSnapshot -> Quote? in
                        try? queryDocumentSnapshot.data(as: Quote.self)
                    }
                    
                    // ブロックしたユーザーの投稿をフィルタリング
                    let filteredQuotes = newQuotes.filter { quote in
                        !(self?.blockReportManager.isUserBlocked(quote.authorUid) ?? false)
                    }
                    
                    self?.quotes.append(contentsOf: filteredQuotes)
                    self?.lastDocument = documents.last
                    self?.hasMoreData = documents.count == self?.pageSize
                }
            }
    }

    // データを追加する
    func addData(quote: Quote, userProfile: UserProfile? = nil) {
        errorMessage = nil
        var newQuote = quote
        
        // 🚨 PRODUCTION FIX: セキュリティ強化
        guard let currentUser = Auth.auth().currentUser else {
            print("User not authenticated for posting")
            self.errorMessage = "認証処理中です。投稿できません。"
            return
        }
        
        // コンテンツの適切性チェック
        let moderationResult = ContentModerationService.shared.isContentAppropriate(newQuote.text)
        if !moderationResult.isAppropriate {
            errorMessage = moderationResult.reason ?? "投稿内容が不適切です"
            return
        }
        
        // 作者名もチェック
        if !newQuote.author.isEmpty {
            let authorModeration = ContentModerationService.shared.isContentAppropriate(newQuote.author)
            if !authorModeration.isAppropriate {
                errorMessage = "作者名が不適切です"
                return
            }
        }
        
        // 匿名ユーザーの投稿頻度制限（スパム防止）
        if currentUser.isAnonymous {
            // 実装例：匿名ユーザーは1日5投稿まで等の制限を追加可能
            print("⚠️ SECURITY: Anonymous user posting (consider rate limiting)")
        }
        
        newQuote.authorUid = currentUser.uid
        
        // ログイン済みユーザーの場合、プロフィール情報を設定
        let isLoggedIn = Auth.auth().currentUser?.isAnonymous == false
        if isLoggedIn {
            // 作者名が空白の場合、プロフィール名を使用
            if newQuote.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                newQuote.author = userProfile?.displayName ?? "名無しさん"
            }
            // プロフィール情報を設定
            newQuote.authorDisplayName = userProfile?.displayName ?? ""
            newQuote.authorProfileImage = userProfile?.profileImageURL
            newQuote.authorBadges = userProfile?.allBadges ?? []
        } else {
            // 未ログインユーザーは作者名が空白なら匿名
            if newQuote.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                newQuote.author = "匿名"
            }
        }
        
#if DEBUG
        print("Adding quote with authenticated user ID: \(currentUser.uid)")
        print("Quote data being saved:")
        print("  - text: '\(newQuote.text)'")
        print("  - author: '\(newQuote.author)'")
        print("  - authorUid: '\(newQuote.authorUid)'")
        print("  - authorDisplayName: '\(newQuote.authorDisplayName)'")
        #endif
        
        var documentData: [String: Any] = [
            "text": newQuote.text,
            "author": newQuote.author,
            "authorUid": newQuote.authorUid,
            "authorDisplayName": newQuote.authorDisplayName,
            "likes": newQuote.likes,
            "likedBy": newQuote.likedBy,
            "bookmarkedBy": newQuote.bookmarkedByArray,
            "replyCount": newQuote.replyCountValue,
            "createdAt": newQuote.createdAt
        ]
        
        // authorProfileImageが存在する場合のみ追加
        if let profileImage = newQuote.authorProfileImage, !profileImage.isEmpty {
            documentData["authorProfileImage"] = profileImage
        }
        
        let _ = db.collection("quotes").addDocument(data: documentData) { [weak self] error in
            if let error = error {
                print("Error saving quote: \(error)")
                DispatchQueue.main.async {
                    self?.errorMessage = "データの追加に失敗しました: \(error.localizedDescription)"
                }
            } else {
                DispatchQueue.main.async {
                    // 投稿成功時、データを再取得してUI更新
                    self?.fetchData()
                    
                    // 投稿成功時、プロフィールの投稿数を更新
                    if isLoggedIn, let profile = userProfile {
                        NotificationCenter.default.post(name: NSNotification.Name("UpdateProfilePostCount"), object: nil)
                        // バッジ獲得チェック
                        if let userId = Auth.auth().currentUser?.uid {
                            self?.checkAndAwardBadges(userId: userId)
                        }
                    } else {
                    }
                }
            }
        }
    }
    
    /// 名言を更新する
    func updateData(quote: Quote) {
        errorMessage = nil
        guard let documentId = quote.id else { return }
        do {
            try db.collection("quotes").document(documentId).setData(from: quote, merge: true)
        } catch {
            self.errorMessage = "データの更新に失敗しました: \(error.localizedDescription)"
            print(error)
        }
    }
    
    /// 名言を削除する
    func deleteData(quote: Quote) {
        errorMessage = nil
        guard let documentId = quote.id else { return }
        
        db.collection("quotes").document(documentId).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "データの削除に失敗しました: \(error.localizedDescription)"
                    print(error)
                } else {
                    // 削除成功時にローカルの配列からも削除
                    self?.quotes.removeAll { $0.id == documentId }
                    print("✅ 投稿を削除しました: \(documentId)")
                }
            }
        }
    }
    
    // いいねを更新する
    func likeQuote(quote: Quote) {
        errorMessage = nil
        guard let documentId = quote.id else { 
            print("ERROR: Quote ID is nil")
            return 
        }
        // 匿名認証が有効化されたので、認証必須に変更
        guard let userId = Auth.auth().currentUser?.uid else {
            print("ERROR: User not authenticated - this should not happen with anonymous auth enabled")
            self.errorMessage = "認証処理中です。しばらくお待ちください。"
            return
        }
#if DEBUG
        print("Using authenticated user ID: \(userId)")
        print("Liking quote with ID: \(documentId), User: \(userId)")
        #endif

        let quoteRef = db.collection("quotes").document(documentId)
        
        // まず簡単なテスト: ドキュメントが存在するか確認
        quoteRef.getDocument { [weak self] (document, error) in
            if let error = error {
                print("Error fetching document: \(error)")
                return
            }
            if document?.exists != true {
                return
            }
        }

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let quoteDocument: DocumentSnapshot
            do {
                quoteDocument = try transaction.getDocument(quoteRef)
            } catch let fetchError as NSError {
                print("Failed to fetch document: \(fetchError)")
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let quoteData = try? quoteDocument.data(as: Quote.self) else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "ドキュメントのデコードに失敗しました"
                ])
                print("Failed to decode document data")
                errorPointer?.pointee = error
                return nil
            }

            let wasLiked = quoteData.likedBy.contains(userId)
            
            if wasLiked {
                // いいね解除
                transaction.updateData(["likes": FieldValue.increment(Int64(-1)), "likedBy": FieldValue.arrayRemove([userId])], forDocument: quoteRef)
            } else {
                // いいね追加
                transaction.updateData(["likes": FieldValue.increment(Int64(1)), "likedBy": FieldValue.arrayUnion([userId])], forDocument: quoteRef)
            }

            return ["wasLiked": wasLiked, "quoteData": quoteData] // 通知作成用にデータを返す
        }) { [weak self] (object, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "いいねの更新に失敗しました: \(error.localizedDescription)"
                    print("Transaction failed: \(error)")
                } else {
                    
                    // 通知作成（いいね追加時のみ）
                    if let result = object as? [String: Any],
                       let wasLiked = result["wasLiked"] as? Bool,
                       let quoteData = result["quoteData"] as? Quote,
                       !wasLiked { // いいね追加時のみ通知
                        
                        // 現在のユーザー情報を取得して通知作成
                        self?.createLikeNotificationIfNeeded(
                            fromUserId: userId,
                            toUserId: quoteData.authorUid,
                            quoteId: quote.id ?? "",
                            quoteText: quoteData.text
                        )
                    }
                    
                    // ViewModelのquotes配列も更新して全画面で同期
                    self?.refreshQuoteInViewModel(quoteId: quote.id ?? "")
                    // プロフィール画面の統計情報も更新
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshProfileContent"), object: nil)
                    
                    // 投稿者のバッジチェック（いいね追加時のみ）
                    if let result = object as? [String: Any],
                       let wasLiked = result["wasLiked"] as? Bool,
                       let quoteData = result["quoteData"] as? Quote,
                       !wasLiked { // いいね追加時のみ
                        // 投稿者のバッジチェック（いいね数に基づく）
                        self?.checkAndAwardBadges(userId: quoteData.authorUid)
                        
                        // 現在のユーザーのバッジチェック（投稿数に基づく）
                        self?.checkAndAwardBadges(userId: userId)
                    }
                }
            }
        }
    }

    // ブックマークを更新する
    func bookmarkQuote(quote: Quote) {
        errorMessage = nil
        guard let documentId = quote.id else { return }
        
        // 匿名認証が有効化されたので、認証必須に変更
        guard let userId = Auth.auth().currentUser?.uid else {
            print("ERROR: User not authenticated for bookmark - this should not happen")
            self.errorMessage = "認証処理中です。しばらくお待ちください。"
            return
        }
#if DEBUG
        print("Using authenticated user ID for bookmark: \(userId)")
        #endif

        let quoteRef = db.collection("quotes").document(documentId)

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let quoteDocument: DocumentSnapshot
            do {
                try quoteDocument = transaction.getDocument(quoteRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard var quoteData = try? quoteDocument.data(as: Quote.self) else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "ドキュメントのデコードに失敗しました"
                ])
                errorPointer?.pointee = error
                return nil
            }

            if quoteData.bookmarkedByArray.contains(userId) {
                // ブックマーク解除
                transaction.updateData(["bookmarkedBy": FieldValue.arrayRemove([userId])], forDocument: quoteRef)
            } else {
                // ブックマーク追加
                transaction.updateData(["bookmarkedBy": FieldValue.arrayUnion([userId])], forDocument: quoteRef)
            }

            return nil
        }) { [weak self] (object, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "ブックマークの更新に失敗しました: \(error.localizedDescription)"
                    print("Transaction failed: \(error)")
                } else {
                    // ViewModelのquotes配列も更新して全画面で同期
                    // Firestoreの最新データを取得して反映
                    self?.refreshQuoteInViewModel(quoteId: quote.id ?? "")
                    // プロフィール画面の統計情報も更新
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshProfileContent"), object: nil)
                }
            }
        }
    }

    // リプライを読み込む（コスト最適化版）
    func fetchReplies(for quote: Quote) {
        guard let quoteId = quote.id else { return }
        
        // 🚨 PRODUCTION FIX: リアルタイムリスナーをワンタイム取得に変更
        
        db.collection("quotes").document(quoteId).collection("replies")
            .order(by: "createdAt", descending: false)
            .limit(to: 20) // 最大20件のリプライ
            .getDocuments { [weak self] (querySnapshot, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "リプライの読み込みに失敗しました: \(error.localizedDescription)"
                        print(error.localizedDescription)
                        return
                    }

                    guard let documents = querySnapshot?.documents else {
                        print("No replies")
                        self?.replies = []
                        return
                    }

                    self?.replies = documents.compactMap { queryDocumentSnapshot -> Reply? in
                        try? queryDocumentSnapshot.data(as: Reply.self)
                    }
                    
                    print("📊 Loaded \(documents.count) replies (cost-optimized)")
                }
            }
    }

    // リプライを追加する
    func addReply(to quote: Quote, reply: Reply, userProfile: UserProfile? = nil) {
        guard let quoteId = quote.id else { return }
        var newReply = reply
        
        // 匿名認証が有効化されたので、認証必須に変更
        guard let currentUser = Auth.auth().currentUser else {
            print("ERROR: User not authenticated for reply - this should not happen")
            self.errorMessage = "認証処理中です。リプライできません。"
            return
        }
        
        // リプライ内容の適切性チェック
        let moderationResult = ContentModerationService.shared.isContentAppropriate(newReply.text)
        if !moderationResult.isAppropriate {
            errorMessage = moderationResult.reason ?? "リプライ内容が不適切です"
            return
        }
        
        newReply.authorUid = currentUser.uid
        
        // ログイン済みユーザーの場合、プロフィール情報を設定
        let isLoggedIn = Auth.auth().currentUser?.isAnonymous == false
        if isLoggedIn, let userProfile = userProfile {
            // プロフィール情報を設定
            newReply.authorDisplayName = userProfile.displayName ?? ""
            newReply.authorProfileImage = userProfile.profileImageURL ?? ""
            // authorが空の場合はプロフィール名を使用
            if newReply.author.isEmpty {
                newReply.author = userProfile.displayName ?? "名無しさん"
            }
        } else if newReply.author.isEmpty {
            // 未ログインユーザーでauthorが空の場合
            newReply.author = "匿名"
        }
        
#if DEBUG
        print("Adding reply with authenticated user ID: \(currentUser.uid)")
        #endif
        
        do {
            _ = try db.collection("quotes").document(quoteId).collection("replies").addDocument(from: newReply) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "リプライの追加に失敗しました: \(error.localizedDescription)"
                        print(error)
                    } else {
                        // リプライ追加成功後、リプライ一覧を再読み込み
                        self?.fetchReplies(for: quote)
                        
                        // ViewModelのQuoteも更新してリプライ数を反映
                        if let index = self?.quotes.firstIndex(where: { $0.id == quote.id }) {
                            self?.quotes[index].replyCount = (self?.quotes[index].replyCount ?? 0) + 1
                        }
                        
                        // リプライ通知を作成
                        self?.createReplyNotificationIfNeeded(
                            fromUserId: currentUser.uid,
                            toUserId: quote.authorUid,
                            quoteId: quote.id ?? "",
                            quoteText: quote.text,
                            replyText: newReply.text,
                            userProfile: userProfile
                        )
                        
                        // 他画面への同期通知
                        NotificationCenter.default.post(name: NSNotification.Name("RefreshProfileContent"), object: nil)
                    }
                }
            }
        } catch {
            self.errorMessage = "リプライの追加に失敗しました: \(error.localizedDescription)"
            print(error)
        }
    }
    
    // 特定のQuoteをFirestoreから再取得してViewModelに反映
    private func refreshQuoteInViewModel(quoteId: String) {
        guard !quoteId.isEmpty else { return }
        
        db.collection("quotes").document(quoteId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error refreshing quote: \(error)")
                    return
                }
                
                guard let document = document, document.exists,
                      let updatedQuote = try? document.data(as: Quote.self) else {
                    print("Could not decode updated quote")
                    return
                }
                
                // ViewModelのquotes配列を更新
                if let index = self?.quotes.firstIndex(where: { $0.id == quoteId }) {
                    self?.quotes[index] = updatedQuote
                }
            }
        }
    }
    
    // いいね通知作成のヘルパー関数
    private func createLikeNotificationIfNeeded(
        fromUserId: String,
        toUserId: String,
        quoteId: String,
        quoteText: String
    ) {
        print("🔍 通知作成チェック:")
        print("   - fromUserId: \(fromUserId)")
        print("   - toUserId: \(toUserId)")
        print("   - 同じユーザー?: \(fromUserId == toUserId)")
        print("   - 匿名ユーザー?: \(Auth.auth().currentUser?.isAnonymous ?? true)")
        
        // 匿名ユーザーまたは自分自身への通知は作成しない
        guard !(Auth.auth().currentUser?.isAnonymous ?? true),
              fromUserId != toUserId,
              !toUserId.isEmpty else {
            print("❌ 通知作成をスキップ: 自分自身または匿名ユーザー")
            return
        }
        
        print("✅ 通知作成を続行")
        
        // 現在のユーザーのプロフィール情報を取得
        db.collection("userProfiles").document(fromUserId).getDocument { document, error in
            var fromUserName = "匿名ユーザー"
            var fromUserProfileImage: String? = nil
            
            if let document = document, document.exists,
               let profile = try? document.data(as: UserProfile.self) {
                fromUserName = profile.displayName
                fromUserProfileImage = profile.profileImageURL
            }
            
            // 通知を作成
            print("🔔 いいね通知を作成中: \(fromUserName) -> \(toUserId)")
            NotificationViewModel.createLikeNotification(
                fromUserId: fromUserId,
                fromUserName: fromUserName,
                fromUserProfileImage: fromUserProfileImage,
                toUserId: toUserId,
                quoteId: quoteId,
                quoteText: quoteText
            )
        }
    }
    
    // リプライ通知作成のヘルパー関数
    private func createReplyNotificationIfNeeded(
        fromUserId: String,
        toUserId: String,
        quoteId: String,
        quoteText: String,
        replyText: String,
        userProfile: UserProfile?
    ) {
        // 匿名ユーザーまたは自分自身への通知は作成しない
        guard !(Auth.auth().currentUser?.isAnonymous ?? true),
              fromUserId != toUserId,
              !toUserId.isEmpty else {
            return
        }
        
        var fromUserName = "匿名ユーザー"
        var fromUserProfileImage: String? = nil
        
        // プロフィール情報が渡されている場合はそれを使用
        if let userProfile = userProfile {
            fromUserName = userProfile.displayName ?? "匿名ユーザー"
            fromUserProfileImage = userProfile.profileImageURL
        }
        
        // 通知を作成
        print("🔔 リプライ通知を作成中: \(fromUserName) -> \(toUserId)")
        NotificationViewModel.createReplyNotification(
            fromUserId: fromUserId,
            fromUserName: fromUserName,
            fromUserProfileImage: fromUserProfileImage,
            toUserId: toUserId,
            quoteId: quoteId,
            quoteText: quoteText,
            replyText: replyText
        )
        
    }
    
    func clearLocalStates() {
        // ローカルのいいね・ブックマーク状態をクリア
        for i in 0..<quotes.count {
            quotes[i].likedBy = []
            quotes[i].bookmarkedBy = []
        }
    }
    
    // バッジ獲得チェック
    func checkAndAwardBadges(userId: String) {
        guard Auth.auth().currentUser?.isAnonymous == false else { return }
        
        // 投稿数とトータルいいね数を取得
        db.collection("quotes")
            .whereField("authorUid", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let postCount = documents.count
                let totalLikes = documents.reduce(0) { sum, doc in
                    sum + (doc.data()["likes"] as? Int ?? 0)
                }
                
                // BadgeManagerを使ってバッジをチェック
                let badgeManager = BadgeManager()
                badgeManager.checkPostBadges(userId: userId, postCount: postCount)
                badgeManager.checkLikeBadges(userId: userId, totalLikes: totalLikes)
                
                print("📊 バッジチェック完了 - 投稿数: \(postCount), 総いいね数: \(totalLikes)")
            }
    }
    
}
