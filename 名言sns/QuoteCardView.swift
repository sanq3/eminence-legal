import SwiftUI
import FirebaseAuth

struct QuoteCardView: View {
    let quote: Quote
    @ObservedObject var viewModel: QuoteViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    let onTap: () -> Void
    let onEdit: () -> Void
    
    @State private var showingEmojis = false
    
    // ローカル状態（即座の更新用）
    @State private var localLikes: Int
    @State private var localIsLiked: Bool
    @State private var localIsBookmarked: Bool
    
    // 初期化
    init(quote: Quote, viewModel: QuoteViewModel, profileViewModel: ProfileViewModel, onTap: @escaping () -> Void, onEdit: @escaping () -> Void) {
        self.quote = quote
        self.viewModel = viewModel
        self.profileViewModel = profileViewModel
        self.onTap = onTap
        self.onEdit = onEdit
        self._localLikes = State(initialValue: quote.likes)
        self._localIsLiked = State(initialValue: quote.likedBy.contains(Auth.auth().currentUser?.uid ?? ""))
        self._localIsBookmarked = State(initialValue: quote.bookmarkedByArray.contains(Auth.auth().currentUser?.uid ?? ""))
    }
    
    // ViewModelから最新のquoteデータを取得
    private var currentQuote: Quote {
        viewModel.quotes.first { $0.id == quote.id } ?? quote
    }
    
    // 作者名とチェックマークの表示
    private var authorDisplayView: some View {
        HStack(spacing: 4) {
            Text(currentQuote.author.isEmpty ? "匿名" : String(currentQuote.author.prefix(10)))
            
            // チェックマーク表示（authorBadgesフィールドから判断）
            if let authorBadges = currentQuote.authorBadges, !authorBadges.isEmpty {
                if authorBadges.contains("admin") {
                    // 運営者バッジ = 赤の認証マーク
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                        .shadow(color: .red.opacity(0.3), radius: 1, x: 0, y: 0.5)
                } else if authorBadges.contains("verified") {
                    // 認証済みバッジ = 青の認証マーク
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 12))
                        .shadow(color: .blue.opacity(0.3), radius: 1, x: 0, y: 0.5)
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // タップ可能エリア（名言部分）
                quoteContentView
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTap()
                    }
                
                // アクションボタンエリア
                Divider()
                    .padding(.horizontal, 16)
                
                actionButtonsView
            }
            .onAppear {
                // 画面表示時に最新の状態を同期
                let userId = Auth.auth().currentUser?.uid ?? ""
                localLikes = currentQuote.likes
                localIsLiked = currentQuote.likedBy.contains(userId)
                localIsBookmarked = currentQuote.bookmarkedByArray.contains(userId)
                
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            )
            
            // 絵文字オーバーレイ
            if showingEmojis {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        ForEach(["😍", "😭", "😳", "☺️"], id: \.self) { emoji in
                            Button(action: {
                                sendEmojiReply(emoji)
                                withAnimation {
                                    showingEmojis = false
                                }
                            }) {
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .padding(10)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.8))
                    )
                    .padding(.bottom, 10)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contextMenu {
            let currentUserId = Auth.auth().currentUser?.uid ?? ""
            let isAuthor = currentQuote.authorUid == currentUserId
            let isAdmin = profileViewModel.userProfile?.allBadges.contains("admin") ?? false
            
            if isAuthor || isAdmin {
                if isAuthor {
                    Button {
                        onEdit()
                    } label: {
                        Label("編集", systemImage: "pencil")
                    }
                }
                Button(role: .destructive) {
                    viewModel.deleteData(quote: currentQuote)
                } label: {
                    Label("削除", systemImage: "trash")
                }
            }
        }
    }
    
    private var quoteContentView: some View {
        VStack(spacing: 0) {
            // 上のスペース
            Spacer()
            
            // Quote text - 中央配置
            Text(currentQuote.text)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
            
            // 下のスペース
            Spacer()
            
            // Author - 右下配置
            HStack {
                Spacer()
                authorDisplayView
                    .font(.system(.subheadline, design: .serif))
                    .foregroundColor(.secondary)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 12)
        }
        .frame(minHeight: 120)
        .padding(.top, 20)
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 0) {
            // Reply Button with long press and tap
            Button(action: {
                // タップで詳細画面に遷移
                onTap()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "text.bubble")
                    Text("\(currentQuote.replyCountValue)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                withAnimation(.spring()) {
                    showingEmojis.toggle()
                }
            }

            Divider()
                .frame(height: 20)

            // Like Button
            Button(action: {
                // 🚀 即座にローカル状態を更新（Twitter風）
                let wasLiked = localIsLiked
                localIsLiked.toggle()
                localLikes += wasLiked ? -1 : 1
                
                // バックグラウンドでFirestore更新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.likeQuote(quote: currentQuote)
                }
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
            .onChange(of: currentQuote.likes) { newLikes in
                // ViewModelから最新データが来たらローカル状態を同期
                localLikes = newLikes
            }
            .onChange(of: currentQuote.likedBy) { newLikedBy in
                // いいね状態を同期
                let userId = Auth.auth().currentUser?.uid ?? ""
                localIsLiked = newLikedBy.contains(userId)
            }

            Divider()
                .frame(height: 20)

            // Bookmark Button
            Button(action: {
                // 🚀 即座にローカル状態を更新（Twitter風）
                localIsBookmarked.toggle()
                
                // バックグラウンドでFirestore更新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.bookmarkQuote(quote: currentQuote)
                }
            }) {
                Image(systemName: localIsBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.subheadline)
                    .foregroundColor(localIsBookmarked ? .orange : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .onChange(of: currentQuote.bookmarkedBy) { newBookmarkedBy in
                // ブックマーク状態を同期
                let userId = Auth.auth().currentUser?.uid ?? ""
                localIsBookmarked = currentQuote.bookmarkedByArray.contains(userId)
            }
        }
    }
    
    // 現在の認証済みユーザーがいいねしているかチェック
    private func isLikedByCurrentUser(_ quote: Quote) -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else { return false }
        return quote.likedBy.contains(userId)
    }
    
    // 現在の認証済みユーザーがブックマークしているかチェック
    private func isBookmarkedByCurrentUser(_ quote: Quote) -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else { return false }
        return quote.bookmarkedByArray.contains(userId)
    }
    
    private func sendEmojiReply(_ emoji: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let tripleEmoji = "\(emoji)\(emoji)\(emoji)"
        
        // ログイン済みユーザーの場合は、プロフィール情報を使用
        if Auth.auth().currentUser?.isAnonymous == false {
            let authorName = profileViewModel.userProfile?.displayName ?? "匿名"
            var reply = Reply(text: tripleEmoji, author: authorName, authorUid: userId)
            reply.authorDisplayName = profileViewModel.userProfile?.displayName ?? ""
            reply.authorProfileImage = profileViewModel.userProfile?.profileImageURL ?? ""
            viewModel.addReply(to: currentQuote, reply: reply, userProfile: profileViewModel.userProfile)
        } else {
            // 匿名ユーザーの場合
            let reply = Reply(text: tripleEmoji, author: "匿名", authorUid: userId)
            viewModel.addReply(to: currentQuote, reply: reply, userProfile: nil)
        }
    }
    
}