import SwiftUI
import FirebaseAuth

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @EnvironmentObject var quoteViewModel: QuoteViewModel
    @State private var selectedQuote: Quote?
    
    var body: some View {
        NavigationView {
            contentView
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationDestination(item: $selectedQuote) { quote in
            QuoteDetailView(quote: quote)
                .environmentObject(quoteViewModel)
        }
        .onAppear {
            viewModel.fetchNotifications()
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("了解") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.notifications.isEmpty {
                ProgressView("通知を読み込み中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.notifications.isEmpty {
                emptyStateView
            } else {
                notificationListView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("通知がありません")
                .font(.title2)
                .fontWeight(.medium)
            Text("いいねやリプライがあると\nここに通知が表示されます")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var notificationListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.notifications) { notification in
                    NotificationRowView(
                        notification: notification,
                        onTap: {
                            handleNotificationTap(notification)
                        }
                    )
                    .onAppear {
                        // 表示されたら既読にする
                        if !notification.isRead {
                            viewModel.markAsRead(notification)
                        }
                    }
                    
                    Divider()
                        .padding(.leading, 60)
                }
            }
        }
        .refreshable {
            await viewModel.refreshNotifications()
        }
    }
    
    private func handleNotificationTap(_ notification: AppNotification) {
        
        switch notification.type {
        case .like, .reply:
            // 対象の名言を取得して詳細画面へ
            if let quoteId = notification.relatedQuoteId {
                fetchQuoteAndNavigate(quoteId: quoteId)
            } else {
            }
        case .follow:
            // プロフィール画面への遷移（将来実装）
            break
        }
    }
    
    private func fetchQuoteAndNavigate(quoteId: String) {
        // QuoteViewModelから該当のQuoteを探す
        if let existingQuote = quoteViewModel.quotes.first(where: { $0.id == quoteId }) {
            selectedQuote = existingQuote
            return
        }
        
        // なければFirestoreから直接取得
        viewModel.fetchQuoteById(quoteId) { quote in
            if let quote = quote {
                DispatchQueue.main.async {
                    selectedQuote = quote
                }
            }
        }
    }
}

struct NotificationRowView: View {
    let notification: AppNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // アイコン
                notificationIcon
                    .frame(width: 36, height: 36)
                    .background(notificationColor.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    // メッセージ
                    Text(notification.message)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    // リプライの場合はリプライ内容を表示
                    if notification.type == .reply, let replyText = notification.replyText {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("リプライ:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("「\(replyText.prefix(50))\(replyText.count > 50 ? "..." : "")」")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }
                        .padding(.top, 2)
                    }
                    
                    // 関連する名言のテキスト（もしあれば）
                    if let quoteText = notification.relatedQuoteText {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("あなたの名言:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("「\(quoteText.prefix(50))\(quoteText.count > 50 ? "..." : "")」")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.top, 2)
                    }
                    
                    // 時刻
                    Text(notification.createdAt.timeAgoDisplay())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 未読インディケータ
                if !notification.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            notification.isRead ? Color.clear : Color.blue.opacity(0.05)
        )
    }
    
    private var notificationIcon: some View {
        Image(systemName: notificationIconName)
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(notificationColor)
    }
    
    private var notificationIconName: String {
        switch notification.type {
        case .like:
            return "heart.fill"
        case .reply:
            return "bubble.left.fill"
        case .follow:
            return "person.fill.badge.plus"
        }
    }
    
    private var notificationColor: Color {
        switch notification.type {
        case .like:
            return .pink
        case .reply:
            return .blue
        case .follow:
            return .green
        }
    }
}

// Date の拡張（時間表示用）
extension Date {
    func timeAgoDisplay() -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear], from: self, to: now)
        
        if let weeks = components.weekOfYear, weeks > 0 {
            return "\(weeks)週間前"
        } else if let days = components.day, days > 0 {
            return "\(days)日前"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)時間前"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 0 ? "たった今" : "\(minutes)分前"
        } else {
            return "たった今"
        }
    }
}

#Preview {
    NotificationView()
        .environmentObject(QuoteViewModel())
}