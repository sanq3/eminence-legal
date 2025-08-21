
import SwiftUI
import FirebaseAuth

struct AddQuoteView: View {
    @Environment(\.dismiss) var dismiss
    @State private var text: String = ""
    @State private var author: String = ""
    @State private var showingTermsAgreement = false
    @State private var isPosting = false  // 投稿中フラグ
    @AppStorage("hasAgreedToTerms") private var hasAgreedToTerms = false
    @AppStorage("agreedTermsVersion") private var agreedTermsVersion = ""
    
    let currentTermsVersion = "1.0.0"

    var onAdd: (Quote) -> Void
    
    private var isLoggedIn: Bool {
        Auth.auth().currentUser?.isAnonymous == false
    }
    
    private var placeholderText: String {
        if isLoggedIn {
            return "作者（空白でユーザー名を使用）"
        } else {
            return "作者（空白で匿名）"
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("新しい言葉")) {
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("心に残った言葉を共有しましょう")
                                .foregroundColor(Color(UIColor.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        TextEditor(text: $text)
                            .frame(height: 150)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.sentences)
                    }
                    TextField(placeholderText, text: $author)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("投稿する")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isPosting ? "投稿中..." : "投稿") {
                        // 投稿中は処理しない（連打防止）
                        guard !isPosting else { return }
                        
                        // 利用規約に同意していない場合は同意画面を表示
                        if !hasAgreedToTerms || agreedTermsVersion != currentTermsVersion {
                            showingTermsAgreement = true
                        } else {
                            // 同意済みの場合は投稿処理を実行
                            postQuote()
                        }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPosting)
                }
            }
        }
        .sheet(isPresented: $showingTermsAgreement) {
            TermsAgreementView {
                // 同意後に投稿処理を実行
                postQuote()
            }
        }
    }
    
    private func postQuote() {
        // 連打防止フラグを設定
        isPosting = true
        
        let authorName = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let uid = Auth.auth().currentUser?.uid ?? ""
        let newQuote = Quote(text: text, author: authorName, authorUid: uid)
        
        // 投稿処理を実行
        onAdd(newQuote)
        
        // 投稿後、画面を自動的に閉じる
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}
