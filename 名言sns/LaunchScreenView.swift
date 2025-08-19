//
//  LaunchScreenView.swift
//  名言sns
//
//  Created by Claude on 2025/08/18.
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // 背景色
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // アプリアイコン（オプション）
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.pink)
                
                // アプリ名
                Text("エミネンス")
                    .font(.system(size: 34, weight: .medium, design: .default))
                    .foregroundColor(.primary)
                
                // サブタイトル
                Text("心に響く名言をあなたに")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenView()
    }
}