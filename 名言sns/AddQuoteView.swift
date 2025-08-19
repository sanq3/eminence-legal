
import SwiftUI
import FirebaseAuth

struct AddQuoteView: View {
    @Environment(\.dismiss) var dismiss
    @State private var text: String = ""
    @State private var author: String = ""

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
                    Button("保存") {
                        let authorName = author.trimmingCharacters(in: .whitespacesAndNewlines)
                        let uid = Auth.auth().currentUser?.uid ?? ""
                        let newQuote = Quote(text: text, author: authorName, authorUid: uid)
                        onAdd(newQuote)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
