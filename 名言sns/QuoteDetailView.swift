import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit

struct QuoteDetailView: View {
    let quote: Quote
    @EnvironmentObject var viewModel: QuoteViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var replyText = ""
    @State private var authorProfile: UserProfile?
    @State private var showingStamps = false
    @State private var selectedUserProfile: String?
    @FocusState private var isReplyFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    // ローカル状態（即座の更新用）
    @State private var localLikes: Int
    @State private var localIsLiked: Bool
    @State private var localIsBookmarked: Bool
    
    // ブロック・報告機能
    @StateObject private var blockReportManager = BlockAndReportManager()
    @State private var showingActionSheet = false
    @State private var showingReportSheet = false
    @State private var showingBlockAlert = false
    @State private var showingDeleteAlert = false
    @State private var reportReason: ReportReason = .inappropriate
    @State private var isCurrentUserAdmin = false
    
    // Firebase無料枠節約：管理者チェックのキャッシュ
    private static var adminStatusCache: [String: Bool] = [:]
    
    // 利用規約同意
    @State private var showingTermsAgreement = false
    @AppStorage("hasAgreedToTerms") private var hasAgreedToTerms = false
    @AppStorage("agreedTermsVersion") private var agreedTermsVersion = ""
    let currentTermsVersion = "1.0.0"
    
    init(quote: Quote) {
        self.quote = quote
        // ローカル状態を初期化
        self._localLikes = State(initialValue: quote.likes)
        self._localIsLiked = State(initialValue: quote.likedBy.contains(Auth.auth().currentUser?.uid ?? ""))
        self._localIsBookmarked = State(initialValue: quote.bookmarkedByArray.contains(Auth.auth().currentUser?.uid ?? ""))
    }
    
    // ViewModelから最新のquoteデータを取得
    private var currentQuote: Quote {
        return viewModel.quotes.first(where: { $0.id == quote.id }) ?? quote
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // メインコンテンツエリア
            ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {
                    // 投稿者情報
                    if let profile = authorProfile, !quote.authorUidValue.isEmpty {
                        Button(action: {
                            selectedUserProfile = quote.authorUidValue
                        }) {
                            HStack(spacing: 12) {
                                // プロフィール画像
                                if let imageURL = profile.profileImageURL, !imageURL.isEmpty {
                                    if imageURL.hasPrefix("data:") {
                                        // Base64画像の場合
                                        if let data = Data(base64Encoded: String(imageURL.dropFirst(23))),
                                           let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 50, height: 50)
                                                .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(.secondary)
                                        }
                                    } else if let url = URL(string: imageURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    // ユーザー名 + チェックマーク
                                    HStack(spacing: 4) {
                                        Text(profile.displayName)
                                            .font(.headline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        // チェックマーク表示（運営者・認証バッジがある場合のみ）
                                        if profile.allBadges.contains("admin") {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 14))
                                        } else if profile.allBadges.contains("verified") {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 14))
                                        }
                                    }
                                    
                                    // バッジ表示（最大4つ、設定されたバッジのみ）
                                    HStack(spacing: 4) {
                                        ForEach(profile.selectedBadges.prefix(4), id: \.self) { badgeRawValue in
                                            if let badgeType = BadgeType(rawValue: badgeRawValue) {
                                                BadgeView(badge: badgeType, size: 12, style: .icon)
                                            }
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    
                    // 名言カード（カード全体の中央に名言を配置、サイズ動的調整）
                    ZStack {
                        // 背景カード
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .cornerRadius(16)
                        
                        // コンテンツ全体
                        VStack(spacing: 0) {
                            // 上部スペース
                            Spacer()
                            
                            // 名言テキスト（カード全体の中央）
                            Text(quote.text)
                                .font(.title2)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // 下部スペース
                            Spacer()
                            
                            // 作者名（右下）
                            HStack {
                                Spacer()
                                Text("\(quote.author)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 16)
                                    .padding(.trailing, 24)
                            }
                        }
                        .padding(.top, 24)
                    }
                    .frame(minHeight: 200, maxHeight: 400)
                    .padding(.horizontal, 20)
                    
                    // 投稿情報とアクション
                    VStack(spacing: 12) {
                        // 投稿時間（1分以上経過時のみ表示）
                        let timeInterval = Date().timeIntervalSince(quote.createdAt)
                        if timeInterval >= 60 {
                            HStack {
                                Spacer()
                                Text(formatTime(quote.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // アクションボタン（リプライ・いいね・ブックマーク順）
                        HStack(spacing: 0) {
                            Button(action: {
                                // リプライボタンのアクション - リプライ入力にフォーカス
                                isReplyFieldFocused = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "bubble.left")
                                    Text("\(viewModel.replies.count)")
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            
                            Divider().frame(height: 20)
                            
                            Button(action: {
                                localIsLiked.toggle()
                                localLikes += localIsLiked ? 1 : -1
                                viewModel.likeQuote(quote: currentQuote)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: localIsLiked ? "heart.fill" : "heart")
                                    Text("\(localLikes)")
                                }
                                .font(.subheadline)
                                .foregroundColor(localIsLiked ? .pink : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            
                            Divider().frame(height: 20)
                            
                            Button(action: {
                                localIsBookmarked.toggle()
                                viewModel.bookmarkQuote(quote: currentQuote)
                            }) {
                                Image(systemName: localIsBookmarked ? "bookmark.fill" : "bookmark")
                                    .font(.subheadline)
                                    .foregroundColor(localIsBookmarked ? .orange : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                    }
                    
                    // リプライ
                    VStack(alignment: .leading, spacing: 16) {
                        if !viewModel.replies.isEmpty {
                            HStack {
                                Text("返信 (\(viewModel.replies.count))")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            ForEach(viewModel.replies) { reply in
                                ReplyRowView(
                                    reply: reply, 
                                    quoteId: quote.id ?? "",
                                    selectedUserProfile: $selectedUserProfile
                                )
                                    .environmentObject(viewModel)
                                    .padding(.horizontal, 20)
                                    .id(reply.id)
                            }
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .onChange(of: viewModel.replies.count) { _ in
                // 新しいリプライが追加されたら一番下にスクロール
                if let lastReply = viewModel.replies.last {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(lastReply.id, anchor: .bottom)
                    }
                }
            }
            }
            
            // リプライ入力エリア
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    TextField("返信を書く...", text: $replyText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isReplyFieldFocused)
                        .lineLimit(1...4)
                    
                    Button(action: sendReply) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(replyText.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle("詳細")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingActionSheet = true
                }) {
                    Image(systemName: "ellipsis")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("オプション"),
                buttons: getActionSheetButtons()
            )
        }
        .sheet(isPresented: $showingTermsAgreement) {
            TermsAgreementView {
                // 同意後にリプライ送信
                performReply()
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportView(
                targetType: .quote,
                targetId: quote.id ?? "",
                onSubmit: { reason, additionalInfo in
                    blockReportManager.reportQuote(
                        quote.id ?? "",
                        reason: reason,
                        additionalInfo: additionalInfo
                    ) { success, message in
                        print(message)
                    }
                }
            )
        }
        .alert("ユーザーをブロック", isPresented: $showingBlockAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("ブロック", role: .destructive) {
                blockReportManager.blockUser(quote.authorUidValue) { success, message in
                    print(message)
                    if success {
                        // ブロック成功後、データを更新
                        DispatchQueue.main.async {
                            viewModel.fetchData()
                        }
                    }
                }
            }
        } message: {
            Text("このユーザーの投稿は表示されなくなります。")
        }
        .alert("投稿を削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                deleteQuote()
            }
        } message: {
            Text("この投稿を削除しますか？この操作は元に戻せません。")
        }
        .navigationDestination(item: Binding<String?>(
            get: { selectedUserProfile },
            set: { selectedUserProfile = $0 }
        )) { userId in
            OtherUserProfileView(userId: userId)
                .environmentObject(viewModel)
        }
        .onAppear {
            viewModel.fetchReplies(for: quote)
            loadAuthorProfile()
            checkCurrentUserAdminStatus()
            if Auth.auth().currentUser?.isAnonymous == false {
                profileViewModel.loadUserProfile()
            }
            syncLocalStateWithViewModel()
        }
        .onChange(of: currentQuote.likes) { newLikes in
            if !localIsLiked && currentQuote.likedBy.contains(Auth.auth().currentUser?.uid ?? "") {
                localIsLiked = true
            } else if localIsLiked && !currentQuote.likedBy.contains(Auth.auth().currentUser?.uid ?? "") {
                localIsLiked = false
            }
            localLikes = newLikes
        }
        .onChange(of: currentQuote.bookmarkedBy) { _ in
            let userId = Auth.auth().currentUser?.uid ?? ""
            localIsBookmarked = currentQuote.bookmarkedByArray.contains(userId)
        }
    }
    
    private func loadAuthorProfile() {
        guard !quote.authorUidValue.isEmpty else { return }
        
        let db = Firestore.firestore()
        db.collection("userProfiles").document(quote.authorUidValue).getDocument { document, error in
            if let document = document, document.exists,
               let profile = try? document.data(as: UserProfile.self) {
                DispatchQueue.main.async {
                    self.authorProfile = profile
                }
            }
        }
    }
    
    private func getCurrentUserDisplayName() -> String {
        if Auth.auth().currentUser?.isAnonymous == false,
           let profile = profileViewModel.userProfile {
            return profile.displayName
        }
        return "匿名"
    }
    
    private func sendReply() {
        guard !replyText.isEmpty else { return }
        
        // 利用規約に同意していない場合は同意画面を表示
        if !hasAgreedToTerms || agreedTermsVersion != currentTermsVersion {
            showingTermsAgreement = true
            return
        }
        
        // 同意済みの場合はリプライ送信
        performReply()
    }
    
    private func performReply() {
        let authorName = getCurrentUserDisplayName()
        let userId = Auth.auth().currentUser?.uid ?? ""
        var reply = Reply(text: replyText, author: authorName, authorUid: userId)
        
        if Auth.auth().currentUser?.isAnonymous == false {
            reply.authorDisplayName = profileViewModel.userProfile?.displayName ?? ""
            reply.authorProfileImage = profileViewModel.userProfile?.profileImageURL ?? ""
        }
        
        viewModel.addReply(to: quote, reply: reply, userProfile: profileViewModel.userProfile)
        
        DispatchQueue.main.async {
            replyText = ""
            isReplyFieldFocused = false
        }
    }
    
    private func syncLocalStateWithViewModel() {
        let userId = Auth.auth().currentUser?.uid ?? ""
        localLikes = currentQuote.likes
        localIsLiked = currentQuote.likedBy.contains(userId)
        localIsBookmarked = currentQuote.bookmarkedByArray.contains(userId)
    }
    
    private func getActionSheetButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        let userId = Auth.auth().currentUser?.uid ?? ""
        
        // 自分の投稿の場合：削除オプション
        if quote.authorUidValue == userId {
            buttons.append(.destructive(Text("投稿を削除")) {
                showingDeleteAlert = true
            })
        } else {
            // 他人の投稿の場合：ブロック・報告オプション
            buttons.append(.destructive(Text("このユーザーをブロック")) {
                showingBlockAlert = true
            })
            
            buttons.append(.destructive(Text("この投稿を報告")) {
                showingReportSheet = true
            })
        }
        
        // 管理者権限（adminバッジ）がある場合は、他人の投稿も削除可能
        if quote.authorUidValue != userId && isCurrentUserAdmin {
            buttons.append(.destructive(Text("管理者として削除")) {
                showingDeleteAlert = true
            })
        }
        
        buttons.append(.default(Text("投稿をシェア")) {
            shareQuote()
        })
        
        buttons.append(.cancel())
        return buttons
    }
    
    private func shareQuote() {
        let shareText = """
        「\(quote.text)」
        - \(quote.author)
        
        #エミネンス #名言
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 3600 { // 1時間未満
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分前"
        } else if timeInterval < 86400 { // 24時間未満
            let hours = Int(timeInterval / 3600)
            return "\(hours)時間前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            formatter.locale = Locale(identifier: "ja_JP")
            return formatter.string(from: date)
        }
    }
    
    private func checkCurrentUserAdminStatus() {
        let userId = Auth.auth().currentUser?.uid ?? ""
        guard !userId.isEmpty else { return }
        
        // キャッシュから管理者ステータスを確認（Firebase無料枠節約）
        if let cachedStatus = Self.adminStatusCache[userId] {
            isCurrentUserAdmin = cachedStatus
            return
        }
        
        let db = Firestore.firestore()
        db.collection("userProfiles").document(userId).getDocument { document, error in
            if let document = document, document.exists,
               let profile = try? document.data(as: UserProfile.self) {
                let adminStatus = profile.allBadges.contains("admin")
                DispatchQueue.main.async {
                    self.isCurrentUserAdmin = adminStatus
                    // キャッシュに保存（次回のFirebase読み取りを節約）
                    Self.adminStatusCache[userId] = adminStatus
                }
            }
        }
    }
    
    private func deleteQuote() {
        guard let quoteId = quote.id else { 
            print("投稿IDが見つかりません")
            return 
        }
        
        let db = Firestore.firestore()
        let quoteRef = db.collection("quotes").document(quoteId)
        
        // 投稿を削除（Firebase無料枠節約：バッチ削除は使わず単発削除）
        quoteRef.delete { [weak viewModel] error in
            if let error = error {
                print("投稿削除エラー: \(error.localizedDescription)")
            } else {
                print("投稿を削除しました: \(quoteId)")
                
                // 削除成功後、ホーム画面に戻る
                DispatchQueue.main.async {
                    // ViewModelからも削除（メモリ効率化）
                    viewModel?.quotes.removeAll { $0.id == quoteId }
                    
                    // SwiftUIの適切な方法でナビゲーション
                    dismiss()
                }
            }
        }
    }
}

// ReplyRowView - リプライ表示用のコンポーネント
struct ReplyRowView: View {
    let reply: Reply
    let quoteId: String
    @Binding var selectedUserProfile: String?
    @EnvironmentObject var viewModel: QuoteViewModel
    @StateObject private var blockReportManager = BlockAndReportManager()
    @State private var replyAuthorProfile: UserProfile?
    @State private var showingActionSheet = false
    @State private var showingReportSheet = false
    @State private var showingBlockAlert = false
    @State private var isHidden = false
    
    var body: some View {
        if isHidden {
            EmptyView()
        } else if blockReportManager.isUserBlocked(reply.authorUid) {
            EmptyView()
        } else {
        HStack(alignment: .top, spacing: 12) {
            // プロフィール画像（タップ可能）
            Button(action: {
                if !reply.authorUid.isEmpty {
                    selectedUserProfile = reply.authorUid
                }
            }) {
            if let profile = replyAuthorProfile, !reply.authorUid.isEmpty {
                if let imageURL = profile.profileImageURL, !imageURL.isEmpty {
                    if imageURL.hasPrefix("data:") {
                        // Base64画像の場合
                        if let data = Data(base64Encoded: String(imageURL.dropFirst(23))),
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    } else if let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(reply.authorUid.isEmpty)
            .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                // ユーザー名 + チェックマーク + 時刻（タップ可能）
                HStack(spacing: 4) {
                    Button(action: {
                        if !reply.authorUid.isEmpty {
                            selectedUserProfile = reply.authorUid
                        }
                    }) {
                        Text(reply.authorDisplayName.isEmpty ? reply.author : reply.authorDisplayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(reply.authorUid.isEmpty)
                    
                    // チェックマーク表示（リプライ用）
                    if let profile = replyAuthorProfile {
                        if profile.allBadges.contains("admin") {
                            // 運営者バッジ = 赤の認証マーク
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 10))
                                .shadow(color: .red.opacity(0.3), radius: 1, x: 0, y: 0.5)
                        } else if profile.allBadges.contains("verified") {
                            // 認証済みバッジ = 青の認証マーク
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 10))
                                .shadow(color: .blue.opacity(0.3), radius: 1, x: 0, y: 0.5)
                        }
                    }
                    
                    Spacer()
                    
                    // 時刻表示
                    Text(formatTime(reply.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                Text(reply.text)
                    .font(.body)
            }
            
            Spacer()
            
            // メニューボタン（3点リーダー）- 独立したVStackで包む
            VStack {
                Button(action: {
                    print("3点メニューがタップされました - showingActionSheet: \(showingActionSheet)")
                    showingActionSheet = true
                    print("ActionSheet状態変更後: \(showingActionSheet)")
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .frame(width: 32)
        }
        .onAppear {
            loadReplyAuthorProfile()
            blockReportManager.loadBlockedUsers()
        }
        .confirmationDialog("コメントのオプション", isPresented: $showingActionSheet, titleVisibility: .visible) {
            let userId = Auth.auth().currentUser?.uid ?? ""
            
            if reply.authorUid == userId {
                // 自分のコメントの場合：削除オプション
                Button("コメントを削除", role: .destructive) {
                    deleteReply()
                }
            } else {
                // 他人のコメントの場合：報告・ブロック・非表示オプション
                Button("このユーザーをブロック", role: .destructive) {
                    showingBlockAlert = true
                }
                
                Button("このコメントを報告", role: .destructive) {
                    showingReportSheet = true
                }
                
                Button("このコメントを非表示") {
                    withAnimation {
                        isHidden = true
                    }
                }
            }
            
            Button("キャンセル", role: .cancel) { }
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportView(
                targetType: .reply,
                targetId: reply.id ?? "",
                onSubmit: { reason, additionalInfo in
                    blockReportManager.reportReply(
                        quoteId,
                        replyId: reply.id ?? "",
                        reason: reason,
                        additionalInfo: additionalInfo
                    ) { success, message in
                        print(message)
                    }
                }
            )
        }
        .alert("ユーザーをブロック", isPresented: $showingBlockAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("ブロック", role: .destructive) {
                blockReportManager.blockUser(reply.authorUid) { success, message in
                    print(message)
                    if success {
                        DispatchQueue.main.async {
                            viewModel.fetchData()
                        }
                    }
                }
            }
        } message: {
            Text("このユーザーの投稿とコメントは表示されなくなります。")
        }
        }
    }
    
    private func loadReplyAuthorProfile() {
        guard !reply.authorUid.isEmpty else { return }
        
        let db = Firestore.firestore()
        db.collection("userProfiles").document(reply.authorUid).getDocument { document, error in
            if let document = document, document.exists,
               let profile = try? document.data(as: UserProfile.self) {
                DispatchQueue.main.async {
                    self.replyAuthorProfile = profile
                }
            }
        }
    }
    
    private func deleteReply() {
        guard let replyId = reply.id else { return }
        
        let db = Firestore.firestore()
        let replyRef = db.collection("quotes").document(quoteId).collection("replies").document(replyId)
        
        replyRef.delete { [weak viewModel] error in
            if let error = error {
                print("リプライ削除エラー: \(error.localizedDescription)")
            } else {
                print("リプライを削除しました")
                // ViewModelのリプライリストを更新
                DispatchQueue.main.async {
                    viewModel?.replies.removeAll { $0.id == replyId }
                }
            }
        }
    }
    
    // 時間を相対的な表示に変換する関数（ReplyRowView専用）
    private func formatTime(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "たった今"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分前"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)時間前"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/M/d"
            return formatter.string(from: date)
        }
    }
}