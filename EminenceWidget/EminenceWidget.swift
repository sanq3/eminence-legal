//
//  EminenceWidget.swift
//  EminenceWidget
//
//  Created by san san on 2025/08/18.
//

import WidgetKit
import SwiftUI

struct QuoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> ()) {
        let entry = QuoteEntry(date: Date(), quote: .placeholder)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // 複数の異なるランダム名言を取得
        QuoteWidgetService.shared.getMultipleRandomBookmarkedQuotes(count: 5) { quotes in
            let currentDate = Date()
            var entries: [QuoteEntry] = []
            
            // 現在のエントリー
            entries.append(QuoteEntry(date: currentDate, quote: quotes[0]))
            
            // 15分、30分、1時間、2時間後にそれぞれ異なる名言を表示
            let updateIntervals = [15, 30, 60, 120] // 分単位
            
            for (index, interval) in updateIntervals.enumerated() {
                if let nextUpdate = Calendar.current.date(byAdding: .minute, value: interval, to: currentDate),
                   index + 1 < quotes.count {
                    let nextEntry = QuoteEntry(date: nextUpdate, quote: quotes[index + 1])
                    entries.append(nextEntry)
                }
            }
            
            // より頻繁な更新を要求（システムが判断して実際の頻度を決定）
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: WidgetQuote
}

struct EminenceWidgetEntryView: View {
    var entry: QuoteProvider.Entry
    
    var body: some View {
        ZStack {
            // 背景
            Color.clear
            
            VStack {
                Spacer()
                
                // 名言本文（中央配置）
                Text(entry.quote.text)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .lineLimit(6)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                
                Spacer()
            }
            
            // 作者名（右下配置）
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(entry.quote.author)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EminenceWidget: Widget {
    let kind: String = "EminenceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            if #available(iOS 17.0, *) {
                EminenceWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                EminenceWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("ブックマーク名言")
        .description("あなたがブックマークした名言をランダムに表示します")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    EminenceWidget()
} timeline: {
    QuoteEntry(date: .now, quote: .placeholder)
    QuoteEntry(date: .now, quote: WidgetQuote(
        id: "test",
        text: "成功への第一歩は、まず始めることだ。",
        author: "マーク・トウェイン",
        likes: 128,
        createdAt: Date()
    ))
}
