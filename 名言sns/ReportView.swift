import SwiftUI

enum ReportTargetType {
    case quote
    case user
    case reply
}

struct ReportView: View {
    let targetType: ReportTargetType
    let targetId: String
    let onSubmit: (ReportReason, String?) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedReason: ReportReason = .inappropriate
    @State private var additionalInfo: String = ""
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("報告理由を選択") {
                    Picker("理由", selection: $selectedReason) {
                        ForEach(ReportReason.allCases, id: \.self) { reason in
                            Text(reason.description).tag(reason)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 150)
                }
                
                Section("詳細（任意）") {
                    TextEditor(text: $additionalInfo)
                        .frame(minHeight: 100)
                        .placeholder(when: additionalInfo.isEmpty) {
                            Text("詳細な情報があれば入力してください")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                }
                
                Section {
                    Text("報告は慎重に検討されます。虚偽の報告は利用制限の対象となる場合があります。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(
                targetType == .quote ? "投稿を報告" :
                targetType == .user ? "ユーザーを報告" :
                "コメントを報告"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("送信") {
                        onSubmit(selectedReason, additionalInfo.isEmpty ? nil : additionalInfo)
                        showingSuccessAlert = true
                    }
                    .fontWeight(.bold)
                }
            }
            .alert("報告を送信しました", isPresented: $showingSuccessAlert) {
                Button("了解") {
                    dismiss()
                }
            } message: {
                Text("ご報告ありがとうございます。内容を確認後、適切に対処いたします。")
            }
        }
    }
}

// TextEditorのプレースホルダー用Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}