import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct MainTabView: View {
    @StateObject private var sharedQuoteViewModel = QuoteViewModel()
    @StateObject private var sharedProfileViewModel = ProfileViewModel()
    @StateObject private var sharedNotificationViewModel = NotificationViewModel()
    @State private var authStateListener: AuthStateDidChangeListenerHandle?
    @State private var selectedTab = 0
    @State private var homeTabTappedTwice = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ホーム画面
            ContentView(viewModel: sharedQuoteViewModel, profileViewModel: sharedProfileViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
                .tag(0)
            
            // 検索画面
            EnhancedSearchView()
                .environmentObject(sharedQuoteViewModel)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("検索")
                }
                .tag(1)
            
            // 通知画面
            NotificationViewShared(notificationViewModel: sharedNotificationViewModel)
                .environmentObject(sharedQuoteViewModel)
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("通知")
                }
                .tag(2)
            
            // プロフィール画面
            ProfileView(quoteViewModel: sharedQuoteViewModel, profileViewModel: sharedProfileViewModel)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("プロフィール")
                }
                .tag(3)
        }
        .accentColor(.primary)
        .onChange(of: selectedTab) { newValue in
            if newValue != 0 {
                // ホーム以外のタブが選択されたら通知を送る
                NotificationCenter.default.post(name: NSNotification.Name("TabChanged"), object: nil)
            }
        }
        .onAppear {
            // 認証状態の変更を監視
            authStateListener = Auth.auth().addStateDidChangeListener { auth, user in
                if let user = user, !user.isAnonymous {
                    // ログイン後にプロフィールをロード
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        sharedProfileViewModel.loadUserProfile()
                    }
                } else {
                    // ログアウト時にプロフィールをクリア
                    sharedProfileViewModel.clearUserProfile()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserLoggedOut"))) { _ in
            // ログアウト時の即座のデータリロード
            
            // 全データをクリア
            sharedNotificationViewModel.clearAllData()
            sharedProfileViewModel.clearUserProfile()
            sharedQuoteViewModel.clearLocalStates()
            
            // 全データをリフレッシュ
            sharedQuoteViewModel.fetchData()
            
            // 匿名認証を再実行
            if Auth.auth().currentUser == nil {
                sharedQuoteViewModel.signInAnonymouslyIfNeeded()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserLoggedIn"))) { _ in
            // ログイン時のデータリロード
            
            // 少し待ってからリロード（認証状態が完全に更新されるのを待つ）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // プロフィールをロード
                sharedProfileViewModel.loadUserProfile()
                
                // 全データをリフレッシュ（いいね状態を正しく反映）
                sharedQuoteViewModel.fetchData()
                
                // 通知をフェッチ
                sharedNotificationViewModel.fetchNotifications()
            }
        }
        .onChange(of: selectedTab) { newTab in
            // ホームタブ(0)が選択された場合の処理
            if newTab == 0 {
                handleHomeTabTap()
            }
        }
        .onDisappear {
            // リスナーを削除
            if let listener = authStateListener {
                Auth.auth().removeStateDidChangeListener(listener)
            }
        }
    }
    
    private func handleHomeTabTap() {
        // 既にホームタブが選択されている場合の連続タップ処理
        if selectedTab == 0 {
            if homeTabTappedTwice {
                // 2回目のタップ：更新
                NotificationCenter.default.post(name: NSNotification.Name("RefreshHome"), object: nil)
                homeTabTappedTwice = false
            } else {
                // 1回目のタップ：最上部へスクロール
                NotificationCenter.default.post(name: NSNotification.Name("ScrollToTop"), object: nil)
                homeTabTappedTwice = true
                
                // 2秒後にフラグをリセット
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    homeTabTappedTwice = false
                }
            }
        }
    }
}


// プロフィール画面
struct ProfileView: View {
    @ObservedObject var quoteViewModel: QuoteViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    @StateObject private var badgeManager = BadgeManager()
    @State private var showingSettings = false
    @State private var showingAuth = false
    @State private var showingProfileEdit = false
    @State private var showingBadgeSelector = false
    @State private var selectedProfileTab = 0 // 0: 投稿, 1: ブックマーク
    @State private var userQuotes: [Quote] = []
    @State private var bookmarkedQuotes: [Quote] = []
    @State private var navigationPath = NavigationPath()
    
    private var isLoggedIn: Bool {
        Auth.auth().currentUser?.isAnonymous == false
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Instagram風ヘッダー
                    VStack(spacing: 20) {
                        
                        // プロフィール画像 + 統計情報
                        HStack(alignment: .center, spacing: 16) {
                            // プロフィール画像とユーザー名（左寄せ）
                            VStack(spacing: 8) {
                                // ユーザー名（プロフィール画像の上）+ チェックマーク
                                if isLoggedIn {
                                    HStack(spacing: 4) {
                                        Text(profileViewModel.userProfile?.displayName ?? "ユーザー名未設定")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                        
                                        // チェックマーク表示（開発者バッジは表示しない）
                                        if let userBadges = profileViewModel.userProfile?.allBadges {
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
                                            // developer バッジはチェックマークなし
                                        }
                                    }
                                } else {
                                    Text("匿名ユーザー")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                }
                                
                                // プロフィール画像
                                if let imageURL = profileViewModel.userProfile?.profileImageURL,
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
                            if isLoggedIn {
                                VStack {
                                    Spacer()
                                    HStack(spacing: 24) {
                                        VStack(spacing: 4) {
                                            Text("\(userQuotes.count)")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                            Text("投稿")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        VStack(spacing: 4) {
                                            Text("\(userQuotes.reduce(0) { $0 + $1.likes })")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                            Text("いいね")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        VStack(spacing: 4) {
                                            Text("\(profileViewModel.userProfile?.allBadges.count ?? 0)")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                            Text("バッジ")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .frame(height: 80) // プロフィール画像と同じ高さに制限
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // バイオ
                        if isLoggedIn {
                            HStack {
                                Text(profileViewModel.userProfile?.bio.isEmpty == false 
                                     ? profileViewModel.userProfile!.bio 
                                     : "名言を愛する者です 🌟")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .lineLimit(3)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // プロフィール編集ボタン
                        if isLoggedIn {
                            Button(action: {
                                // プロフィールが未ロードの場合はロード
                                if profileViewModel.userProfile == nil {
                                    profileViewModel.loadUserProfile()
                                }
                                showingProfileEdit = true
                            }) {
                                Text("プロフィールを編集")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 20)
                        } else {
                            // 未ログインユーザー向けの表示
                            VStack(spacing: 16) {
                                Text("アカウントを作成すると")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .foregroundColor(.blue)
                                            .frame(width: 24)
                                        Text("プロフィール画像・名前の設定")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Image(systemName: "doc.text")
                                            .foregroundColor(.green)
                                            .frame(width: 24)
                                        Text("投稿履歴の保存・管理")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Image(systemName: "bookmark.fill")
                                            .foregroundColor(.orange)
                                            .frame(width: 24)
                                        Text("ブックマーク機能")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Image(systemName: "bell.badge")
                                            .foregroundColor(.red)
                                            .frame(width: 24)
                                        Text("いいね・リプライ通知")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Image(systemName: "rosette")
                                            .foregroundColor(.purple)
                                            .frame(width: 24)
                                        Text("バッジ機能")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .padding(.horizontal, 10)
                                
                                Button(action: {
                                    showingAuth = true
                                }) {
                                    Text("アカウントを作成")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .padding(.top, 8)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 10)
                    
                    // バッジ表示（選択したバッジ + 追加ボタン）
                    if isLoggedIn {
                        VStack(spacing: 12) {
                            let selectedBadges = profileViewModel.userProfile?.selectedBadges ?? []
                            
                            if selectedBadges.isEmpty {
                                // バッジが未選択の場合：追加ボタンのみ中央表示
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        showingBadgeSelector = true
                                    }) {
                                        VStack(spacing: 6) {
                                            ZStack {
                                                Circle()
                                                    .stroke(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                                    .frame(width: 80, height: 80)
                                                
                                                Image(systemName: "plus")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.secondary)
                                            }
                                            Text("追加")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                            } else {
                                // バッジが選択されている場合：等間隔で中央配置
                                HStack(spacing: 0) {
                                    // 選択したバッジを等間隔で表示
                                    ForEach(Array(selectedBadges.enumerated()), id: \.offset) { index, badgeRawValue in
                                        if let badgeType = BadgeType(rawValue: badgeRawValue) {
                                            Button(action: {
                                                showingBadgeSelector = true
                                            }) {
                                                VStack(spacing: 6) {
                                                    BadgeView(badge: badgeType, size: 32, style: .premium)
                                                    Text(badgeType.title)
                                                        .font(.system(size: 10))
                                                        .foregroundColor(.primary)
                                                        .lineLimit(1)
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                    }
                                    
                                    // 追加ボタン（最大4個まで、4個の場合は非表示）
                                    if selectedBadges.count < 4 {
                                        Button(action: {
                                            showingBadgeSelector = true
                                        }) {
                                            VStack(spacing: 6) {
                                                ZStack {
                                                    Circle()
                                                        .stroke(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                                        .frame(width: 80, height: 80)
                                                    
                                                    Image(systemName: "plus")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.secondary)
                                                }
                                                Text("追加")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 21)
                    }
                    
                    // タブとコンテンツ（ログイン済みユーザーのみ）
                    if isLoggedIn {
                        VStack(spacing: 0) {
                            // タブバー
                            HStack(spacing: 0) {
                                Button(action: {
                                    selectedProfileTab = 0
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "doc.text")
                                            .font(.title3)
                                        HStack(spacing: 4) {
                                            Text("投稿")
                                            Text("\(userQuotes.count)")
                                                .fontWeight(.medium)
                                        }
                                        .font(.caption)
                                    }
                                    .foregroundColor(selectedProfileTab == 0 ? .primary : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                }
                                
                                Button(action: {
                                    selectedProfileTab = 1
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "bookmark")
                                            .font(.title3)
                                        HStack(spacing: 4) {
                                            Text("ブックマーク")
                                            Text("\(bookmarkedQuotes.count)")
                                                .fontWeight(.medium)
                                        }
                                        .font(.caption)
                                    }
                                    .foregroundColor(selectedProfileTab == 1 ? .primary : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                }
                            }
                            .background(Color(UIColor.systemBackground))
                            
                            // タブのインジケーター
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(selectedProfileTab == 0 ? Color.primary : Color.clear)
                                    .frame(height: 2)
                                Rectangle()
                                    .fill(selectedProfileTab == 1 ? Color.primary : Color.clear)
                                    .frame(height: 2)
                            }
                            .animation(.easeInOut(duration: 0.2), value: selectedProfileTab)
                            
                            // 単純化：TabViewを使わずに条件分岐で表示
                            VStack {
                                if selectedProfileTab == 0 {
                                    ProfileContentView(
                                        selectedTab: 0,
                                        profileViewModel: profileViewModel,
                                        userQuotes: $userQuotes,
                                        bookmarkedQuotes: $bookmarkedQuotes,
                                        navigationPath: $navigationPath
                                    )
                                        .environmentObject(quoteViewModel)
                                } else {
                                    ProfileContentView(
                                        selectedTab: 1,
                                        profileViewModel: profileViewModel,
                                        userQuotes: $userQuotes,
                                        bookmarkedQuotes: $bookmarkedQuotes,
                                        navigationPath: $navigationPath
                                    )
                                        .environmentObject(quoteViewModel)
                                }
                            }
                            .frame(minHeight: 300)
                        }
                        .padding(.top, 20)
                    } else {
                        Spacer(minLength: 100)
                    }
                }
            }
            .refreshable {
                // 🚀 Twitter風のサイレント更新
                if isLoggedIn {
                    profileViewModel.loadUserProfile()
                    profileViewModel.updateActualPostCount()
                    // プロフィールコンテンツも更新
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshProfileContent"), object: nil)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationDestination(for: Quote.self) { quote in
                QuoteDetailView(quote: quote)
                    .environmentObject(quoteViewModel)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingAuth) {
            AuthenticationView()
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileEditView(profileViewModel: profileViewModel)
        }
        .sheet(isPresented: $showingBadgeSelector) {
            BadgeSelectorView(profileViewModel: profileViewModel)
        }
        .onAppear {
            if isLoggedIn {
                profileViewModel.loadUserProfile()
                profileViewModel.updateActualPostCount()
                
                // バッジ情報をロード
                if let userId = Auth.auth().currentUser?.uid {
                    badgeManager.fetchUserBadges(userId: userId)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BadgeUpdated"))) { _ in
            // バッジが更新された時にプロフィールを再読み込み
            if isLoggedIn {
                profileViewModel.loadUserProfile()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateProfilePostCount"))) { _ in
            if isLoggedIn {
                profileViewModel.updateActualPostCount()
                // プロフィール内容も更新
                NotificationCenter.default.post(name: NSNotification.Name("RefreshProfileContent"), object: nil)
            }
        }
    }
}

// プロフィールのコンテンツビュー（投稿一覧・ブックマーク一覧）
struct ProfileContentView: View {
    let selectedTab: Int
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var userQuotes: [Quote]
    @Binding var bookmarkedQuotes: [Quote]
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var mainQuoteViewModel: QuoteViewModel
    @State private var isLoading = false
    @State private var lastLoadedTab = -1
    
    var body: some View {
        VStack {
            if selectedTab == 0 {
                // 投稿一覧
                if isLoading {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if userQuotes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("まだ投稿がありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("名言を投稿してみましょう")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(userQuotes) { quote in
                            QuoteCardView(
                                quote: quote,
                                viewModel: mainQuoteViewModel,
                                profileViewModel: profileViewModel,
                                onTap: {
                                    navigationPath.append(quote)
                                },
                                onEdit: { }
                            )
                        }
                    }
                    .padding(.horizontal, 0) // ホームカードと同じ表示
                }
            } else {
                // ブックマーク一覧
                if isLoading {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if bookmarkedQuotes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("ブックマークがありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("気に入った名言をブックマークしてみましょう")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(bookmarkedQuotes) { quote in
                            QuoteCardView(
                                quote: quote,
                                viewModel: mainQuoteViewModel,
                                profileViewModel: profileViewModel,
                                onTap: {
                                    navigationPath.append(quote)
                                },
                                onEdit: { }
                            )
                        }
                    }
                    .padding(.horizontal, 0) // ホームカードと同じ表示
                }
            }
            
            Spacer(minLength: 50)
        }
        .onAppear {
            loadContent()
            lastLoadedTab = selectedTab
        }
        .onChange(of: selectedTab) { newTab in
            if lastLoadedTab != selectedTab {
                loadContent()
                lastLoadedTab = selectedTab
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateProfilePostCount"))) { _ in
            // 投稿の通知は常にloadContent()を呼び出す（タブが0の時に表示される）
            loadContent()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshBookmarks"))) { _ in
            // ブックマークの通知も常にloadContent()を呼び出す（タブが1の時に表示される）
            loadContent()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshProfileContent"))) { _ in
            // いいね・ブックマーク更新後はViewModelから最新データを取得（Firestoreアクセスなし）
            updateFromViewModel()
        }
    }
    
    private func loadContent() {
        let currentUser = Auth.auth().currentUser
        guard let uid = currentUser?.uid else { 
            return 
        }
        
        
        // 匿名ユーザーの場合はデータ取得をスキップ
        if currentUser?.isAnonymous == true {
            isLoading = false
            userQuotes = []
            bookmarkedQuotes = []
            return
        }
        
        
        // まず全ての投稿を確認するテストクエリ
        Firestore.firestore()
            .collection("quotes")
            .limit(to: 5)
            .getDocuments { snapshot, error in
            }
        isLoading = true
        
        if selectedTab == 0 {
            // 自分の投稿を取得（インデックス不要の単純なクエリ）
            Firestore.firestore()
                .collection("quotes")
                .whereField("authorUid", isEqualTo: uid)
                .limit(to: 10) // 🚨 PRODUCTION FIX: 50→10に削減
                .getDocuments { snapshot, error in
                    DispatchQueue.main.async {
                        isLoading = false
                        if let error = error {
                            print("Error loading user quotes: \(error.localizedDescription)")
                        } else if let documents = snapshot?.documents {
                            
                            let decodedQuotes = documents.compactMap { doc in
                                do {
                                    let quote = try doc.data(as: Quote.self)
                                    return quote
                                } catch {
                                    print("Error decoding quote: \(error)")
                                    return nil
                                }
                            }
                            
                            // 取得後にアプリ側でソート
                            let sortedQuotes = decodedQuotes.sorted { $0.createdAt > $1.createdAt }
                            userQuotes = sortedQuotes
                        }
                    }
                }
        } else {
            // ブックマークした投稿を取得（インデックス不要の単純なクエリ）
            Firestore.firestore()
                .collection("quotes")
                .whereField("bookmarkedBy", arrayContains: uid)
                .limit(to: 10) // 🚨 PRODUCTION FIX: 50→10に削減
                .getDocuments { snapshot, error in
                    DispatchQueue.main.async {
                        isLoading = false
                        if let error = error {
                            print("Error loading bookmarked quotes: \(error.localizedDescription)")
                        } else if let documents = snapshot?.documents {
                            
                            let decodedBookmarks = documents.compactMap { doc in
                                do {
                                    let quote = try doc.data(as: Quote.self)
                                    return quote
                                } catch {
                                    print("Error decoding bookmark: \(error)")
                                    return nil
                                }
                            }
                            
                            // 取得後にアプリ側でソート
                            let sortedBookmarks = decodedBookmarks.sorted { $0.createdAt > $1.createdAt }
                            bookmarkedQuotes = sortedBookmarks
                        }
                    }
                }
        }
    }
    
    // 🚀 ViewModelから最新データを取得（Firestoreアクセスなし、高速更新）
    private func updateFromViewModel() {
        let currentUser = Auth.auth().currentUser
        guard let uid = currentUser?.uid,
              currentUser?.isAnonymous == false else {
            return
        }
        
        
        if selectedTab == 0 {
            // ViewModelから自分の投稿を抽出
            userQuotes = mainQuoteViewModel.quotes.filter { $0.authorUid == uid }
                .sorted { $0.createdAt > $1.createdAt }
        } else {
            // ViewModelからブックマークした投稿を抽出
            bookmarkedQuotes = mainQuoteViewModel.quotes.filter { $0.bookmarkedByArray.contains(uid) }
                .sorted { $0.createdAt > $1.createdAt }
        }
    }
}

#Preview {
    MainTabView()
}