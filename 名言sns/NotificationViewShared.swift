import SwiftUI
import FirebaseAuth

struct NotificationViewShared: View {
    @ObservedObject var notificationViewModel: NotificationViewModel
    @EnvironmentObject var quoteViewModel: QuoteViewModel
    @State private var selectedQuote: Quote?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if notificationViewModel.isLoading && notificationViewModel.notifications.isEmpty {
                    ProgressView("通知を読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if notificationViewModel.notifications.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        // アイコン
                        Image(systemName: Auth.auth().currentUser?.isAnonymous == true ? "bell.badge" : "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(Auth.auth().currentUser?.isAnonymous == true ? .blue : .secondary)
                        
                        // タイトル
                        if Auth.auth().currentUser?.isAnonymous == true {
                            Text("通知機能を使ってみよう")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 16) {
                                Text("アカウントを作成すると以下の通知が受け取れます")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.pink)
                                            .frame(width: 20)
                                        Text("あなたの名言へのいいね通知")
                                            .font(.subheadline)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Image(systemName: "bubble.left.fill")
                                            .foregroundColor(.blue)
                                            .frame(width: 20)
                                        Text("あなたの名言へのリプライ通知")
                                            .font(.subheadline)
                                    }
                                }
                                .padding(.horizontal, 40)
                                
                                NavigationLink(destination: AuthenticationView()) {
                                    Text("アカウントを作成")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: 200)
                                        .padding(.vertical, 12)
                                        .background(Color.blue)
                                        .cornerRadius(25)
                                }
                                .padding(.top, 8)
                            }
                        } else {
                            Text("通知がありません")
                                .font(.title2)
                                .fontWeight(.medium)
                            Text("いいねやリプライがあると\nここに通知が表示されます")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(notificationViewModel.notifications) { notification in
                                NotificationRowView(
                                    notification: notification,
                                    onTap: {
                                        handleNotificationTap(notification)
                                    }
                                )
                                .onAppear {
                                    if !notification.isRead {
                                        notificationViewModel.markAsRead(notification)
                                    }
                                }
                                
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .refreshable {
                        await notificationViewModel.refreshNotifications()
                    }
                }
            }
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedQuote) { quote in
                QuoteDetailView(quote: quote)
                    .environmentObject(quoteViewModel)
            }
        }
        .onAppear {
            notificationViewModel.fetchNotifications()
        }
        .alert("エラー", isPresented: .constant(notificationViewModel.errorMessage != nil)) {
            Button("了解") {
                notificationViewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = notificationViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func handleNotificationTap(_ notification: AppNotification) {
        
        switch notification.type {
        case .like, .reply:
            if let quoteId = notification.relatedQuoteId {
                fetchQuoteAndNavigate(quoteId: quoteId)
            } else {
            }
        case .follow:
            break
        }
    }
    
    private func fetchQuoteAndNavigate(quoteId: String) {
        if let existingQuote = quoteViewModel.quotes.first(where: { $0.id == quoteId }) {
            selectedQuote = existingQuote
            return
        }
        
        notificationViewModel.fetchQuoteById(quoteId) { quote in
            if let quote = quote {
                DispatchQueue.main.async {
                    selectedQuote = quote
                }
            }
        }
    }
}