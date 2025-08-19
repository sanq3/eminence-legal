//
//  __snsApp.swift
//  名言sns
//
//  Created by san san on 2025/08/08.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications

// Firebaseを初期化するためのAppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    
    // プッシュ通知の設定
    UNUserNotificationCenter.current().delegate = self
    
    // 通知許可をリクエスト
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      print("Permission granted: \(granted)")
      if let error = error {
        print("Notification authorization error: \(error)")
      }
      
      if granted {
        DispatchQueue.main.async {
          application.registerForRemoteNotifications()
        }
      }
    }
    
    // Firebase Messaging delegate設定
    Messaging.messaging().delegate = self
    
    // ユーザー認証状態の監視を開始（ウィジェット用）
    setupAuthenticationStateListener()
    
    // 🚨 PRODUCTION READINESS CHECK
    // ProductionConfig.validateProductionReadiness() // TODO: Fix import issue
    
    // Firebase設定確認
    if let app = FirebaseApp.app() {
      print("Firebase configured successfully")
      print("Project ID: \(app.options.projectID ?? "Not found")")
      print("App ID: \(app.options.googleAppID)")
    } else {
      print("Firebase configuration failed")
    }
    
    // 匿名ログインを自動付与（ユーザー操作なしで端末を識別）
    if Auth.auth().currentUser == nil {
      Auth.auth().signInAnonymously { authResult, error in
        if let error = error {
          print("Firebase Auth: Anonymous authentication failed with error: \(error)")
          print("Error code: \((error as NSError).code)")
          
          // 認証失敗時の再試行
          DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if Auth.auth().currentUser == nil {
              print("Firebase Auth: Retrying anonymous sign-in...")
              Auth.auth().signInAnonymously(completion: nil)
            }
          }
        } else {
          print("Firebase Auth: Anonymous sign-in succeeded: \(authResult?.user.uid ?? "No UID")")
          
          // 匿名認証成功後、FCMトークンがあれば保存
          Messaging.messaging().token { token, error in
            if let error = error {
              print("Error fetching FCM token: \(error)")
            } else if let token = token {
              print("FCM Token retrieved after anonymous auth: \(token)")
              if let userId = authResult?.user.uid {
                self.saveFCMToken(token: token, userId: userId)
              }
            }
          }
        }
      }
    }
    
    return true
  }
  
  // デバイストークンの登録
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
  
  // デバイストークン登録失敗
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Remote notification registration failed: \(error.localizedDescription)")
  }
  
  // FCMトークンをFirestoreに保存するヘルパーメソッド
  func saveFCMToken(token: String, userId: String) {
    let db = Firestore.firestore()
    db.collection("users").document(userId).setData([
      "fcmToken": token,
      "notificationsEnabled": true,
      "updatedAt": FieldValue.serverTimestamp()
    ], merge: true) { error in
      if let error = error {
        print("Error saving FCM token: \(error)")
      } else {
        print("FCM token saved successfully for user: \(userId)")
      }
    }
  }
  
  // ユーザー認証状態監視（ウィジェット用）
  func setupAuthenticationStateListener() {
    Auth.auth().addStateDidChangeListener { _, user in
      if let user = user {
        // ユーザーIDをUserDefaultsに保存（ウィジェットからアクセス可能）
        UserDefaults.standard.set(user.uid, forKey: "currentUserId")
        print("App: Saved user ID for widget: \(user.uid)")
        
        // App Groupがあれば、そちらにも保存
        if let groupDefaults = UserDefaults(suiteName: "group.com.meigensns.app") {
          groupDefaults.set(user.uid, forKey: "currentUserId")
          print("App: Saved user ID to App Group for widget: \(user.uid)")
        }
      } else {
        // ログアウト時はUserDefaultsから削除
        UserDefaults.standard.removeObject(forKey: "currentUserId")
        UserDefaults(suiteName: "group.com.meigensns.app")?.removeObject(forKey: "currentUserId")
        print("App: Cleared user ID (logged out)")
      }
    }
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
  // フォアグラウンド時の通知処理
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.banner, .sound])
  }
  
  // 通知タップ時の処理
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    print("Notification tapped: \(response.notification.request.content.userInfo)")
    completionHandler()
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  // FCMトークン更新時の処理
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    #if DEBUG
    print("FCM Token: \(fcmToken ?? "No token")")
    #endif
    
    guard let token = fcmToken else { return }
    
    // 全ユーザー（匿名含む）のFCMトークンをFirestoreに保存
    if let user = Auth.auth().currentUser {
      updateFCMToken(token: token, userId: user.uid)
    } else {
      // ユーザーがまだ認証されていない場合は、認証後に再度トークンを保存
      print("User not authenticated yet, will save token after authentication")
    }
  }
  
  private func updateFCMToken(token: String, userId: String) {
    // FirestoreにFCMトークンを直接保存
    let db = Firestore.firestore()
    db.collection("users").document(userId).setData([
      "fcmToken": token,
      "notificationsEnabled": true,
      "updatedAt": FieldValue.serverTimestamp()
    ], merge: true) { error in
      if let error = error {
        print("Error updating FCM token: \(error)")
      } else {
        print("FCM token updated successfully")
      }
    }
  }
}

@main
struct __snsApp: App {
    // Firebaseの初期化処理を呼び出す
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .onChange(of: isDarkMode) { newValue in
                    // アプリ全体のダークモード設定を即座に更新
                    DispatchQueue.main.async {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            windowScene.windows.first?.overrideUserInterfaceStyle = newValue ? .dark : .light
                        }
                    }
                }
        }
    }
}
