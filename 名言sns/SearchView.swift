import SwiftUI
import FirebaseAuth

struct SearchView: View {
    @StateObject private var viewModel = QuoteViewModel()
    @State private var searchText = ""
    @State private var showingAddQuoteView = false
    @State private var quoteToEdit: Quote?

    var filteredQuotes: [Quote] {
        if searchText.isEmpty {
            return []
        } else {
            return viewModel.quotes.filter {
                $0.text.localizedCaseInsensitiveContains(searchText) || $0.author.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if searchText.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("名言を検索")
                            .font(.title2)
                            .fontWeight(.medium)
                        Text("名言や作者名で検索してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else if filteredQuotes.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Text("「\(searchText)」の検索結果はありません")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredQuotes) { quote in
                                VStack(spacing: 0) {
                                    // メイン名言エリア
                                    VStack(spacing: 0) {
                                        Spacer()
                                        
                                        Text(quote.text)
                                            .font(.title3)
                                            .fontWeight(.medium)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding(.horizontal, 20)
                                        
                                        Spacer()
                                        
                                        HStack {
                                            Spacer()
                                            Text(quote.author.isEmpty ? "匿名" : quote.author)
                                                .font(.system(.subheadline, design: .serif))
                                                .foregroundColor(.secondary)
                                                .padding(.trailing, 20)
                                                .padding(.bottom, 12)
                                        }
                                    }
                                    .frame(minHeight: 120)
                                    .padding(.top, 20)
                                    
                                    Divider()
                                        .padding(.horizontal, 16)
                                    
                                    HStack(spacing: 0) {
                                        // Reply Button - 詳細画面に遷移
                                        NavigationLink(destination: QuoteDetailView(quote: quote).environmentObject(viewModel)) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "text.bubble")
                                                Text("\(quote.replyCountValue)")
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                        }
                                        .buttonStyle(.plain)

                                        Divider()
                                            .frame(height: 20)

                                        // Like Button
                                        Button(action: {
                                            viewModel.likeQuote(quote: quote)
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: quote.likedBy.contains(Auth.auth().currentUser?.uid ?? "") ? "heart.fill" : "heart")
                                                Text("\(quote.likes)")
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(quote.likedBy.contains(Auth.auth().currentUser?.uid ?? "") ? .pink : .secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                        }

                                        Divider()
                                            .frame(height: 20)

                                        // Bookmark Button
                                        Button(action: {
                                            viewModel.bookmarkQuote(quote: quote)
                                        }) {
                                            Image(systemName: quote.bookmarkedByArray.contains(Auth.auth().currentUser?.uid ?? "") ? "bookmark.fill" : "bookmark")
                                                .font(.subheadline)
                                                .foregroundColor(quote.bookmarkedByArray.contains(Auth.auth().currentUser?.uid ?? "") ? .orange : .secondary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .contextMenu {
                                    if quote.authorUid == Auth.auth().currentUser?.uid ?? "" {
                                        Button {
                                            quoteToEdit = quote
                                        } label: {
                                            Label("編集", systemImage: "pencil")
                                        }
                                        Button(role: .destructive) {
                                            viewModel.deleteData(quote: quote)
                                        } label: {
                                            Label("削除", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("検索")
            .searchable(text: $searchText, prompt: "名言や作者名で検索")
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            .onAppear {
                viewModel.signInAnonymouslyIfNeeded()
                if viewModel.quotes.isEmpty {
                    viewModel.fetchData()
                }
            }
            .sheet(item: $quoteToEdit) { quote in
                EditQuoteView(quote: quote) { updatedQuote in
                    viewModel.updateData(quote: updatedQuote)
                }
            }
        }
    }
}

#Preview {
    SearchView()
}