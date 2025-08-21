import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

// バッジの種類
enum BadgeType: String, CaseIterable {
    case firstPost = "first_post"
    case fivePosts = "five_posts"
    case tenPosts = "ten_posts"
    case tenLikes = "ten_likes"
    case fiftyLikes = "fifty_likes"
    case hundredLikes = "hundred_likes"
    case weeklyPost = "weekly_post"
    case monthlyPost = "monthly_post"
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    case developer = "developer"
    case verified = "verified"
    case admin = "admin"
    
    // SNSフォロワーバッジ
    case tiktok1k = "tiktok_1k"
    case tiktok5k = "tiktok_5k"
    case tiktok10k = "tiktok_10k"
    case x1k = "x_1k"
    case x5k = "x_5k"
    case x10k = "x_10k"
    
    var title: String {
        switch self {
        case .firstPost: return "初投稿"
        case .fivePosts: return "5投稿達成"
        case .tenPosts: return "10投稿達成"
        case .tenLikes: return "10いいね達成"
        case .fiftyLikes: return "50いいね達成"
        case .hundredLikes: return "100いいね達成"
        case .weeklyPost: return "週間投稿者"
        case .monthlyPost: return "月間投稿者"
        case .earlyBird: return "早起き投稿者"
        case .nightOwl: return "夜更かし投稿者"
        case .developer: return "開発者"
        case .verified: return "認証済み"
        case .admin: return "運営者"
        
        // SNSフォロワーバッジ
        case .tiktok1k: return "TikTok 1K"
        case .tiktok5k: return "TikTok 5K"
        case .tiktok10k: return "TikTok 10K"
        case .x1k: return "X 1K"
        case .x5k: return "X 5K"
        case .x10k: return "X 10K"
        }
    }
    
    var icon: String {
        switch self {
        case .firstPost: return "star.fill"
        case .fivePosts: return "doc.text.fill"
        case .tenPosts: return "doc.badge.plus"
        case .tenLikes: return "heart.fill"
        case .fiftyLikes: return "flame.fill"
        case .hundredLikes: return "crown.fill"
        case .weeklyPost: return "calendar.badge.plus"
        case .monthlyPost: return "calendar.circle.fill"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .developer: return "hammer.fill"
        case .verified: return "checkmark.seal.fill"
        case .admin: return "checkmark.seal.fill"
        
        // SNSフォロワーバッジ
        case .tiktok1k, .tiktok5k, .tiktok10k: return "t.circle.fill"
        case .x1k, .x5k, .x10k: return "x.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .firstPost: return .yellow
        case .fivePosts: return .green
        case .tenPosts: return .teal
        case .tenLikes: return .pink
        case .fiftyLikes: return .orange
        case .hundredLikes: return .purple
        case .weeklyPost: return .green
        case .monthlyPost: return .blue
        case .earlyBird: return .orange
        case .nightOwl: return .indigo
        case .developer: return .purple
        case .verified: return .blue
        case .admin: return .red
        
        // SNSフォロワーバッジ（ランク色分け）
        case .tiktok1k, .x1k: return Color.gray // 1K: グレー（基本ランク）
        case .tiktok5k, .x5k: return Color.blue // 5K: 青（中級ランク）
        case .tiktok10k, .x10k: return Color.red // 10K: 赤（最高ランク）
        }
    }
    
    var description: String {
        switch self {
        case .firstPost: return "初めての名言を投稿"
        case .fivePosts: return "5つの名言を投稿"
        case .tenPosts: return "10つの名言を投稿"
        case .tenLikes: return "投稿が合計10いいねを獲得"
        case .fiftyLikes: return "投稿が合計50いいねを獲得"
        case .hundredLikes: return "投稿が合計100いいねを獲得"
        case .weeklyPost: return "7日連続で投稿"
        case .monthlyPost: return "30日連続で投稿"
        case .earlyBird: return "朝5時〜7時に投稿"
        case .nightOwl: return "深夜0時〜2時に投稿"
        case .developer: return "アプリ開発者"
        case .verified: return "公式認証アカウント"
        case .admin: return "アプリ運営者"
        
        // SNSフォロワーバッジ
        case .tiktok1k: return "TikTokフォロワー1,000人"
        case .tiktok5k: return "TikTokフォロワー5,000人"
        case .tiktok10k: return "TikTokフォロワー10,000人"
        case .x1k: return "Xフォロワー1,000人"
        case .x5k: return "Xフォロワー5,000人"
        case .x10k: return "Xフォロワー10,000人"
        }
    }
}

// バッジ管理クラス
class BadgeManager: ObservableObject {
    @Published var userBadges: [BadgeType] = []
    private let db = Firestore.firestore()
    
    // ユーザーのバッジを取得
    func fetchUserBadges(userId: String) {
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                if let badgeStrings = data?["badges"] as? [String] {
                    self.userBadges = badgeStrings.compactMap { BadgeType(rawValue: $0) }
                }
            }
        }
    }
    
    // バッジを付与
    func awardBadge(_ badge: BadgeType, to userId: String) {
        // 既にバッジを持っているかチェック
        db.collection("userProfiles").document(userId).getDocument { [weak self] document, error in
            if let document = document, document.exists {
                let data = document.data()
                let allBadges = data?["allBadges"] as? [String] ?? []
                
                // 既にバッジを持っている場合は付与しない
                if allBadges.contains(badge.rawValue) {
                    print("バッジ \(badge.title) は既に付与済みです")
                    return
                }
                
                // バッジを付与
                self?.db.collection("userProfiles").document(userId).updateData([
                    "allBadges": FieldValue.arrayUnion([badge.rawValue])
                ]) { error in
                    if let error = error {
                        print("バッジ付与エラー: \(error)")
                    } else {
                        print("✅ バッジ \(badge.title) を付与しました")
                        
                        // BadgeUpdated通知を送信してUIを更新
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name("BadgeUpdated"), object: nil)
                        }
                        
                        // プッシュ通知を送信
                        self?.sendBadgeNotification(badge: badge, userId: userId)
                    }
                }
            }
        }
    }
    
    // 投稿数に基づくバッジチェック
    func checkPostBadges(userId: String, postCount: Int) {
        if postCount >= 1 {
            awardBadge(.firstPost, to: userId)
        }
        if postCount >= 5 {
            awardBadge(.fivePosts, to: userId)
        }
        if postCount >= 10 {
            awardBadge(.tenPosts, to: userId)
        }
    }
    
    // いいね数に基づくバッジチェック
    func checkLikeBadges(userId: String, totalLikes: Int) {
        if totalLikes >= 10 {
            awardBadge(.tenLikes, to: userId)
        }
        if totalLikes >= 50 {
            awardBadge(.fiftyLikes, to: userId)
        }
        if totalLikes >= 100 {
            awardBadge(.hundredLikes, to: userId)
        }
    }
    
    // バッジ獲得条件をチェック
    func checkBadgeConditions(for userId: String) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        // 投稿数をチェック
        db.collection("quotes")
            .whereField("authorUid", isEqualTo: userId)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                // 初投稿バッジ
                if documents.count == 1 {
                    self.awardBadge(.firstPost, to: userId)
                }
                
                // いいね数の合計をチェック
                let totalLikes = documents.reduce(0) { sum, doc in
                    sum + (doc.data()["likes"] as? Int ?? 0)
                }
                
                if totalLikes >= 10 && !self.userBadges.contains(.tenLikes) {
                    self.awardBadge(.tenLikes, to: userId)
                }
                if totalLikes >= 50 && !self.userBadges.contains(.fiftyLikes) {
                    self.awardBadge(.fiftyLikes, to: userId)
                }
                if totalLikes >= 100 && !self.userBadges.contains(.hundredLikes) {
                    self.awardBadge(.hundredLikes, to: userId)
                }
                
                // 時間帯バッジ
                let now = Date()
                let hour = Calendar.current.component(.hour, from: now)
                
                if hour >= 5 && hour <= 7 && !self.userBadges.contains(.earlyBird) {
                    self.awardBadge(.earlyBird, to: userId)
                }
                if (hour >= 0 && hour <= 2) && !self.userBadges.contains(.nightOwl) {
                    self.awardBadge(.nightOwl, to: userId)
                }
            }
    }
    
    private func sendBadgeNotification(badge: BadgeType, userId: String) {
        let content = UNMutableNotificationContent()
        content.title = "バッジを獲得しました！"
        content.body = "\(badge.icon) \(badge.title) - \(badge.description)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// バッジ表示ビュー
struct BadgeView: View {
    let badge: BadgeType
    let size: CGFloat
    let style: BadgeStyle
    
    enum BadgeStyle {
        case icon          // アイコンのみ
        case iconWithGlow  // アイコン + グロー効果
        case pill          // ピル型（アイコン + テキスト）
        case premium       // プレミアム（グラデーション + 影）
    }
    
    init(badge: BadgeType, size: CGFloat = 24, style: BadgeStyle = .iconWithGlow) {
        self.badge = badge
        self.size = size
        self.style = style
    }
    
    var body: some View {
        Group {
            switch style {
            case .icon:
                iconOnlyView
            case .iconWithGlow:
                iconWithGlowView
            case .pill:
                pillView
            case .premium:
                premiumView
            }
        }
    }
    
    private var iconOnlyView: some View {
        Image(systemName: badge.icon)
            .font(.system(size: size, weight: .semibold))
            .foregroundColor(badge.color)
    }
    
    private var iconWithGlowView: some View {
        ZStack {
            // グロー効果
            Image(systemName: badge.icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(badge.color)
                .shadow(color: badge.color.opacity(0.6), radius: 4, x: 0, y: 0)
            
            // メインアイコン
            Image(systemName: badge.icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(badge.color)
        }
    }
    
    private var pillView: some View {
        HStack(spacing: 4) {
            Image(systemName: badge.icon)
                .font(.system(size: size * 0.7, weight: .semibold))
            
            Text(badge.title)
                .font(.system(size: size * 0.5, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, size * 0.5)
        .padding(.vertical, size * 0.25)
        .background(
            Capsule()
                .fill(badge.color)
        )
    }
    
    private var premiumView: some View {
        ZStack {
            // SNSバッジは特別豪華に、それ以外は通常のプレミアム
            if isSNSBadge {
                // SNS専用の豪華デザイン
                premiumSNSDesign
            } else {
                // 通常のプレミアムデザイン
                normalPremiumDesign
            }
        }
    }
    
    private var isSNSBadge: Bool {
        switch badge {
        case .tiktok1k, .tiktok5k, .tiktok10k, .x1k, .x5k, .x10k:
            return true
        default:
            return false
        }
    }
    
    private var premiumSNSDesign: some View {
        ZStack {
            let followerNumber = getFollowerNumber()
            let luxuryLevel = getLuxuryLevel()
            
            // 背景サークル（ランクに応じたデザイン）
            if luxuryLevel == 1.0 {
                // 1K: グレー（基本ランク） - シンプル
                Circle()
                    .fill(badge.color)
                    .frame(width: size * 1.5, height: size * 1.5)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            } else if luxuryLevel == 2.0 {
                // 5K: 青（中級ランク） - メタリックブルー
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.7), Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size * 1.5, height: size * 1.5)
                        .shadow(color: .blue.opacity(0.5), radius: 4, x: 0, y: 2)
                    
                    // シルバーリング
                    Circle()
                        .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
                        .frame(width: size * 1.6, height: size * 1.6)
                }
            } else {
                // 10K: 赤（最高ランク） - ゴールド＆レッド
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow.opacity(0.8), Color.red, Color.red.opacity(0.9)],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: size * 0.8
                            )
                        )
                        .frame(width: size * 1.5, height: size * 1.5)
                        .shadow(color: .red.opacity(0.6), radius: 6, x: 0, y: 3)
                    
                    // ゴールドリング
                    Circle()
                        .stroke(Color.yellow.opacity(0.9), lineWidth: 2)
                        .frame(width: size * 1.6, height: size * 1.6)
                    
                    // 内側の装飾
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        .frame(width: size * 1.3, height: size * 1.3)
                }
            }
            
            // 中央に数字を表示
            VStack(spacing: 0) {
                Text(followerNumber)
                    .font(.system(size: size * 0.35, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                
                // SNSアイコンを小さく下に表示
                Image(systemName: getSNSIcon())
                    .font(.system(size: size * 0.25, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
        }
    }
    
    private func getFollowerNumber() -> String {
        switch badge {
        case .tiktok1k, .x1k: return "1K"
        case .tiktok5k, .x5k: return "5K"  
        case .tiktok10k, .x10k: return "10K"
        default: return ""
        }
    }
    
    private func getSNSIcon() -> String {
        switch badge {
        case .tiktok1k, .tiktok5k, .tiktok10k: return "t.circle"
        case .x1k, .x5k, .x10k: return "x.circle"
        default: return badge.icon
        }
    }
    
    private var normalPremiumDesign: some View {
        ZStack {
            // 背景グラデーション
            Circle()
                .fill(
                    LinearGradient(
                        colors: [badge.color.opacity(0.8), badge.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .shadow(color: badge.color.opacity(0.4), radius: 6, x: 0, y: 3)
            
            // 内側の円
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: size * 1.2, height: size * 1.2)
            
            // アイコン
            Image(systemName: badge.icon)
                .font(.system(size: size, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
        }
    }
    
    private func getLuxuryLevel() -> CGFloat {
        switch badge {
        case .tiktok1k, .x1k:
            return 1.0 // 基本レベル
        case .tiktok5k, .x5k:
            return 2.0 // 中級レベル
        case .tiktok10k, .x10k:
            return 3.0 // 最高級レベル
        default:
            return 1.0
        }
    }
}

// バッジリストビュー
struct BadgeListView: View {
    let badges: [BadgeType]
    let maxDisplay: Int
    
    init(badges: [BadgeType], maxDisplay: Int = 3) {
        self.badges = badges
        self.maxDisplay = maxDisplay
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(badges.prefix(maxDisplay), id: \.self) { badge in
                BadgeView(badge: badge, size: 16)
            }
            
            if badges.count > maxDisplay {
                Text("+\(badges.count - maxDisplay)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// バッジ詳細画面
struct BadgeDetailView: View {
    let userId: String
    @StateObject private var badgeManager = BadgeManager()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(BadgeType.allCases, id: \.self) { badge in
                    HStack {
                        BadgeView(badge: badge, size: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(badge.title)
                                .font(.headline)
                            
                            Text(badge.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if badgeManager.userBadges.contains(badge) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        } else {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                                .font(.title2)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(badgeManager.userBadges.contains(badge) ? 
                                  badge.color.opacity(0.1) : Color.gray.opacity(0.1))
                    )
                }
            }
            .padding()
        }
        .navigationTitle("バッジコレクション")
        .onAppear {
            badgeManager.fetchUserBadges(userId: userId)
        }
    }
}