
import SwiftUI
import UIKit
import FirebaseAuth

struct ContentView: View {
    @ObservedObject var viewModel: QuoteViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    @State private var showingAddQuoteView = false
    @State private var quoteToEdit: Quote?
    @State private var selectedQuote: Quote?
    @State private var currentPage = 0
    @State private var isFirstLaunch = true
    @State private var showingTermsAgreement = false
    @AppStorage("hasAgreedToTermsAnonymous") private var hasAgreedToTermsAnonymous = false

    var body: some View {
        NavigationStack {
            ZStack {
                // ページビュー機能
                TabView(selection: $currentPage) {
                    // ホーム画面（通常の投稿一覧）
                    Group {
                        if viewModel.isLoading && viewModel.quotes.isEmpty {
                            ProgressView("読み込み中...")
                        } else if viewModel.quotes.isEmpty {
                            Text("まだ投稿がありません。最初の言葉を投稿してみましょう！")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                        } else {
                            ScrollViewReader { proxy in
                                ScrollView {
                                    LazyVStack(spacing: 16) {
                                        // スクロール位置の目印
                                        Color.clear
                                            .frame(height: 0)
                                            .id("top")
                                        
                                        // 今日の名言（初回起動時のみ表示）
                                        if isFirstLaunch {
                                            DailyQuoteView(shouldShow: $isFirstLaunch) {
                                                // タップでブックマーク画面に切り替え
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    currentPage = 1
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .environmentObject(viewModel)
                                        }
                                        
                                        ForEach(viewModel.quotes) { quote in
                                            QuoteCardView(
                                                quote: quote,
                                                viewModel: viewModel,
                                                profileViewModel: profileViewModel,
                                                onTap: { selectedQuote = quote },
                                                onEdit: { quoteToEdit = quote }
                                            )
                                        }
                                        
                                        // 無限スクロール用のローディングインジケータ
                                        if viewModel.hasMoreData {
                                            HStack {
                                                Spacer()
                                                if viewModel.isLoadingMore {
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle())
                                                } else {
                                                    Text("さらに読み込む")
                                                        .foregroundColor(.secondary)
                                                }
                                                Spacer()
                                            }
                                            .padding()
                                            .onAppear {
                                                viewModel.loadMoreData()
                                            }
                                        }
                                    }
                                    .padding(.top, 16)
                                }
                                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScrollToTop"))) { _ in
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        proxy.scrollTo("top", anchor: .top)
                                    }
                                }
                                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshHome"))) { _ in
                                    viewModel.fetchData()
                                }
                            }
                            .refreshable {
                                viewModel.fetchData()
                            }
                        }
                    }
                    .tag(0)
                    
                    // ブックマーク専用画面
                    BookmarkOnlyView(viewModel: viewModel)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScrollToTop"))) { _ in
                    // ホーム画面でない場合は、ホーム画面に切り替え
                    if currentPage != 0 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage = 0
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TabChanged"))) { _ in
                    // 他のタブに移動したら初回起動フラグをfalseにする
                    isFirstLaunch = false
                }
                .onChange(of: currentPage) { newValue in
                    // ブックマーク画面に移動したら初回起動フラグをfalseにする
                    if newValue == 1 {
                        isFirstLaunch = false
                    }
                }
                
                // Twitter風の右下投稿ボタン（ホーム画面のみ表示）
                if currentPage == 0 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showingAddQuoteView = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .padding(.bottom, 20)
                            .padding(.trailing, 20)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text(currentPage == 0 ? "ホーム" : "ブックマーク")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        // ページインジケーター
                        HStack(spacing: 6) {
                            Circle()
                                .fill(currentPage == 0 ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 5, height: 5)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                            
                            Circle()
                                .fill(currentPage == 1 ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 5, height: 5)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }
                }
            }
            .onAppear {
                // アプリは認証なしでも動作するため、認証試行は一回のみ
                // 認証に失敗してもアプリは正常に動作する
                if Auth.auth().currentUser == nil {
                    viewModel.signInAnonymouslyIfNeeded()
                }
                if viewModel.quotes.isEmpty {
                    viewModel.fetchData()
                }
                // ログイン済みユーザーの場合、プロフィールを読み込む
                if Auth.auth().currentUser?.isAnonymous == false {
                    profileViewModel.loadUserProfile()
                }
                
                // 未ログインユーザーで初回起動時のみ利用規約同意ポップアップを表示
                if !hasAgreedToTermsAnonymous && (Auth.auth().currentUser == nil || Auth.auth().currentUser?.isAnonymous == true) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingTermsAgreement = true
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserLoggedIn"))) { _ in
                // ログイン後、データをリフレッシュしていいね状態を更新
                viewModel.fetchData()
                profileViewModel.loadUserProfile()
            }
            .sheet(isPresented: $showingAddQuoteView) {
                AddQuoteView { newQuote in
                    viewModel.addData(quote: newQuote, userProfile: profileViewModel.userProfile)
                }
            }
            .sheet(item: $quoteToEdit) { quote in
                EditQuoteView(quote: quote) { updatedQuote in
                    viewModel.updateData(quote: updatedQuote)
                }
            }
            .navigationDestination(item: $selectedQuote) { quote in
                QuoteDetailView(quote: quote)
                    .environmentObject(viewModel)
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("再試行") {
                    viewModel.errorMessage = nil
                    viewModel.fetchData()
                }
                Button("キャンセル", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            }, message: {
                Text(viewModel.errorMessage ?? "不明なエラーが発生しました。")
            })
            .fullScreenCover(isPresented: $showingTermsAgreement) {
                TermsAgreementView(onAgree: {
                    hasAgreedToTermsAnonymous = true
                    showingTermsAgreement = false
                })
            }
        }
    }

}

#Preview {
    ContentView(viewModel: QuoteViewModel(), profileViewModel: ProfileViewModel())
}
