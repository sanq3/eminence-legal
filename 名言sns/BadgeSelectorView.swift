import SwiftUI

struct BadgeSelectorView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedBadges: Set<String> = []
    
    var body: some View {
        NavigationView {
            VStack {
                // 説明
                VStack(alignment: .leading, spacing: 8) {
                    Text("表示するバッジを選択")
                        .font(.headline)
                    Text("最大4つまで選択できます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // 獲得済みバッジ一覧
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(profileViewModel.userProfile?.allBadges ?? [], id: \.self) { badgeRawValue in
                            if let badgeType = BadgeType(rawValue: badgeRawValue) {
                                BadgeCard(
                                    badgeType: badgeType,
                                    isSelected: selectedBadges.contains(badgeRawValue)
                                ) {
                                    toggleBadgeSelection(badgeRawValue)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                if (profileViewModel.userProfile?.allBadges.isEmpty ?? true) {
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("まだバッジがありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("名言を投稿したり、いいねを獲得してバッジを集めましょう！")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
            }
            .navigationTitle("バッジ選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        profileViewModel.updateSelectedBadges(Array(selectedBadges))
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            selectedBadges = Set(profileViewModel.userProfile?.selectedBadges ?? [])
        }
    }
    
    private func toggleBadgeSelection(_ badgeId: String) {
        if selectedBadges.contains(badgeId) {
            selectedBadges.remove(badgeId)
        } else if selectedBadges.count < 4 {
            selectedBadges.insert(badgeId)
        }
    }
}

struct BadgeCard: View {
    let badgeType: BadgeType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                BadgeView(badge: badgeType, size: 24, style: isSelected ? .premium : .iconWithGlow)
                
                VStack(spacing: 2) {
                    Text(badgeType.title)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text(badgeType.description)
                        .font(.system(size: 8))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 90)
            .background(isSelected ? badgeType.color : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? badgeType.color : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

#Preview {
    BadgeSelectorView(profileViewModel: ProfileViewModel())
}