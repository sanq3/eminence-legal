import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct OtherUserProfileView: View {
    let userId: String
    @StateObject private var viewModel = OtherUserProfileViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @EnvironmentObject var mainQuoteViewModel: QuoteViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0 // 0: 投稿のみ（他ユーザーはブックマークは見れない）
    @State private var selectedQuote: Quote?
    @State private var showingBadgeDetail = false
    @State private var selectedBadge: BadgeType?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Instagram風ヘッダー
                    VStack(spacing: 20) {
                        
                        // プロフィール画像 + 統計情報
                        HStack(alignment: .center, spacing: 16) {
                            // プロフィール画像とユーザー名（左寄せ）
                            VStack(spacing: 8) {
                                // ユーザー名（プロフィール画像の上）+ チェックマーク
                                HStack(spacing: 4) {
                                    Text(viewModel.userProfile?.displayName ?? "ユーザー名未設定")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    
                                    // チェックマーク表示
                                    if let userBadges = viewModel.userProfile?.allBadges {
                                        if userBadges.contains("admin") {
                                            // 運営者バッジ = 赤の認証マーク
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 16))
                                                .shadow(color: .red.opacity(0.3), radius: 2, x: 0, y: 1)
                                        } else if userBadges.contains("verified") {
                                            // 認証済みバッジ = 青の認証マーク
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 16))
                                                .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 1)
                                        }
                                    }
                                }
                                
                                // プロフィール画像
                                if let imageURL = viewModel.userProfile?.profileImageURL,
                                   !imageURL.isEmpty {
                                    if imageURL.hasPrefix("data:") {
                                        // Base64画像の場合
                                        if let data = Data(base64Encoded: String(imageURL.dropFirst(23))),
                                           let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .font(.system(size: 80))
                                                .foregroundColor(.secondary)
                                        }
                                    } else if let url = URL(string: imageURL) {
                                        // URLの場合
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 80))
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // 統計情報 (Instagram風) - アイコンの下部に配置
                            VStack {
                                Spacer()
                                HStack(spacing: 24) {
                                    VStack(spacing: 4) {
                                        Text("\(viewModel.userQuotes.count)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text("投稿")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(spacing: 4) {
                                        Text("\(viewModel.totalLikes)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text("いいね")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(spacing: 4) {
                                        Text("\(viewModel.bookmarkedQuotesCount)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text("ブックマーク")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(spacing: 4) {
                                        Text("\(viewModel.userProfile?.allBadges.count ?? 0)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text("バッジ")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .frame(height: 80) // プロフィール画像と同じ高さに制限
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // バイオ
                        HStack {
                            Text(viewModel.userProfile?.bio.isEmpty == false 
                                 ? viewModel.userProfile!.bio 
                                 : "名言を愛する者です 🌟")
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineLimit(3)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)
                    
                    // バッジ表示（等間隔で中央配置）
                    if let selectedBadges = viewModel.userProfile?.selectedBadges, !selectedBadges.isEmpty {
                        VStack(spacing: 12) {
                            HStack(spacing: 0) {
                                // 選択されているバッジを等間隔で表示
                                ForEach(Array(selectedBadges.enumerated()), id: \.offset) { index, badgeRawValue in
                                    if let badgeType = BadgeType(rawValue: badgeRawValue) {
                                        VStack(spacing: 6) {
                                            BadgeView(badge: badgeType, size: 32, style: .premium)
                                                .onTapGesture {
                                                    selectedBadge = badgeType
                                                    showingBadgeDetail = true
                                                }
                                            Text(badgeType.title)
                                                .font(.system(size: 10))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 21)
                    }
                    
                    // タブとコンテンツ（他ユーザーは投稿のみ表示）
                    VStack(spacing: 0) {
                        // タブバー（投稿のみ）
                        HStack(spacing: 0) {
                            VStack(spacing: 8) {
                                Image(systemName: "doc.text")
                                    .font(.title3)
                                HStack(spacing: 4) {
                                    Text("投稿")
                                    Text("\(viewModel.userQuotes.count)")
                                        .fontWeight(.medium)
                                }
                                .font(.caption)
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .background(Color(UIColor.systemBackground))
                        
                        // タブのインジケーター
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.primary)
                                .frame(height: 2)
                        }
                        
                        // コンテンツ
                        OtherUserProfileContentView(
                            userQuotes: viewModel.userQuotes,
                            selectedQuote: $selectedQuote,
                            isLoading: viewModel.isLoading,
                            profileViewModel: profileViewModel
                        )
                        .environmentObject(mainQuoteViewModel)
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedQuote) { quote in
            QuoteDetailView(quote: quote)
                .environmentObject(mainQuoteViewModel)
        }
        .onAppear {
            viewModel.loadUserData(userId: userId)
            
            // 現在のユーザーのプロフィール情報をロード（adminバッジ確認のため）
            if Auth.auth().currentUser?.uid != nil && Auth.auth().currentUser?.isAnonymous == false {
                profileViewModel.loadUserProfile()
            }
        }
        .alert("バッジ詳細", isPresented: $showingBadgeDetail) {
            Button("了解") { }
        } message: {
            if let badge = selectedBadge {
                Text(badge.description)
            }
        }
    }
}

// 他ユーザーのコンテンツ表示用
struct OtherUserProfileContentView: View {
    let userQuotes: [Quote]
    @Binding var selectedQuote: Quote?
    let isLoading: Bool
    @ObservedObject var profileViewModel: ProfileViewModel
    
    @EnvironmentObject var mainQuoteViewModel: QuoteViewModel
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("読み込み中...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if userQuotes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("投稿がありません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(userQuotes) { quote in
                        Button(action: {
                            selectedQuote = quote
                        }) {
                            QuoteCardView(
                                quote: quote,
                                viewModel: mainQuoteViewModel,
                                profileViewModel: profileViewModel,
                                onTap: { 
                                    selectedQuote = quote
                                },
                                onEdit: { }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 12)
            }
        }
    }
}

@MainActor
class OtherUserProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var userQuotes: [Quote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var bookmarkedQuotesCount = 0 // ブックマーク数
    
    var totalLikes: Int {
        userQuotes.reduce(0) { $0 + $1.likes }
    }
    
    private let db = Firestore.firestore()
    private var bookmarkListener: ListenerRegistration?
    
    func loadUserData(userId: String) {
        isLoading = true
        errorMessage = nil
        userQuotes = []
        userProfile = nil
        bookmarkedQuotesCount = 0
        
        loadUserProfile(userId: userId)
        loadUserQuotes(userId: userId)
        loadUserBookmarkCount(userId: userId)
    }
    
    private func loadUserProfile(userId: String) {
        db.collection("userProfiles").document(userId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error loading profile: \(error)")
                    self?.errorMessage = "プロフィールの読み込みに失敗しました"
                    return
                }
                
                if let document = document, document.exists {
                    do {
                        self?.userProfile = try document.data(as: UserProfile.self)
                        let displayName = self?.userProfile?.displayName ?? "no name"
                    } catch {
                        print("Error decoding profile: \(error)")
                        self?.errorMessage = "プロフィールの読み込みに失敗しました"
                    }
                } else {
                    self?.errorMessage = "ユーザーが見つかりません"
                }
            }
        }
    }
    
    private func loadUserQuotes(userId: String) {
        
        // 投稿がない場合とエラーを区別するために別々にロードingを管理
        db.collection("quotes")
            .whereField("authorUid", isEqualTo: userId)
            .limit(to: 20)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print("Error loading user quotes: \(error)")
                        self?.errorMessage = "投稿の読み込みに失敗しました"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        return
                    }
                    
                    
                    let quotes = documents.compactMap { doc -> Quote? in
                        
                        do {
                            var quote = try doc.data(as: Quote.self)
                            quote.id = doc.documentID // IDを確実に設定
                            let quoteText = quote.text.prefix(30)
                            return quote
                        } catch {
                            print("Error decoding quote from doc \(doc.documentID): \(error)")
                            return nil
                        }
                    }
                    
                    // メモリ内でソート（インデックス不要）
                    let sortedQuotes = quotes.sorted { $0.createdAt > $1.createdAt }
                    self?.userQuotes = sortedQuotes
                }
            }
    }
    
    private func loadUserBookmarkCount(userId: String) {
        // ブックマーク数をリアルタイムで監視
        bookmarkListener?.remove()
        
        bookmarkListener = db.collection("quotes")
            .whereField("bookmarkedBy", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let documents = snapshot?.documents {
                        self?.bookmarkedQuotesCount = documents.count
                    }
                }
            }
    }
    
    deinit {
        bookmarkListener?.remove()
    }
}

#Preview {
    OtherUserProfileView(userId: "test123")
        .environmentObject(QuoteViewModel())
}