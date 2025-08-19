//
//  ProductionConfig.swift
//  名言sns
//
//  リリース前の重要な設定値
//

import Foundation

struct ProductionConfig {
    // リリース用の設定値
    
    // データ取得制限（コスト削減）
    static let maxQuotesPerLoad = 10      // 一度に取得する投稿数
    static let maxRepliesPerQuote = 20    // 1つの投稿につき最大リプライ数
    static let maxProfileQuotes = 10      // プロフィールページの投稿表示数
    
    // 画像制限（パフォーマンス・コスト削減）
    static let maxImageSizeKB = 30        // 最大画像サイズ（KB）
    static let imageCompressionQuality: Float = 0.05  // 画像圧縮品質（5%）
    
    // セキュリティ設定
    static let enableAnonymousPosting = true    // 匿名投稿を許可するか
    static let maxAnonymousPostsPerDay = 5      // 匿名ユーザーの1日投稿制限
    
    // リアルタイム機能（コスト重要）
    static let useRealtimeUpdates = false       // リアルタイム更新を無効化（コスト削減）
    
    // デバッグ設定
    static let isProductionBuild: Bool = {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }()
    
    // リリース前チェック（本番環境では実行されない）
    static func validateProductionReadiness() {
        #if DEBUG
        print("PRODUCTION READINESS CHECK:")
        print("  - Realtime updates: \(useRealtimeUpdates ? "ENABLED" : "DISABLED")")
        print("  - Max quotes per load: \(maxQuotesPerLoad)")
        print("  - Max image size: \(maxImageSizeKB)KB")
        print("  - Image compression: \(Int(imageCompressionQuality * 100))%")
        #endif
    }
}