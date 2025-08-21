import SwiftUI

struct TermsAgreementView: View {
    @AppStorage("hasAgreedToTerms") private var hasAgreedToTerms = false
    @AppStorage("agreedTermsVersion") private var agreedTermsVersion = ""
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var hasReadTerms = false
    @State private var hasReadPrivacy = false
    
    let currentTermsVersion = "1.0.0"
    let onAgree: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // アプリアイコンとタイトル
            VStack(spacing: 20) {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.pink)
                
                Text("エミネンス")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("利用規約とプライバシーポリシー")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 50)
            
            // 重要な注意事項
            VStack(alignment: .leading, spacing: 15) {
                Label("不適切なコンテンツは禁止されています", systemImage: "hand.raised.fill")
                    .foregroundColor(.red)
                
                Label("利用規約違反の場合、利用制限される場合があります", systemImage: "xmark.shield.fill")
                    .foregroundColor(.red)
            }
            .padding(.horizontal)
            .font(.footnote)
            
            // 利用規約とプライバシーポリシーのボタン
            VStack(spacing: 15) {
                Button(action: {
                    showingTerms = true
                    hasReadTerms = true
                }) {
                    HStack {
                        Image(systemName: hasReadTerms ? "checkmark.circle.fill" : "doc.text")
                            .foregroundColor(hasReadTerms ? .green : .blue)
                        Text("利用規約を読む")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showingPrivacy = true
                    hasReadPrivacy = true
                }) {
                    HStack {
                        Image(systemName: hasReadPrivacy ? "checkmark.circle.fill" : "lock.doc")
                            .foregroundColor(hasReadPrivacy ? .green : .blue)
                        Text("プライバシーポリシーを読む")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 同意ボタン
            VStack(spacing: 10) {
                Button(action: {
                    hasAgreedToTerms = true
                    agreedTermsVersion = currentTermsVersion
                    onAgree()
                }) {
                    Text("上記の内容に同意して利用を開始")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasReadTerms && hasReadPrivacy ? Color.pink : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!(hasReadTerms && hasReadPrivacy))
                
                Text("不適切なコンテンツの投稿を行わないことに同意します")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showingTerms) {
            TermsWebView(url: URL(string: "https://sanq3.github.io/eminence-legal/legal-docs/terms.html")!)
        }
        .sheet(isPresented: $showingPrivacy) {
            TermsWebView(url: URL(string: "https://sanq3.github.io/eminence-legal/legal-docs/privacy.html")!)
        }
    }
}

struct TermsWebView: View {
    let url: URL
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            WebView(url: url)
                .navigationTitle("規約")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("閉じる") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// WebViewのラッパー
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}