//
//  WidgetQuote.swift
//  EminenceWidget
//
//  Created by Claude on 2025/08/18.
//

import Foundation

// ウィジェット用のシンプルなQuoteデータ構造
struct WidgetQuote: Codable {
    let id: String
    let text: String
    let author: String
    let likes: Int
    let createdAt: Date
    
    // 基本的な初期化
    init(id: String, text: String, author: String, likes: Int, createdAt: Date) {
        self.id = id
        self.text = text
        self.author = author
        self.likes = likes
        self.createdAt = createdAt
    }
    
    // デフォルト値（プレースホルダー用）
    static var placeholder: WidgetQuote {
        WidgetQuote(
            id: "placeholder",
            text: "今日という日は、残りの人生の最初の日である。",
            author: "アビー・ホフマン",
            likes: 42,
            createdAt: Date()
        )
    }
    
    // エラー時の表示用
    static var error: WidgetQuote {
        WidgetQuote(
            id: "error",
            text: "名言を読み込み中です...",
            author: "エミネンス",
            likes: 0,
            createdAt: Date()
        )
    }
    
    // ブックマークがない場合の表示用
    static var noBookmarks: WidgetQuote {
        WidgetQuote(
            id: "no_bookmarks",
            text: "まだブックマークがありません。アプリで素敵な名言をブックマークしてみましょう！",
            author: "エミネンス",
            likes: 0,
            createdAt: Date()
        )
    }
}