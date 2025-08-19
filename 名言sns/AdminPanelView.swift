import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AdminPanelView: View {
    @Environment(\.dismiss) var dismiss
    @State private var targetUsername = ""  // @ユーザー名
    @State private var selectedBadge = "developer"
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isAdmin = false
    @State private var foundUserId: String? = nil
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    var body: some View {
        NavigationView {
            Form {
                if isAdmin {
                    Section("バッジ付与") {
                        HStack {
                            Text("@")
                                .foregroundColor(.secondary)
                            TextField("ユーザー名", text: $targetUsername)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .onChange(of: targetUsername) { newValue in
                                    // @マークが入力されたら削除
                                    targetUsername = newValue.replacingOccurrences(of: "@", with: "")
                                }
                        }
                        
                        Picker("バッジ種類", selection: $selectedBadge) {
                            // 基本バッジ
                            Label("開発者", systemImage: "hammer.fill")
                                .tag("developer")
                            Label("認証済み", systemImage: "checkmark.seal.fill")
                                .tag("verified")
                            Label("運営者", systemImage: "checkmark.seal.fill")
                                .tag("admin")
                            
                            Divider()
                            
                            // TikTokバッジ
                            Label("TikTok 1K", systemImage: "t.circle.fill")
                                .tag("tiktok_1k")
                            Label("TikTok 5K", systemImage: "t.circle.fill")
                                .tag("tiktok_5k")
                            Label("TikTok 10K", systemImage: "t.circle.fill")
                                .tag("tiktok_10k")
                            
                            Divider()
                            
                            // Xバッジ
                            Label("X 1K", systemImage: "x.circle.fill")
                                .tag("x_1k")
                            Label("X 5K", systemImage: "x.circle.fill")
                                .tag("x_5k")
                            Label("X 10K", systemImage: "x.circle.fill")
                                .tag("x_10k")
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Button(action: grantBadge) {
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("バッジを付与")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                        .disabled(targetUsername.isEmpty || isLoading)
                    }
                    
                    Section("バッジ削除") {
                        Button(action: revokeBadge) {
                            Text("選択したバッジを削除")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(targetUsername.isEmpty || isLoading)
                    }
                    
                    Section("デバッグ") {
                        Button("ユーザー一覧を表示") {
                            debugShowAllUsers()
                        }
                        .foregroundColor(.blue)
                    }
                    
                    
                    Section("情報") {
                        Text("開発者バッジ: アプリ開発者の証")
                        Text("認証バッジ: 公式認証アカウント（青チェックマーク）")
                        Text("運営者バッジ: アプリ運営者（赤チェックマーク）")
                        
                        Divider()
                        
                        Text("TikTokバッジ: フォロワー数達成の証")
                        Text("Xバッジ: フォロワー数達成の証")
                        Text("SNSで拡散してくれた方に付与")
                        
                        Divider()
                        
                        Text("@の後の8文字を入力してください")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                } else {
                    Text("管理者権限がありません")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("管理者パネル")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert("結果", isPresented: $showingAlert) {
                Button("了解") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                checkAdminStatus()
            }
        }
    }
    
    private func checkAdminStatus() {
        guard let uid = currentUserId else { 
            return 
        }
        
        let db = Firestore.firestore()
        db.collection("userProfiles").document(uid).getDocument { document, error in
            if let error = error {
                return
            }
            
            if let data = document?.data() {
                let badges = data["allBadges"] as? [String] ?? []
                
                if badges.contains("admin") {
                    DispatchQueue.main.async {
                        self.isAdmin = true
                    }
                }
            }
        }
    }
    
    private func grantBadge() {
        guard !targetUsername.isEmpty else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        // @ユーザー名から実際のユーザーIDを検索
        findUserIdByUsername(targetUsername) { userId in
            guard let userId = userId else {
                self.isLoading = false
                self.alertMessage = "ユーザー @\(self.targetUsername) が見つかりません"
                self.showingAlert = true
                return
            }
            
            db.collection("userProfiles").document(userId).updateData([
                "allBadges": FieldValue.arrayUnion([self.selectedBadge]),
                "updatedAt": FieldValue.serverTimestamp()
            ]) { error in
                self.isLoading = false
                if let error = error {
                    // ドキュメントが存在しない場合は作成
                    db.collection("userProfiles").document(userId).setData([
                        "uid": userId,
                        "allBadges": [self.selectedBadge],
                        "selectedBadges": [],
                        "displayName": "",
                        "bio": "",
                        "profileImageURL": "",
                        "postCount": 0,
                        "likesReceived": 0,
                        "createdAt": FieldValue.serverTimestamp(),
                        "updatedAt": FieldValue.serverTimestamp()
                    ], merge: true) { createError in
                        if let createError = createError {
                            self.alertMessage = "エラー: \(createError.localizedDescription)"
                        } else {
                            self.alertMessage = "@\(self.targetUsername) にバッジを付与しました！"
                            self.targetUsername = ""
                            
                            // バッジ更新通知を送信
                            NotificationCenter.default.post(name: NSNotification.Name("BadgeUpdated"), object: nil)
                        }
                        self.showingAlert = true
                    }
                } else {
                    self.alertMessage = "@\(self.targetUsername) にバッジを付与しました！"
                    self.targetUsername = ""
                    self.showingAlert = true
                    
                    // バッジ更新通知を送信
                    NotificationCenter.default.post(name: NSNotification.Name("BadgeUpdated"), object: nil)
                }
            }
        }
    }
    
    private func revokeBadge() {
        guard !targetUsername.isEmpty else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        findUserIdByUsername(targetUsername) { userId in
            guard let userId = userId else {
                self.isLoading = false
                self.alertMessage = "ユーザー @\(self.targetUsername) が見つかりません"
                self.showingAlert = true
                return
            }
            
            db.collection("userProfiles").document(userId).updateData([
                "allBadges": FieldValue.arrayRemove([self.selectedBadge]),
                "updatedAt": FieldValue.serverTimestamp()
            ]) { error in
                self.isLoading = false
                if let error = error {
                    self.alertMessage = "エラー: \(error.localizedDescription)"
                } else {
                    self.alertMessage = "@\(self.targetUsername) からバッジを削除しました"
                    self.targetUsername = ""
                }
                self.showingAlert = true
            }
        }
    }
    
    private func findUserIdByUsername(_ username: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        // 複数の方法でユーザーを検索
        #if DEBUG
        print("🔍 Searching for user: '\(username)'")
        #endif
        
        // 方法1: そのままuserProfilesで検索
        db.collection("userProfiles").document(username).getDocument { document, error in
            if document?.exists == true {
                #if DEBUG
                print("✅ Found user by direct ID: \(username)")
                #endif
                completion(username)
                return
            }
            
            // 方法2: Firebase Authenticationで検索してからuserProfilesを確認
            self.searchByDisplayName(username) { foundId in
                if let foundId = foundId {
                    completion(foundId)
                    return
                }
                
                // 方法3: 全てのuserProfilesを検索してuidフィールドをチェック
                self.searchByUidField(username, completion: completion)
            }
        }
    }
    
    private func searchByDisplayName(_ username: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        #if DEBUG
        print("🔍 Searching by displayName: '\(username)'")
        #endif
        
        // displayNameで検索
        db.collection("userProfiles")
            .whereField("displayName", isEqualTo: username)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let document = snapshot?.documents.first {
                    #if DEBUG
                    print("✅ Found user by displayName: \(document.documentID)")
                    #endif
                    completion(document.documentID)
                } else {
                    #if DEBUG
                    print("❌ No user found by displayName")
                    #endif
                    completion(nil)
                }
            }
    }
    
    private func searchByUidField(_ username: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        #if DEBUG
        print("🔍 Searching by uid field: '\(username)'")
        #endif
        
        // uidフィールドで検索（uidの最初の8文字が@の後に表示される）
        db.collection("userProfiles")
            .whereField("uid", isGreaterThanOrEqualTo: username)
            .whereField("uid", isLessThan: username + "z")
            .limit(to: 20)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    #if DEBUG
                    print("📋 Found \(documents.count) potential matches")
                    #endif
                    
                    for document in documents {
                        if let uid = document.data()["uid"] as? String {
                            #if DEBUG
                            print("   - Document: \(document.documentID), uid: \(uid)")
                            #endif
                            
                            // uidの最初の8文字が一致するかチェック
                            if String(uid.prefix(8)) == username {
                                #if DEBUG
                                print("✅ Found exact match: \(document.documentID)")
                                #endif
                                completion(document.documentID)
                                return
                            }
                        }
                    }
                    
                    #if DEBUG
                    print("❌ No exact match found")
                    #endif
                    completion(nil)
                } else {
                    #if DEBUG
                    print("❌ Search failed: \(error?.localizedDescription ?? "Unknown error")")
                    #endif
                    completion(nil)
                }
            }
    }
    
    
    private func debugShowAllUsers() {
        let db = Firestore.firestore()
        
        db.collection("userProfiles").limit(to: 10).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                if let documents = snapshot?.documents {
                    var message = "📋 ユーザー一覧 (\(documents.count)件):\n\n"
                    
                    for document in documents {
                        let data = document.data()
                        let uid = data["uid"] as? String ?? "N/A"
                        let displayName = data["displayName"] as? String ?? "未設定"
                        let badges = data["allBadges"] as? [String] ?? []
                        
                        message += "👤 \(displayName)\n"
                        message += "@\(String(uid.prefix(8)))\n"
                        message += "バッジ: \(badges.joined(separator: ", "))\n\n"
                    }
                    
                    // 現在のユーザー情報も表示
                    if let currentUid = self.currentUserId {
                        message += "🔥 あなたのID: @\(String(currentUid.prefix(8)))"
                    }
                    
                    self.alertMessage = message
                    self.showingAlert = true
                } else {
                    self.alertMessage = "エラー: \(error?.localizedDescription ?? "Unknown")"
                    self.showingAlert = true
                }
            }
        }
    }
    
}

#Preview {
    AdminPanelView()
}