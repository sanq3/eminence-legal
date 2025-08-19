//
//  EminenceWidgetBundle.swift
//  EminenceWidget
//
//  Created by san san on 2025/08/18.
//

import WidgetKit
import SwiftUI
import FirebaseCore

@main
struct EminenceWidgetBundle: WidgetBundle {
    
    init() {
        // Firebase設定を初期化
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    var body: some Widget {
        EminenceWidget()
    }
}
