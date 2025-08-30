import SwiftUI
import FirebaseAuth

struct AllBadgesView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    // すべてのバッジ（取得済み・未取得含む）
    let allAvailableBadges: [(badge: BadgeType, unlocked: Bool, condition: String)] = [
        (.firstPost, false, "初めて名言を投稿する"),
        (.fivePosts, false, "5つの名言を投稿する"),
        (.tenPosts, false, "10個の名言を投稿する"),
        (.thirtyPosts, false, "30個の名言を投稿する"),
        (.fiftyPosts, false, "50個の名言を投稿する"),
        (.hundredPosts, false, "100個の名言を投稿する"),
        (.likeCollector, false, "合計10いいねを獲得する"),
        (.popular, false, "合計50いいねを獲得する"),
        (.superPopular, false, "合計100いいねを獲得する"),
        (.viral, false, "合計500いいねを獲得する"),
        (.legendary, false, "合計1000いいねを獲得する"),
        (.weeklyPoster, false, "7日間連続で投稿する"),
        (.monthlyPoster, false, "30日間連続で投稿する"),
        (.earlyBird, false, "朝5時〜7時に投稿する"),
        (.nightOwl, false, "深夜2時〜4時に投稿する"),
        (.tiktok1k, false, "TikTok 1,000フォロワー達成"),
        (.tiktok5k, false, "TikTok 5,000フォロワー達成"),
        (.tiktok10k, false, "TikTok 10,000フォロワー達成"),
        (.x1k, false, "X(Twitter) 1,000フォロワー達成"),
        (.x5k, false, "X(Twitter) 5,000フォロワー達成"),
        (.x10k, false, "X(Twitter) 10,000フォロワー達成"),
        (.verified, false, "公式認証を受ける（運営付与）"),
        (.developer, false, "アプリ開発に貢献（運営付与）"),
        (.admin, false, "運営チーム（運営付与）")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 取得済みバッジセクション
                    if let userBadges = profileViewModel.userProfile?.allBadges, !userBadges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("取得済みバッジ")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(userBadges, id: \.self) { badgeRawValue in
                                    if let badgeType = BadgeType(rawValue: badgeRawValue) {
                                        VStack(spacing: 4) {
                                            Image(systemName: badgeType.iconName)
                                                .font(.system(size: 28))
                                                .foregroundColor(badgeType.color)
                                            
                                            Text(badgeType.displayName)
                                                .font(.system(size: 10))
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .foregroundColor(.primary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 未取得バッジセクション
                    VStack(alignment: .leading, spacing: 12) {
                        Text("未取得バッジ")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(allAvailableBadges, id: \.badge.rawValue) { item in
                                let isUnlocked = profileViewModel.userProfile?.allBadges.contains(item.badge.rawValue) ?? false
                                
                                if !isUnlocked {
                                    VStack(spacing: 4) {
                                        ZStack {
                                            // 未取得バッジは薄く表示
                                            Image(systemName: item.badge.iconName)
                                                .font(.system(size: 28))
                                                .foregroundColor(item.badge.color.opacity(0.3))
                                            
                                            // ロックアイコンを重ねる
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                                .background(Circle().fill(Color.white).frame(width: 16, height: 16))
                                                .offset(x: 12, y: 12)
                                        }
                                        
                                        Text(item.badge.displayName)
                                            .font(.system(size: 10))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .foregroundColor(.secondary)
                                        
                                        Text(item.condition)
                                            .font(.system(size: 8))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.top)
            }
            .navigationTitle("バッジコレクション")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AllBadgesView(profileViewModel: ProfileViewModel())
}