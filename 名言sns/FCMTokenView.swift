import SwiftUI
import Firebase
import FirebaseMessaging

struct FCMTokenView: View {
    @State private var fcmToken: String = "読み込み中..."
    @State private var copied = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("FCM登録トークン")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("このトークンをFirebase Consoleのテスト送信で使用してください")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // トークン表示エリア
                GroupBox {
                    ScrollView {
                        Text(fcmToken)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.horizontal)
                
                // コピーボタン
                Button(action: {
                    UIPasteboard.general.string = fcmToken
                    copied = true
                    
                    // 2秒後にリセット
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                }) {
                    HStack {
                        Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                        Text(copied ? "コピーしました！" : "トークンをコピー")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(copied ? Color.green : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(fcmToken == "読み込み中..." || fcmToken == "トークンの取得に失敗しました")
                
                // 更新ボタン
                Button(action: fetchToken) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("トークンを再取得")
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                // 使い方説明
                VStack(alignment: .leading, spacing: 10) {
                    Text("使い方：")
                        .font(.headline)
                    
                    Text("1. 上記のトークンをコピー")
                    Text("2. Firebase Consoleを開く")
                    Text("3. Cloud Messaging → 新しい通知")
                    Text("4. 「テストメッセージを送信」をクリック")
                    Text("5. FCM登録トークンにペースト")
                    Text("6. テストを送信")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .navigationTitle("プッシュ通知テスト")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchToken()
            }
        }
    }
    
    private func fetchToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error)")
                fcmToken = "トークンの取得に失敗しました"
            } else if let token = token {
                print("FCM Token: \(token)")
                fcmToken = token
            }
        }
    }
}