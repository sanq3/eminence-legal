import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DailyQuoteView: View {
    @EnvironmentObject var viewModel: QuoteViewModel
    @Binding var shouldShow: Bool
    @State private var todayQuote: Quote?
    @State private var isLoading = true
    var onTapBookmark: (() -> Void)?
    
    var body: some View {
        Group {
            if isLoading {
                // ローディング表示
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 160)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
            } else if let quote = todayQuote {
                // ウィジェット風の今日の名言表示
                ZStack {
                    LinearGradient(
                        colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(spacing: 12) {
                        // ヘッダー
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("今日のあなたへ")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Text("ブックマークから")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                            Image(systemName: "quote.bubble.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        // 名言テキスト
                        Text(quote.text)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .frame(maxWidth: .infinity)
                        
                        // 作者名
                        HStack {
                            Spacer()
                            Text("- \(quote.author.isEmpty ? "匿名" : quote.author)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(16)
                }
                .frame(height: 160)
                .cornerRadius(16)
                .onTapGesture {
                    onTapBookmark?()
                }
            } else {
                // ブックマークがない場合のデフォルト表示
                ZStack {
                    LinearGradient(
                        colors: [Color.gray.opacity(0.6), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(spacing: 8) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("名言をブックマークしよう")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("お気に入りの名言をブックマークすると\nここに表示されます")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(16)
                }
                .frame(height: 160)
                .cornerRadius(16)
            }
        }
        .onAppear {
            loadRandomBookmarkQuote()
        }
    }
    
    private func loadRandomBookmarkQuote() {
        guard let userId = Auth.auth().currentUser?.uid else {
            // ユーザーが認証されていない場合はデフォルト名言を表示
            loadDefaultQuote()
            return
        }
        
        // ブックマークした名言からランダムに1つ選択
        Firestore.firestore()
            .collection("quotes")
            .whereField("bookmarkedBy", arrayContains: userId)
            .getDocuments { [self] snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let error = error {
                        print("今日の名言取得エラー: \(error)")
                        loadDefaultQuote()
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        loadDefaultQuote()
                        return
                    }
                    
                    // 完全にランダムに1つ選択（起動のたびに変わる）
                    let randomIndex = Int.random(in: 0..<documents.count)
                    
                    do {
                        todayQuote = try documents[randomIndex].data(as: Quote.self)
                    } catch {
                        print("名言デコードエラー: \(error)")
                        loadDefaultQuote()
                    }
                }
            }
    }
    
    private func loadDefaultQuote() {
        let defaultQuotes = [
            Quote(text: "人生は旅路のようなもの。大切なのは目的地ではなく、その旅路で学んだことと、出会った人たちとの思い出だ。", author: "匿名"),
            Quote(text: "夢を持ち続ける勇気があれば、すべての夢は必ず実現できる。", author: "ウォルト・ディズニー"),
            Quote(text: "失敗とは、より賢いやり方で再び挑戦する機会である。", author: "ヘンリー・フォード"),
            Quote(text: "今日という日は、残りの人生の最初の日である。", author: "アビー・ホフマン"),
            Quote(text: "成功への道は、失敗への道でもある。重要なのは諦めないこと。", author: "匿名")
        ]
        
        // 日付ベースでランダム選択
        let today = Calendar.current.dateInterval(of: .day, for: Date())?.start ?? Date()
        let daysSince2024 = Int(today.timeIntervalSince(Date(timeIntervalSince1970: 1704067200))) / (24 * 3600)
        let index = daysSince2024 % defaultQuotes.count
        
        todayQuote = defaultQuotes[index]
    }
}

