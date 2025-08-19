import SwiftUI

struct EditQuoteView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var text: String
    @State private var author: String
    
    private let quote: Quote
    var onSave: (Quote) -> Void

    init(quote: Quote, onSave: @escaping (Quote) -> Void) {
        self.quote = quote
        self.onSave = onSave
        _text = State(initialValue: quote.text)
        _author = State(initialValue: quote.author)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("言葉を編集")) {
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("心に残った言葉を共有しましょう")
                                .foregroundColor(Color(UIColor.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        TextEditor(text: $text)
                            .frame(height: 150)
                    }
                    TextField("作者（空白で匿名の投稿）", text: $author)
                }
            }
            .navigationTitle("編集")
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
                        // Create a new Quote object with the same id and createdAt
                        var updatedQuote = quote
                        updatedQuote.text = text
                        updatedQuote.author = authorName
                        
                        onSave(updatedQuote)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
