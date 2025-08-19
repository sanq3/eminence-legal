import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct NotificationSettingsView: View {
    @State private var selectedTime = Date()
    @State private var isNotificationEnabled = true
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("通知設定")) {
                    Toggle("毎日の名言通知", isOn: $isNotificationEnabled)
                        .onChange(of: isNotificationEnabled) { newValue in
                            updateNotificationSettings()
                        }
                    
                    if isNotificationEnabled {
                        DatePicker("通知時間",
                                   selection: $selectedTime,
                                   displayedComponents: .hourAndMinute)
                            .onChange(of: selectedTime) { newValue in
                                updateNotificationSettings()
                            }
                    }
                }
                
                Section(header: Text("説明")) {
                    Text("毎日指定した時間に、その日最も「いいね」が多かった名言をお知らせします。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("通知設定")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadUserSettings()
            }
            .alert("設定を更新しました", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadUserSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                self.isNotificationEnabled = data?["notificationsEnabled"] as? Bool ?? true
                
                if let timeString = data?["notificationTime"] as? String {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    if let time = formatter.date(from: timeString) {
                        self.selectedTime = time
                    }
                }
            }
        }
    }
    
    private func updateNotificationSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard !isSaving else { return }
        
        isSaving = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: selectedTime)
        
        let data: [String: Any] = [
            "notificationsEnabled": isNotificationEnabled,
            "notificationTime": timeString,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userId).setData(data, merge: true) { error in
            self.isSaving = false
            
            if let error = error {
                self.alertMessage = "エラー: \(error.localizedDescription)"
            } else {
                self.alertMessage = "通知時間を\(timeString)に設定しました"
                
                // ローカル通知のスケジュール更新
                self.scheduleLocalNotification(time: timeString)
            }
            self.showingAlert = true
        }
    }
    
    private func scheduleLocalNotification(time: String) {
        let center = UNUserNotificationCenter.current()
        
        // 既存の通知をキャンセル
        center.removeAllPendingNotificationRequests()
        
        guard isNotificationEnabled else { return }
        
        // 時間をパース
        let components = time.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return }
        
        // 通知内容
        let content = UNMutableNotificationContent()
        content.title = "今日の名言"
        content.body = "本日最も心に響いた名言をチェックしましょう"
        content.sound = .default
        
        // トリガー設定（毎日同じ時間）
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // リクエスト作成
        let request = UNNotificationRequest(identifier: "dailyQuote", content: content, trigger: trigger)
        
        // 通知を登録
        center.add(request) { error in
            if let error = error {
                print("通知登録エラー: \(error)")
            }
        }
    }
}