import Foundation

// 不適切なコンテンツをフィルタリングするサービス
class ContentModerationService {
    static let shared = ContentModerationService()
    
    // NGワードリスト（基本的な不適切ワード）
    private let inappropriateWords: Set<String> = [
        // 暴力的な表現
        "殺", "死ね", "ぶっ殺", "自殺",
        // 差別的な表現
        "ブス", "デブ", "ハゲ", "キモい",
        // 性的な表現
        "セックス", "エロ", "風俗",
        // その他の不適切な表現
        "バカ", "アホ", "クソ", "うざい", "きもい",
        // スパム的な表現
        "儲かる", "稼げる", "副業", "投資", "ビットコイン",
        "LINE@", "詳細はプロフ", "DMください"
    ]
    
    // URLパターンの検出
    private let urlPattern = #"https?://[^\s]+"#
    
    // 電話番号パターンの検出
    private let phonePattern = #"(\d{2,4}-?\d{2,4}-?\d{3,4})|(\d{10,11})"#
    
    // メールアドレスパターンの検出
    private let emailPattern = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
    
    private init() {}
    
    // コンテンツが適切かチェック
    func isContentAppropriate(_ text: String) -> (isAppropriate: Bool, reason: String?) {
        let lowercasedText = text.lowercased()
        
        // NGワードチェック
        for word in inappropriateWords {
            if lowercasedText.contains(word.lowercased()) {
                return (false, "不適切な表現が含まれています")
            }
        }
        
        // 連続した同じ文字のチェック（スパム対策）
        if containsRepeatedCharacters(text, maxRepeat: 10) {
            return (false, "スパムの可能性があります")
        }
        
        // URL含有チェック（初期フェーズでは外部リンク禁止）
        if text.range(of: urlPattern, options: .regularExpression) != nil {
            return (false, "URLの投稿は現在許可されていません")
        }
        
        // 電話番号含有チェック
        if text.range(of: phonePattern, options: .regularExpression) != nil {
            return (false, "個人情報（電話番号）が含まれています")
        }
        
        // メールアドレス含有チェック
        if text.range(of: emailPattern, options: .regularExpression) != nil {
            return (false, "個人情報（メールアドレス）が含まれています")
        }
        
        // 過度に短い/長いコンテンツのチェック
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.count < 2 {
            return (false, "投稿内容が短すぎます")
        }
        if trimmedText.count > 500 {
            return (false, "投稿内容が長すぎます（500文字以内）")
        }
        
        return (true, nil)
    }
    
    // 連続した同じ文字のチェック
    private func containsRepeatedCharacters(_ text: String, maxRepeat: Int) -> Bool {
        var previousChar: Character?
        var repeatCount = 1
        
        for char in text {
            if char == previousChar {
                repeatCount += 1
                if repeatCount > maxRepeat {
                    return true
                }
            } else {
                repeatCount = 1
                previousChar = char
            }
        }
        
        return false
    }
    
    // サーバーサイドでの追加チェック用（将来的にFirebase Functionsで実装）
    func shouldFlagForManualReview(_ text: String) -> Bool {
        // 疑わしいパターンのチェック
        let suspiciousPatterns = [
            "金", "お金", "現金", "振込", "口座",
            "出会", "会いましょう", "連絡先",
            "薬", "ドラッグ"
        ]
        
        let lowercasedText = text.lowercased()
        for pattern in suspiciousPatterns {
            if lowercasedText.contains(pattern) {
                return true
            }
        }
        
        return false
    }
}