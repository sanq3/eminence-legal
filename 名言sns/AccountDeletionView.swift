import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AccountDeletionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var confirmationText = ""
    @State private var isDeleting = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    private let deleteConfirmText = "削除"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 警告アイコン
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding(.top, 40)
                
                // タイトル
                Text("アカウントを削除")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // 警告メッセージ
                VStack(alignment: .leading, spacing: 16) {
                    Text("⚠️ この操作は取り消せません")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Text("アカウントを削除すると、以下のデータがすべて削除されます：")
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("すべての投稿", systemImage: "quote.bubble")
                        Label("プロフィール情報", systemImage: "person.circle")
                        Label("いいね・ブックマーク", systemImage: "heart")
                        Label("バッジ・実績", systemImage: "star.circle")
                        Label("すべてのリプライ", systemImage: "bubble.left")
                    }
                    .padding(.leading)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 確認入力
                VStack(alignment: .leading, spacing: 8) {
                    Text("確認のため「\(deleteConfirmText)」と入力してください")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("削除と入力", text: $confirmationText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 削除ボタン
                Button(action: deleteAccount) {
                    HStack {
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("アカウントを完全に削除")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(confirmationText == deleteConfirmText ? Color.red : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(confirmationText != deleteConfirmText || isDeleting)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("了解") {
                if alertTitle == "削除完了" {
                    // アプリを再起動するような動作
                    exit(0)
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func deleteAccount() {
        isDeleting = true
        
        guard let user = Auth.auth().currentUser else {
            alertTitle = "エラー"
            alertMessage = "ユーザー情報が取得できません"
            showingAlert = true
            isDeleting = false
            return
        }
        
        let db = Firestore.firestore()
        let userId = user.uid
        
        // バッチ処理でユーザーデータを削除
        let batch = db.batch()
        
        // 1. ユーザードキュメントを削除
        batch.deleteDocument(db.collection("users").document(userId))
        
        // 2. ユーザーの投稿を削除
        db.collection("quotes")
            .whereField("authorUid", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    for doc in documents {
                        batch.deleteDocument(doc.reference)
                    }
                }
                
                // バッチ実行
                batch.commit { error in
                    if let error = error {
                        alertTitle = "エラー"
                        alertMessage = "データ削除中にエラーが発生しました: \(error.localizedDescription)"
                        showingAlert = true
                        isDeleting = false
                        return
                    }
                    
                    // Firebase Authenticationからユーザーを削除
                    user.delete { error in
                        isDeleting = false
                        
                        if let error = error {
                            // 再認証が必要な場合
                            if (error as NSError).code == 17014 {
                                alertTitle = "再認証が必要"
                                alertMessage = "セキュリティのため、再度ログインしてから削除してください"
                            } else {
                                alertTitle = "エラー"
                                alertMessage = error.localizedDescription
                            }
                            showingAlert = true
                        } else {
                            alertTitle = "削除完了"
                            alertMessage = "アカウントが正常に削除されました"
                            showingAlert = true
                        }
                    }
                }
            }
    }
}