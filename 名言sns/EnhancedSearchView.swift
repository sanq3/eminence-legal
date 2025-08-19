import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EnhancedSearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @EnvironmentObject var sharedQuoteViewModel: QuoteViewModel
    @State private var searchText = ""
    @State private var selectedSortType: SortType = .newest
    @State private var selectedQuote: Quote?
    
    enum SortType: String, CaseIterable {
        case newest = "新着順"
        case likes = "いいね数順"
        case replies = "返信数順"
        case oldest = "古い順"
        
        var systemImage: String {
            switch self {
            case .newest:
                return "clock"
            case .likes:
                return "heart.fill"
            case .replies:
                return "text.bubble"
            case .oldest:
                return "clock.arrow.circlepath"
            }
        }
    }
    
    private var sortedQuotes: [Quote] {
        let quotes = viewModel.searchResults
        switch selectedSortType {
        case .newest:
            return quotes.sorted { $0.createdAt > $1.createdAt }
        case .likes:
            return quotes.sorted { $0.likes > $1.likes }
        case .replies:
            return quotes.sorted { $0.replyCountValue > $1.replyCountValue }
        case .oldest:
            return quotes.sorted { $0.createdAt < $1.createdAt }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 検索結果がある場合のソート選択
                if !viewModel.searchResults.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SortType.allCases, id: \.self) { sortType in
                                Button(action: {
                                    selectedSortType = sortType
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: sortType.systemImage)
                                            .font(.caption)
                                        Text(sortType.rawValue)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedSortType == sortType ?
                                        Color.blue : Color(.systemGray6)
                                    )
                                    .foregroundColor(
                                        selectedSortType == sortType ?
                                        .white : .primary
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    
                    Divider()
                }
                
                // メインコンテンツ
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView("検索中...")
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else if searchText.isEmpty {
                            // 検索前の状態：今日の人気名言を表示
                            LazyVStack(spacing: 16) {
                                // 今日の人気名言セクション
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "flame.fill")
                                            .foregroundColor(.orange)
                                        Text("今日の人気名言")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    if viewModel.todayPopularQuotes.isEmpty {
                                        Text("まだ人気の名言がありません")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 16)
                                    } else {
                                        ForEach(viewModel.todayPopularQuotes.prefix(5)) { quote in
                                            QuoteCardView(
                                                quote: quote,
                                                viewModel: sharedQuoteViewModel,
                                                profileViewModel: profileViewModel,
                                                onTap: {
                                                    selectedQuote = quote
                                                },
                                                onEdit: { }
                                            )
                                        }
                                    }
                                }
                                
                                Spacer(minLength: 50)
                            }
                        } else if sortedQuotes.isEmpty && !viewModel.isLoading {
                            VStack(spacing: 20) {
                                Spacer().frame(height: 100)
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                Text("検索結果がありません")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("「\(searchText)」に一致する名言が見つかりません")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            .frame(minHeight: 300)
                        } else {
                            // 検索結果の表示
                            ForEach(sortedQuotes) { quote in
                                QuoteCardView(
                                    quote: quote,
                                    viewModel: sharedQuoteViewModel,
                                    profileViewModel: profileViewModel,
                                    onTap: {
                                        selectedQuote = quote
                                    },
                                    onEdit: { }
                                )
                            }
                            
                            // 検索結果の統計
                            Text("\(sortedQuotes.count)件の検索結果")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 16)
                                .padding(.bottom, 32)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("検索")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "名言や作者名で検索")
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchText) { newValue in
                if newValue.isEmpty {
                    viewModel.clearResults()
                } else if newValue.count >= 2 { // 2文字以上で自動検索
                    performSearch()
                }
            }
            .navigationTitle("検索")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "名言や作者名で検索")
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchText) { newValue in
                if newValue.isEmpty {
                    viewModel.clearResults()
                } else if newValue.count >= 2 {
                    performSearch()
                }
            }
            .navigationDestination(item: $selectedQuote) { quote in
                QuoteDetailView(quote: quote)
                    .environmentObject(sharedQuoteViewModel)
            }
        }
        .onAppear {
            viewModel.setSharedViewModel(sharedQuoteViewModel)
            viewModel.loadAllQuotes()
            
            // プロフィール情報をロード（adminバッジ確認のため）
            if Auth.auth().currentUser?.uid != nil && Auth.auth().currentUser?.isAnonymous == false {
                profileViewModel.loadUserProfile()
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        viewModel.search(query: searchText)
    }
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchResults: [Quote] = []
    @Published var todayPopularQuotes: [Quote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var quoteViewModel: QuoteViewModel = QuoteViewModel()
    private let db = Firestore.firestore()
    
    func setSharedViewModel(_ sharedViewModel: QuoteViewModel) {
        self.quoteViewModel = sharedViewModel
    }
    
    func loadAllQuotes() {
        quoteViewModel.fetchData()
        loadTodayPopularQuotes()
    }
    
    func loadTodayPopularQuotes() {
        // 今日の0時を計算
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        
        // 今日投稿された名言をいいね数順で取得
        db.collection("quotes")
            .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: today))
            .whereField("createdAt", isLessThan: Timestamp(date: tomorrow))
            .order(by: "likes", descending: true)
            .limit(to: 10)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error loading today's popular quotes: \(error)")
                        // エラーの場合は全期間からのトップを取得
                        self?.loadAllTimePopularQuotes()
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        // データがない場合は全期間からのトップを取得
                        self?.loadAllTimePopularQuotes()
                        return
                    }
                    
                    let quotes = documents.compactMap { doc -> Quote? in
                        do {
                            var quote = try doc.data(as: Quote.self)
                            quote.id = doc.documentID
                            return quote
                        } catch {
                            print("Error decoding today's quote: \(error)")
                            return nil
                        }
                    }
                    
                    self?.todayPopularQuotes = quotes
                    
                    // 今日のデータが少ない場合は全期間のデータで補完
                    if quotes.count < 3 {
                        self?.loadAllTimePopularQuotes()
                    }
                }
            }
    }
    
    private func loadAllTimePopularQuotes() {
        
        db.collection("quotes")
            .order(by: "likes", descending: true)
            .limit(to: 10)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error loading all-time popular quotes: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        return
                    }
                    
                    let quotes = documents.compactMap { doc -> Quote? in
                        do {
                            var quote = try doc.data(as: Quote.self)
                            quote.id = doc.documentID
                            return quote
                        } catch {
                            print("Error decoding all-time quote: \(error)")
                            return nil
                        }
                    }
                    
                    // 今日のデータがある場合は結合、ない場合は置換
                    if self?.todayPopularQuotes.isEmpty == true {
                        self?.todayPopularQuotes = quotes
                    } else {
                        // 重複を避けて結合
                        let existingIds = Set(self?.todayPopularQuotes.compactMap { $0.id } ?? [])
                        let additionalQuotes = quotes.filter { !existingIds.contains($0.id ?? "") }
                        self?.todayPopularQuotes.append(contentsOf: additionalQuotes)
                    }
                }
            }
    }
    
    func search(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            clearResults()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // ローカル検索（すでに読み込まれたデータから）
        let localResults = quoteViewModel.quotes.filter { quote in
            quote.text.localizedCaseInsensitiveContains(query) ||
            quote.author.localizedCaseInsensitiveContains(query)
        }
        
        // Firestore検索も並行実行（より多くの結果を取得）
        searchInFirestore(query: query) { firestoreResults in
            DispatchQueue.main.async {
                // ローカル結果とFirestore結果を統合（重複除去）
                let combinedResults = self.combineResults(local: localResults, firestore: firestoreResults)
                self.searchResults = combinedResults
                self.isLoading = false
                
#if DEBUG
                print("Search completed - Local: \(localResults.count), Firestore: \(firestoreResults.count), Combined: \(combinedResults.count)")
                #endif
            }
        }
        
        // とりあえずローカル結果を即座に表示
        self.searchResults = localResults
    }
    
    private func searchInFirestore(query: String, completion: @escaping ([Quote]) -> Void) {
        // Firestoreでは複数のクエリを実行（テキスト検索の制限のため）
        var allResults: [Quote] = []
        let dispatchGroup = DispatchGroup()
        
        // テキスト検索（部分一致は制限があるため、前方一致で検索）
        let searchTerms = query.lowercased().components(separatedBy: " ").filter { !$0.isEmpty }
        
        for term in searchTerms.prefix(3) { // 最大3つのキーワードで検索
            dispatchGroup.enter()
            
            db.collection("quotes")
                .order(by: "text")
                .start(at: [term])
                .end(at: [term + "\u{f8ff}"])
                .limit(to: 20)
                .getDocuments { snapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("Firestore search error: \(error)")
                        return
                    }
                    
                    let quotes = snapshot?.documents.compactMap { doc -> Quote? in
                        do {
                            var quote = try doc.data(as: Quote.self)
                            quote.id = doc.documentID
                            return quote
                        } catch {
                            print("Error decoding quote: \(error)")
                            return nil
                        }
                    } ?? []
                    
                    allResults.append(contentsOf: quotes)
                }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(allResults)
        }
    }
    
    private func combineResults(local: [Quote], firestore: [Quote]) -> [Quote] {
        var combined = local
        
        // Firestore結果から、ローカルにない結果を追加
        for firestoreQuote in firestore {
            if !combined.contains(where: { $0.id == firestoreQuote.id }) {
                combined.append(firestoreQuote)
            }
        }
        
        return combined
    }
    
    func clearResults() {
        searchResults = []
        errorMessage = nil
    }
}

#Preview {
    EnhancedSearchView()
        .environmentObject(QuoteViewModel())
}