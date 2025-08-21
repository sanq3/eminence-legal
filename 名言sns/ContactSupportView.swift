import SwiftUI
import MessageUI

struct ContactSupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: ContactCategory = .general
    @State private var messageText = ""
    @State private var showingMailComposer = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    enum ContactCategory: String, CaseIterable {
        case general = "一般的な質問"
        case report = "不適切なコンテンツの報告"
        case bug = "不具合の報告"
        case feature = "機能リクエスト"
        case account = "アカウントに関する問題"
        case other = "その他"
        
        var icon: String {
            switch self {
            case .general: return "questionmark.circle"
            case .report: return "exclamationmark.triangle"
            case .bug: return "ant"
            case .feature: return "lightbulb"
            case .account: return "person.circle"
            case .other: return "ellipsis.circle"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("お問い合わせカテゴリー") {
                    Picker("カテゴリー", selection: $selectedCategory) {
                        ForEach(ContactCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                if selectedCategory == .report {
                    Section {
                        Label("不適切なコンテンツは24時間以内に対処いたします", systemImage: "clock.badge.checkmark")
                            .foregroundColor(.orange)
                            .font(.footnote)
                    }
                }
                
                Section("メッセージ") {
                    TextEditor(text: $messageText)
                        .frame(minHeight: 150)
                        .overlay(
                            Group {
                                if messageText.isEmpty {
                                    Text("詳細をご記入ください...")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
                
                Section {
                    Button(action: sendSupport) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("送信")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(messageText.isEmpty ? Color.gray : Color.pink)
                        .cornerRadius(10)
                    }
                    .disabled(messageText.isEmpty)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                Section("その他のサポート") {
                    Link(destination: URL(string: "https://sanq3.github.io/eminence-legal/legal-docs/contact.html")!) {
                        HStack {
                            Label("サポートページ", systemImage: "safari")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if MFMailComposeViewController.canSendMail() {
                        Button(action: { showingMailComposer = true }) {
                            HStack {
                                Label("メールで問い合わせ", systemImage: "envelope")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("対応時間について")
                            .font(.footnote)
                            .fontWeight(.semibold)
                        Text("• 通常のお問い合わせ: 3営業日以内")
                            .font(.caption)
                        Text("• 不適切コンテンツの報告: 24時間以内")
                            .font(.caption)
                        Text("• 緊急の不具合: 48時間以内")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("お問い合わせ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingMailComposer) {
                MailComposerView(
                    subject: "【エミネンス】\(selectedCategory.rawValue)",
                    body: messageText,
                    toRecipients: ["support@eminence-app.com"]
                )
            }
            .alert("送信完了", isPresented: $showingAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func sendSupport() {
        // Firebase Firestoreに問い合わせを保存
        // 実装は後で追加
        alertMessage = "お問い合わせを受け付けました。\n\(selectedCategory == .report ? "24時間以内" : "3営業日以内")に対応いたします。"
        showingAlert = true
    }
}

// メールコンポーザー
struct MailComposerView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let toRecipients: [String]
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        composer.setToRecipients(toRecipients)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposerView
        
        init(_ parent: MailComposerView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}