//
//  QuoteWidgetService.swift
//  EminenceWidget
//
//  Created by Claude on 2025/08/18.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

class QuoteWidgetService {
    static let shared = QuoteWidgetService()
    private var db: Firestore?
    
    private init() {
        print("Widget: Initializing QuoteWidgetService...")
        
        // Firebase設定を初期化（まだ初期化されていない場合）
        if FirebaseApp.app() == nil {
            print("Widget: Firebase not configured, attempting to configure...")
            
            // GoogleService-Info.plistの存在確認
            if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
                print("Widget: Found GoogleService-Info.plist at: \(path)")
                FirebaseApp.configure()
                print("Widget: Firebase configured successfully")
            } else {
                print("Widget: ERROR - GoogleService-Info.plist not found!")
            }
        } else {
            print("Widget: Firebase already configured")
        }
        
        if let app = FirebaseApp.app() {
            print("Widget: Firebase app exists, creating Firestore instance")
            db = Firestore.firestore()
            print("Widget: Firestore instance created successfully")
        } else {
            print("Widget: ERROR - Firebase app is nil, cannot create Firestore")
            db = nil
        }
    }
    
    // ユーザーのブックマークした名言をランダムに1つ取得
    func getRandomBookmarkedQuote(completion: @escaping (WidgetQuote) -> Void) {
        guard let db = db else {
            completion(.error)
            return
        }
        
        // App GroupまたはUserDefaultsからユーザーIDを取得
        guard let userId = getCurrentUserId() else {
            print("Widget: No user ID found")
            completion(.noBookmarks)
            return
        }
        
        print("Widget: Using user ID: \(userId)")
        
        // ユーザーがブックマークした名言を取得
        db.collection("quotes")
            .whereField("bookmarkedBy", arrayContains: userId)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("Widget: Error fetching bookmarked quotes: \(error)")
                    completion(.error)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    // ブックマークがない場合
                    print("Widget: No bookmarked quotes found for user: \(userId)")
                    completion(.noBookmarks)
                    return
                }
                
                print("Widget: Found \(documents.count) bookmarked quotes")
                
                // ランダムに1つ選択
                let randomDocument = documents.randomElement()!
                let data = randomDocument.data()
                
                let widgetQuote = WidgetQuote(
                    id: randomDocument.documentID,
                    text: data["text"] as? String ?? "",
                    author: data["author"] as? String ?? "匿名",
                    likes: data["likes"] as? Int ?? 0,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                )
                
                completion(widgetQuote)
            }
    }
    
    // 複数のランダムブックマーク名言を取得
    func getMultipleRandomBookmarkedQuotes(count: Int, completion: @escaping ([WidgetQuote]) -> Void) {
        guard let db = db else {
            // エラー時は同じ名言を複数返す
            completion(Array(repeating: .error, count: count))
            return
        }
        
        guard let userId = getCurrentUserId() else {
            print("Widget: No user ID found for multiple quotes")
            completion(Array(repeating: .noBookmarks, count: count))
            return
        }
        
        print("Widget: Fetching \(count) random quotes for user: \(userId)")
        
        // ユーザーがブックマークした名言を取得
        db.collection("quotes")
            .whereField("bookmarkedBy", arrayContains: userId)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("Widget: Error fetching multiple bookmarked quotes: \(error)")
                    completion(Array(repeating: .error, count: count))
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("Widget: No bookmarked quotes found for multiple fetch")
                    completion(Array(repeating: .noBookmarks, count: count))
                    return
                }
                
                print("Widget: Found \(documents.count) bookmarked quotes for multiple selection")
                
                // ランダムに複数選択（重複あり）
                var selectedQuotes: [WidgetQuote] = []
                for _ in 0..<count {
                    let randomDocument = documents.randomElement()!
                    let data = randomDocument.data()
                    
                    let widgetQuote = WidgetQuote(
                        id: randomDocument.documentID,
                        text: data["text"] as? String ?? "",
                        author: data["author"] as? String ?? "匿名",
                        likes: data["likes"] as? Int ?? 0,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    
                    selectedQuotes.append(widgetQuote)
                }
                
                completion(selectedQuotes)
            }
    }
    
    // ユーザーIDを取得（App Group経由またはUserDefaults）
    private func getCurrentUserId() -> String? {
        print("Widget: Checking for user ID...")
        
        // まず標準のUserDefaultsから取得を試す
        let standardUserId = UserDefaults.standard.string(forKey: "currentUserId")
        print("Widget: Standard UserDefaults currentUserId: \(standardUserId ?? "nil")")
        
        if let userId = standardUserId {
            print("Widget: Found user ID in standard UserDefaults: \(userId)")
            return userId
        }
        
        // 次にApp Groupから取得を試す（設定されている場合）
        if let groupDefaults = UserDefaults(suiteName: "group.com.meigensns.app") {
            let groupUserId = groupDefaults.string(forKey: "currentUserId")
            print("Widget: App Group UserDefaults currentUserId: \(groupUserId ?? "nil")")
            
            if let userId = groupUserId {
                print("Widget: Found user ID in App Group: \(userId)")
                return userId
            }
        } else {
            print("Widget: Could not access App Group UserDefaults")
        }
        
        // UserDefaultsの全キーを確認（デバッグ用）
        print("Widget: All UserDefaults keys: \(UserDefaults.standard.dictionaryRepresentation().keys.sorted())")
        
        print("Widget: No user ID found in any UserDefaults")
        
        // 🚨 暫定措置: ログから分かった実際のユーザーIDを使用
        // TODO: App Group設定完了後に削除
        let fallbackUserId = "CeLLQFBXrYVD2YLQdAYCmwnehJJ3"
        print("Widget: Using fallback user ID for testing: \(fallbackUserId)")
        return fallbackUserId
    }
}