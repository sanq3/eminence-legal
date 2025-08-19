import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showingAuth = false
    @State private var showingProfileEdit = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoggingOut = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var notificationsEnabled = false
    @State private var versionTapCount = 0
    @State private var showingAdminPanel = false
    @State private var showingAccountDeletion = false
    
    private var isLoggedIn: Bool {
        Auth.auth().currentUser?.isAnonymous == false
    }
    
    var body: some View {
        NavigationView {
            List {
                // アカウント設定セクション
                if isLoggedIn {
                    Section("アカウント") {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(profileViewModel.userProfile?.displayName ?? "ユーザー名未設定")
                                    .font(.headline)
                                if let uid = Auth.auth().currentUser?.uid {
                                    HStack(spacing: 8) {
                                        Text("@\(String(uid.prefix(8)))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Button(action: {
                                            let userID = "@\(String(uid.prefix(8)))"
                                            UIPasteboard.general.string = userID
                                            // 簡単なフィードバック
                                            alertTitle = "コピー完了"
                                            alertMessage = "\(userID) をクリップボードにコピーしました"
                                            showingAlert = true
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                            Spacer()
                            Button(action: {
                                showingProfileEdit = true
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Section("アカウント") {
                        Button(action: {
                            showingAuth = true
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("ログイン / 新規登録")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                
                // アプリ設定セクション
                Section("アプリ設定") {
                    HStack {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .font(.title2)
                            .foregroundColor(isDarkMode ? .indigo : .orange)
                        Text("ダークモード")
                        Spacer()
                        Toggle("", isOn: $isDarkMode)
                            .onChange(of: isDarkMode) { newValue in
                                // ダークモード切り替えを即座に反映
                                DispatchQueue.main.async {
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                        windowScene.windows.first?.overrideUserInterfaceStyle = newValue ? .dark : .light
                                    }
                                }
                            }
                    }
                    
                    HStack {
                        Image(systemName: "bell.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("プッシュ通知")
                        Spacer()
                        Toggle("", isOn: $notificationsEnabled)
                            .disabled(!isLoggedIn)
                    }
                    .opacity(isLoggedIn ? 1.0 : 0.5)
                    
                    if !isLoggedIn {
                        Text("ログインすると通知機能が利用できます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                
                // アプリ情報セクション
                Section("アプリについて") {
                    Button(action: {
                        versionTapCount += 1
                        if versionTapCount >= 10 {
                            // 管理者パネルを表示
                            showingAdminPanel = true
                            versionTapCount = 0
                        }
                        // 3秒後にカウントをリセット
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            versionTapCount = 0
                        }
                    }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("バージョン")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        // 利用規約を開く
                        if let url = URL(string: "https://sanq3.github.io/eminence-legal/legal-docs/terms.html") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("利用規約")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        // プライバシーポリシーを開く
                        if let url = URL(string: "https://sanq3.github.io/eminence-legal/legal-docs/privacy.html") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .font(.title2)
                                .foregroundColor(.purple)
                            Text("プライバシーポリシー")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        // お問い合わせを開く
                        if let url = URL(string: "https://sanq3.github.io/eminence-legal/legal-docs/contact.html") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            Text("お問い合わせ")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // UI説明セクション
                Section("アプリの使い方") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("@")
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                            Text("ユーザーID - 一意の識別子（各ユーザー固有）")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            Text("プロフィール画像はギャラリーから選択可能")
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                
                // アカウント管理セクション
                if isLoggedIn {
                    Section("アカウント管理") {
                        Button(action: {
                            alertTitle = "ログアウト"
                            alertMessage = "本当にログアウトしますか？"
                            showingAlert = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                Text("ログアウト")
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Button(action: {
                            showingAccountDeletion = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                                Text("アカウントを削除")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAuth) {
            AuthenticationView()
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileEditView(profileViewModel: profileViewModel)
        }
        .sheet(isPresented: $showingAdminPanel) {
            AdminPanelView()
        }
        .sheet(isPresented: $showingAccountDeletion) {
            AccountDeletionView()
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            if alertTitle == "ログアウト" {
                Button("キャンセル", role: .cancel) { }
                Button("ログアウト", role: .destructive) {
                    isLoggingOut = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        do {
                            try Auth.auth().signOut()
                            
                            // ログアウト後に全アプリデータをリロード
                            NotificationCenter.default.post(name: NSNotification.Name("UserLoggedOut"), object: nil)
                            
                            // ログアウト後少し待ってから画面を閉じる
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isLoggingOut = false
                                dismiss()
                            }
                        } catch {
                            #if DEBUG
                            print("ログアウトエラー: \(error)")
                            #endif
                            isLoggingOut = false
                        }
                    }
                }
            } else {
                Button("了解") { }
            }
        } message: {
            Text(alertMessage)
        }
        .overlay {
            if isLoggingOut {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView("ログアウト中...")
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
            }
        }
        .onAppear {
            if isLoggedIn {
                profileViewModel.loadUserProfile()
            }
            // ダークモード設定を即座に適用
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.windows.first?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
                }
            }
        }
    }
    
    #if DEBUG
    // デバッグ: バッジ情報を確認
    private func debugCheckBadges() {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ ユーザーが認証されていません")
            return
        }
        
        let db = Firestore.firestore()
        let userId = currentUser.uid
        
        print("\n========== バッジ情報デバッグ ==========")
        print("📱 Current User ID: \(userId)")
        print("📱 Is Anonymous: \(currentUser.isAnonymous)")
        
        // userProfilesコレクションを確認
        db.collection("userProfiles").document(userId).getDocument { document, error in
            if let error = error {
                print("❌ Error: \(error)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                print("\n✅ userProfiles Document Found:")
                print("   - Document ID: \(document.documentID)")
                print("   - Display Name: \(data["displayName"] ?? "None")")
                print("   - All Badges: \(data["allBadges"] ?? [])")
                print("   - Selected Badges: \(data["selectedBadges"] ?? [])")
                
                if let allBadges = data["allBadges"] as? [String] {
                    print("\n🎖 Badge Analysis:")
                    print("   - Has 'admin': \(allBadges.contains("admin"))")
                    print("   - Has 'developer': \(allBadges.contains("developer"))")
                    print("   - Has 'verified': \(allBadges.contains("verified"))")
                    print("   - Total badges: \(allBadges.count)")
                    print("   - All badges: \(allBadges.joined(separator: ", "))")
                }
            } else {
                print("❌ No userProfiles document found for user: \(userId)")
            }
        }
        
        // usersコレクションも確認（古いデータの可能性）
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                print("\n📂 users Document Found (Legacy?):")
                print("   - Badges: \(data["badges"] ?? [])")
            }
        }
        
        print("=====================================\n")
    }
    
    // 開発者向け: 既存投稿のバッジ情報を更新
    private func updateExistingPostsBadges() {
        guard let currentUser = Auth.auth().currentUser,
              !currentUser.isAnonymous else {
            print("ログインユーザーのみがバッジ情報を更新できます")
            return
        }
        
        let db = Firestore.firestore()
        
        // 現在のユーザーのプロフィールを取得
        db.collection("userProfiles").document(currentUser.uid).getDocument { document, error in
            if let document = document, document.exists {
                do {
                    let userProfile = try document.data(as: UserProfile.self)
                    
                    // 自分の投稿すべてを取得
                    db.collection("quotes")
                        .whereField("authorUid", isEqualTo: currentUser.uid)
                        .getDocuments { snapshot, error in
                            if let documents = snapshot?.documents {
                                print("🔄 \(documents.count) 件の投稿のバッジ情報を更新中...")
                                
                                for document in documents {
                                    // 各投稿にバッジ情報を追加
                                    document.reference.updateData([
                                        "authorBadges": userProfile.allBadges ?? []
                                    ]) { error in
                                        if let error = error {
                                            print("❌ 投稿 \(document.documentID) の更新エラー: \(error)")
                                        } else {
                                            print("✅ 投稿 \(document.documentID) のバッジ情報を更新")
                                        }
                                    }
                                }
                            }
                        }
                } catch {
                    #if DEBUG
                    print("プロフィール読み込みエラー: \(error)")
                    #endif
                }
            }
        }
    }
    #endif
}

#Preview {
    SettingsView()
}