import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class BookmarkListener: ObservableObject {
    var listener: ListenerRegistration?
    
    deinit {
        listener?.remove()
    }
}

struct BookmarkOnlyView: View {
    @ObservedObject var viewModel: QuoteViewModel
    @State private var allBookmarkedQuotes: [Quote] = []
    @State private var displayedQuotes: [Quote] = []
    @State private var isLoading = true
    @State private var selectedQuote: Quote?
    @State private var currentIndex = 0
    @StateObject private var bookmarkListener = BookmarkListener()
    
    private let quotesPerLoad = 10
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("読み込み中...")
            } else if allBookmarkedQuotes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("ブックマークした名言がありません")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("名言をブックマークすると\nここに表示されます")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(displayedQuotes) { quote in
                            BookmarkOnlyCard(quote: quote) {
                                selectedQuote = quote
                            }
                        }
                        
                        // 無限スクロール用のローディング
                        if currentIndex < allBookmarkedQuotes.count {
                            HStack {
                                Spacer()
                                Text("さらに読み込む")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding()
                            .onAppear {
                                loadMoreQuotes()
                            }
                        } else if allBookmarkedQuotes.count > quotesPerLoad {
                            // すべて表示し終わったら最初から再表示
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Text("すべての名言を表示しました")
                                        .foregroundColor(.secondary)
                                    Button("最初から表示") {
                                        resetAndReload()
                                    }
                                    .foregroundColor(.blue)
                                }
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                .refreshable {
                    loadBookmarkedQuotes()
                }
            }
        }
        .onAppear {
            startListeningToBookmarks()
        }
        .onDisappear {
            bookmarkListener.listener?.remove()
            bookmarkListener.listener = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshHome"))) { _ in
            loadBookmarkedQuotes()
        }
        .navigationDestination(item: $selectedQuote) { quote in
            QuoteDetailView(quote: quote)
                .environmentObject(viewModel)
        }
    }
    
    private func startListeningToBookmarks() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print(" No authenticated user for bookmarks listener")
            isLoading = false
            return
        }
        
        print(" Starting bookmark listener for user: \(userId)")
        
        // 既存のリスナーを削除
        bookmarkListener.listener?.remove()
        
        // リアルタイムリスナーを設定（インデックス不要のシンプルクエリ）
        bookmarkListener.listener = Firestore.firestore()
            .collection("quotes")
            .whereField("bookmarkedBy", arrayContains: userId)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("ERROR: Bookmark listener failed: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print(" No documents in snapshot")
                        return
                    }
                    
                    print(" Bookmark listener received \(documents.count) quotes")
                    
                    do {
                        var quotes = try documents.compactMap { document in
                            let quote = try document.data(as: Quote.self)
                            return quote
                        }
                        
                        print(" Successfully processed \(quotes.count) bookmarked quotes")
                        
                        // 日付でソートしてからシャッフル
                        quotes.sort { $0.createdAt > $1.createdAt }
                        quotes.shuffle()
                        self.allBookmarkedQuotes = quotes
                        
                        // 表示をリセット
                        self.currentIndex = 0
                        self.displayedQuotes = []
                        self.loadMoreQuotes()
                    } catch {
                        print("ERROR: Failed to process bookmarks: \(error)")
                    }
                }
            }
    }
    
    private func loadBookmarkedQuotes() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print(" No authenticated user for bookmarks")
            isLoading = false
            return
        }
        
        print(" Loading bookmarks for user: \(userId)")
        
        Firestore.firestore()
            .collection("quotes")
            .whereField("bookmarkedBy", arrayContains: userId)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let error = error {
                        print("ERROR: Failed to fetch bookmarks: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print(" No documents returned")
                        return
                    }
                    
                    print(" Found \(documents.count) bookmarked quotes")
                    
                    do {
                        var quotes = try documents.compactMap { document in
                            let quote = try document.data(as: Quote.self)
                            print(" Loaded quote: \(quote.text.prefix(30))...")
                            return quote
                        }
                        
                        print(" Successfully decoded \(quotes.count) quotes")
                        
                        // 日付でソートしてからシャッフル
                        quotes.sort { $0.createdAt > $1.createdAt }
                        quotes.shuffle()
                        allBookmarkedQuotes = quotes
                        
                        // 初期表示分を設定
                        currentIndex = 0
                        displayedQuotes = []
                        loadMoreQuotes()
                    } catch {
                        print("ERROR: Failed to decode bookmarked quotes: \(error)")
                    }
                }
            }
    }
    
    private func loadMoreQuotes() {
        guard currentIndex < allBookmarkedQuotes.count else { return }
        
        let endIndex = min(currentIndex + quotesPerLoad, allBookmarkedQuotes.count)
        let newQuotes = Array(allBookmarkedQuotes[currentIndex..<endIndex])
        
        withAnimation(.easeInOut(duration: 0.3)) {
            displayedQuotes.append(contentsOf: newQuotes)
        }
        
        currentIndex = endIndex
    }
    
    private func resetAndReload() {
        // 新しいランダム順序で再開
        allBookmarkedQuotes.shuffle()
        currentIndex = 0
        displayedQuotes = []
        loadMoreQuotes()
    }
}

struct BookmarkOnlyCard: View {
    let quote: Quote
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 名言テキスト - カード全体の中央配置
                Text(quote.text)
                    .font(.system(.body, design: .serif))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                
                // 作者名 - 右下配置
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("— \(quote.author.isEmpty ? "匿名" : quote.author) —")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.indigo.opacity(0.03))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BookmarkOnlyView(viewModel: QuoteViewModel())
}