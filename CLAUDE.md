# エミネンス アプリ 要件定義書

## 1. プロジェクト概要

### 1.1 アプリ名

「エミネンス」

### 1.2 ビジョン

「日々の生活に気づきと感動を与える言葉を共有し、最も心に響いた名言を毎日届けるプラットフォーム」

### 1.3 コンセプト

- **1 日で最もいいねが多かった名言が通知される**
- ユーザーが自分に響いた言葉を投稿
- 他のユーザーがいいねをつける（X のような仕組み）
- その日最も人気だった名言が通知される

### 1.4 ターゲットユーザー

- 自己啓発に興味がある人
- 日々のモチベーションを求める人
- 言葉の力を信じる人
- 年齢層：10 代〜50 代
- 性別：問わない

## 2. 機能要件

### 2.1 フェーズ 1（MVP） - 現在開発中

#### 2.1.1 基本機能（未ログインでも使用可能）

| 機能           | 説明                           | 状態        |
| -------------- | ------------------------------ | ----------- |
| 名言投稿       | テキストと作者名を入力して投稿 | ✅ 実装済み |
| 名言一覧表示   | 投稿された名言を時系列で表示   | ✅ 実装済み |
| 無限スクロール | 20 件ずつ読み込み              | ✅ 実装済み |
| いいね機能     | デバイスに紐づくいいね         | ✅ 実装済み |
| ブックマーク機能 | 一時的なお気に入り保存         | ✅ 実装済み |
| リプライ機能   | 名言へのコメント               | ✅ 実装済み |
| 検索機能       | 名言・作者名で検索             | ✅ 実装済み |
| 日次トップ名言通知 | 1日1回、最も人気の名言を通知 | 🚧 部分実装 |

#### 2.1.2 ログインユーザー限定機能

| 機能                 | 説明                           | 状態      |
| -------------------- | ------------------------------ | --------- |
| プロフィール機能     | ユーザー情報の管理             | ✅ 実装済み |
| バッジ機能           | 実績バッジの獲得・表示         | ✅ 実装済み |
| 個人通知             | 自分の投稿へのいいね・リプライ通知 | ❌ 未実装 |
| 通知時間カスタマイズ | 好きな時間に通知を受け取る     | ❌ 未実装 |
| ブックマーク履歴保存 | 過去のブックマーク履歴を永続保存 | ❌ 未実装 |
| ウィジェット機能     | ブックマーク投稿のランダム表示 | ❌ 未実装 |

#### 2.1.3 認証機能

| 認証方法           | 状態        |
| ------------------ | ----------- |
| 匿名認証（自動）   | ✅ 実装済み |
| メールアドレス認証 | ❌ 未実装   |
| Apple ID 認証      | ❌ 未実装   |
| Google 認証        | ❌ 未実装   |

#### 2.1.4 バッジ機能

| バッジ種類         | 条件                 | チェックマーク | 権限 | 状態        |
| ------------------ | -------------------- | -------------- | ---- | ----------- |
| 運営者バッジ(admin) | アプリ運営者のみ     | 🔴赤           | AdminPanel権限 | ✅ 実装済み |
| 認証済みバッジ(verified) | 公式認証アカウント | 🔵青     | なし | ✅ 実装済み |
| 開発者バッジ(developer) | アプリ開発者など | なし      | なし | ✅ 実装済み |
| 毎日投稿バッジ     | 連続投稿日数に応じて | なし           | なし | ✅ 実装済み |
| いいね数達成バッジ | 10, 50, 100 いいね等 | なし           | なし | ✅ 実装済み |
| **SNSフォロワーバッジ** |                  |                |      |             |
| TikTok 1K          | 1,000フォロワー達成  | なし           | なし | ✅ 実装済み |
| TikTok 5K          | 5,000フォロワー達成  | なし           | なし | ✅ 実装済み |
| TikTok 10K         | 10,000フォロワー達成 | なし           | なし | ✅ 実装済み |
| X 1K               | 1,000フォロワー達成  | なし           | なし | ✅ 実装済み |
| X 5K               | 5,000フォロワー達成  | なし           | なし | ✅ 実装済み |
| X 10K              | 10,000フォロワー達成 | なし           | なし | ✅ 実装済み |

**⚠️ 重要なルール:**
- **運営者バッジ(admin)のみ**がAdminPanel権限を持つ
- 開発者バッジ(developer)と認証済みバッジ(verified)は表示のみで権限なし
- 運営者バッジ = 赤チェックマーク🔴 + AdminPanel権限
- 認証済みバッジ = 青チェックマーク🔵（権限なし）
- 開発者バッジ = バッジアイコンのみ（チェックマークなし、権限なし）

### 2.2 フェーズ 2（将来実装予定）

- ユーザーフォロー機能
- カテゴリー分類（恋愛、仕事、人生など）
- 名言コレクション機能
- シェア機能（SNS 連携）
- ダークモード対応
- ウィジェット機能
- AI による名言推薦

### 2.3 フェーズ 3（長期計画）

- Android 版アプリ
- Web 版
- 多言語対応
- 有料プラン（広告非表示、無制限ブックマーク等）

## 3. 非機能要件

### 3.1 パフォーマンス

- 起動時間：3 秒以内
- 画面遷移：1 秒以内
- リスト表示：スムーズなスクロール（60fps）

### 3.2 セキュリティ

- Firebase セキュリティルール適用
- 個人情報の暗号化
- 不適切コンテンツのフィルタリング

### 3.3 可用性

- オフライン時の適切なエラー表示
- ローカルキャッシュによる一部機能の継続利用

### 3.4 運用性

- Firebase 無料枠での運用
- 自動バックアップ
- アナリティクス導入

## 4. 技術スタック

### 4.1 フロントエンド

- **言語**: Swift 5
- **フレームワーク**: SwiftUI
- **最小対応 OS**: iOS 15.0
- **アーキテクチャ**: MVVM

### 4.2 バックエンド

- **BaaS**: Firebase
  - Authentication（認証）
  - Firestore（データベース）
  - Cloud Functions（サーバーレス関数）
  - Cloud Messaging（プッシュ通知）
  - Analytics（分析）

### 4.3 開発環境

- **IDE**: Xcode 15+
- **補助ツール**: Cursor AI
- **バージョン管理**: Git
- **パッケージ管理**: Swift Package Manager

## 5. SwiftUI ベストプラクティス

### 5.1 アーキテクチャパターン

- **MVVM（Model-View-ViewModel）パターンを採用**
  - View: SwiftUI ビュー（表示のみ）
  - ViewModel: ObservableObject（ビジネスロジック）
  - Model: データ構造体

### 5.2 コーディング規約

```swift
// ✅ 良い例
struct ContentView: View {
    @StateObject private var viewModel = QuoteViewModel()
    @State private var showingAddQuote = false

    var body: some View {
        NavigationView {
            // コンテンツ
        }
    }
}

// ❌ 悪い例
struct ContentView: View {
    var vm = QuoteViewModel() // @StateObjectを使っていない
    var show = false // @Stateを使っていない
}
```

### 5.3 パフォーマンス最適化

1. **@StateObject vs @ObservedObject**

   - 初期化時は`@StateObject`
   - 親から渡される場合は`@ObservedObject`

2. **LazyVStack の使用**

   - 大量のデータ表示時に使用
   - メモリ効率の向上

3. **画像の最適化**
   - AsyncImage で非同期読み込み
   - キャッシュの実装

### 5.4 Firebase 連携のベストプラクティス

1. **リアルタイムリスナーの管理**

   - 不要になったら必ず削除
   - メモリリークの防止

2. **バッチ処理の活用**

   - 複数の書き込みは`batch()`使用
   - トランザクションで整合性保証

3. **セキュリティルール**
   - 最小権限の原則
   - バリデーションルールの設定

### 5.5 エラーハンドリング

```swift
// 適切なエラーハンドリング
func fetchData() {
    isLoading = true
    errorMessage = nil

    db.collection("quotes").getDocuments { [weak self] snapshot, error in
        self?.isLoading = false

        if let error = error {
            self?.errorMessage = "エラー: \(error.localizedDescription)"
            return
        }

        // 成功時の処理
    }
}
```

## 6. 現在の進捗状況

### 6.1 完了タスク

- [x] プロジェクト初期設定
- [x] Firebase 連携
- [x] 基本的な UI 実装
- [x] 名言投稿機能
- [x] いいね・ブックマーク機能
- [x] リプライ機能
- [x] 検索機能
- [x] 無限スクロール
- [x] Cloud Functions（毎日のトップ名言集計）

### 6.2 進行中タスク

- [ ] プッシュ通知の完全実装
- [ ] 認証機能の実装

### 6.3 今後の優先タスク

1. **認証機能の実装**（メール/Apple/Google）
2. **プロフィール機能**
3. **バッジシステム**
4. **通知時間のカスタマイズ**

## 7. 課題と解決策

### 7.1 現在の課題

| 課題                   | 影響             | 解決策                               |
| ---------------------- | ---------------- | ------------------------------------ |
| Firebase 無料枠の制限  | スケーラビリティ | 効率的なクエリ設計、キャッシュ活用   |
| プッシュ通知の証明書   | 実機テスト不可   | Apple Developer Program 登録後に対応 |
| リアルタイム更新の負荷 | パフォーマンス   | ページネーション実装済み             |

### 7.2 技術的負債

- コードの重複（リファクタリング必要）
- テストコードの不足
- エラーハンドリングの統一化

## 8. データベース設計

### 8.1 Firestore コレクション構造

```
firestore/
├── quotes/
│   ├── {quoteId}/
│   │   ├── text: string
│   │   ├── author: string
│   │   ├── authorUid: string
│   │   ├── likes: number
│   │   ├── likedBy: array<string>
│   │   ├── bookmarkedBy: array<string>
│   │   ├── replyCount: number
│   │   ├── createdAt: timestamp
│   │   └── replies/
│   │       └── {replyId}/
│   │           ├── text: string
│   │           ├── authorUid: string
│   │           └── createdAt: timestamp
├── users/
│   └── {userId}/
│       ├── fcmToken: string
│       ├── notificationsEnabled: boolean
│       ├── notificationTime: string
│       ├── badges: array<string>
│       └── updatedAt: timestamp
└── dailyTopQuotes/
    └── {dateId}/
        ├── quoteId: string
        ├── text: string
        ├── author: string
        ├── likes: number
        └── date: timestamp
```

## 9. UI/UX デザイン方針

### 9.1 デザイン原則

- **シンプル**: 余計な装飾を排除
- **直感的**: 説明不要な操作性
- **高速**: レスポンシブな反応
- **美しい**: 洗練されたデザイン

### 9.2 カラースキーム

- プライマリ: システムデフォルト
- アクセント: Pink（いいね）、Yellow（ブックマーク）
- 背景: システム準拠（ライト/ダーク対応予定）

### 9.3 フォント

- 見出し: System Bold
- 本文: System Regular
- 名言: System Serif

## 10. ビルド・実行コマンド

### iOS アプリのビルド

```bash
# シミュレーターでビルド
xcodebuild -scheme "名言sns" -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build

# 実機でビルド（要Apple Developer Program）
xcodebuild -scheme "名言sns" -sdk iphoneos build
```

### Firebase Functions

```bash
cd functions
npm install              # 依存関係インストール
npm run serve            # ローカルエミュレータ起動
npm run deploy           # 本番環境へデプロイ
npm run logs            # ログ確認
```

## 開発ルール

1. **コード品質**

   - SwiftUI のベストプラクティスに従う
   - MVVM パターンを使用（View - ViewModel - Model）
   - エラーハンドリングを適切に実装

2. **Firebase 利用**

   - 無料枠を意識した実装
   - セキュリティルールを適切に設定
   - バッチ処理でリクエスト数を削減

3. **UI/UX**
   - シンプルで直感的なデザイン
   - 日本語ユーザー向けの最適化
   - ダークモード対応（将来）

## 現在の実装状況

### ✅ 実装済み

- 名言の投稿・編集・削除
- 名言一覧表示
- いいね機能
- ブックマーク機能
- リプライ機能
- 検索機能
- 匿名認証
- 無限スクロール
- Cloud Functions（毎日のトップ名言集計）
- プッシュ通知基盤

### 🚧 実装中

- プッシュ通知（iOS 側の設定）

### 📋 TODO（優先順）

1. FirebaseMessaging のビルドエラー修正
2. 認証機能（メール/Apple/Google）
3. プロフィール機能
4. バッジ機能
5. 通知時間カスタマイズ UI

## トラブルシューティング

### FirebaseMessaging エラー

`Missing required module 'FirebaseMessagingInterop'`が発生した場合：

1. Xcode でプロジェクトを開く
2. File > Add Package Dependencies
3. Firebase SDK が正しく追加されているか確認
4. FirebaseMessaging を明示的に追加

## Firebase セキュリティルール（本番環境用）

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 名言の読み取りは全員可能
    match /quotes/{quoteId} {
      allow read: if true;
      // 未ログインでも投稿可能
      allow create: if true;
      // 未ログインでもいいね・ブックマーク可能
      allow update: if true;
      // 削除は本人または管理者のみ
      allow delete: if request.auth != null &&
        (request.auth.uid == resource.data.authorUid || isAdmin());

      // リプライ
      match /replies/{replyId} {
        allow read: if true;
        // 未ログインでもリプライ可能
        allow create: if true;
        // 削除は本人または管理者のみ
        allow delete: if request.auth != null &&
          (request.auth.uid == resource.data.authorUid || isAdmin());
      }
    }

    // ユーザー設定
    match /users/{userId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == userId;
    }
    
    // ヘルパー関数: ユーザーが運営者バッジを持っているかチェック（AdminPanel権限）
    function isAdmin() {
      return request.auth != null && 
        exists(/databases/$(database)/documents/userProfiles/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/userProfiles/$(request.auth.uid)).data.get('allBadges', []).hasAny(['admin']);
    }
    
    // ユーザープロフィール（読み取りは全員可能、書き込みは本人または運営者）
    match /userProfiles/{userId} {
      allow read: if true;
      allow create: if request.auth != null &&
        (request.auth.uid == userId || isAdmin()) &&
        (!("displayName" in request.resource.data) || 
          (request.resource.data.displayName is string && 
           request.resource.data.displayName.size() <= 30)) &&
        (!("bio" in request.resource.data) || 
          (request.resource.data.bio is string && 
           request.resource.data.bio.size() <= 160));
      allow update: if request.auth != null &&
        (request.auth.uid == userId || isAdmin()) &&
        (!("displayName" in request.resource.data) || 
          (request.resource.data.displayName is string && 
           request.resource.data.displayName.size() <= 30)) &&
        (!("bio" in request.resource.data) || 
          (request.resource.data.bio is string && 
           request.resource.data.bio.size() <= 160));
      allow delete: if request.auth != null &&
        (request.auth.uid == userId || isAdmin());
    }
    
    // 通知（読み取り・削除は本人のみ、作成は認証済みユーザー）
    match /notifications/{notificationId} {
      allow read, update, delete: if request.auth != null &&
        request.auth.uid == resource.data.toUserId;
      allow create: if request.auth != null;
    }
    
    // 毎日のトップ名言（読み取りのみ全員可能）
    match /dailyTopQuotes/{dateId} {
      allow read: if true;
      // 書き込みはCloud Functionsのみ
      allow write: if false;
    }
  }
}
```

### ルールの重要なポイント：
- **未ログインユーザー**: 投稿・いいね・ブックマーク・リプライ・閲覧が可能
- **ログインユーザー限定**: プロフィール編集・バッジ機能・個人通知・履歴保存
- **通知機能**: 日次トップ名言は全員、個人通知はログインユーザーのみ
- **管理者権限**: adminバッジ保有者のみ削除権限とAdminPanel権限

## 11. テスト戦略

### 11.1 単体テスト

- ViewModel のロジックテスト
- データモデルの変換テスト
- バリデーションテスト

### 11.2 統合テスト

- Firebase 連携テスト
- 通知機能テスト
- 認証フローテスト

### 11.3 UI テスト

- 主要な画面遷移
- 投稿・編集・削除フロー
- エラー表示の確認

## 12. リリース計画

### 12.1 MVP リリース（目標：1 ヶ月以内）

- [ ] 認証機能の完成
- [ ] プッシュ通知の完成
- [ ] Apple Developer Program 登録
- [ ] TestFlight でのベータテスト
- [ ] App Store 申請

### 12.2 Version 1.0 チェックリスト

- [ ] 全機能の動作確認
- [ ] パフォーマンステスト
- [ ] セキュリティ監査
- [ ] プライバシーポリシー作成
- [ ] 利用規約作成
- [ ] App Store スクリーンショット準備
- [ ] アプリ説明文の作成

### 12.3 マーケティング戦略

- SNS での告知
- プレスリリース
- インフルエンサーへの協力依頼
- ASO（App Store 最適化）

## 13. 監視・分析

### 13.1 Firebase Analytics 設定項目

- DAU/MAU
- 投稿数/日
- いいね数/日
- 通知開封率
- リテンション率

### 13.2 エラー監視

- Firebase Crashlytics 導入
- エラーレポートの自動通知
- パフォーマンスモニタリング

## 14. 収益化計画（将来）

### 14.1 フリーミアムモデル

**無料版**

- 基本機能すべて
- 広告表示あり
- ブックマーク上限 100 件

**プレミアム版（月額 300 円想定）**

- 広告非表示
- 無制限ブックマーク
- 特別バッジ
- 高度な検索機能
- 統計情報閲覧

### 14.2 収益目標

- 6 ヶ月後：月間アクティブユーザー 1,000 人
- 1 年後：有料会員 100 人（月額 3 万円）
- 2 年後：有料会員 500 人（月額 15 万円）

## 15. 連絡事項・メモ

### 15.1 重要な決定事項

- Firebase 無料枠での運用を前提
- iOS 先行リリース（Android 版は後日）
- 日本市場に特化

### 15.2 開発メモ

- リアルタイム更新と無限スクロールの両立実装済み
- FirebaseFunctions の代わりに Firestore を直接使用（コスト削減）
- プッシュ通知の実機テストは保留中

### 15.3 改善アイデア

- AI による不適切コンテンツフィルタリング
- 名言の自動翻訳機能
- 音声読み上げ機能
- ウィジェット対応
- Apple Watch 対応

## 16. リソース・参考資料

### 16.1 公式ドキュメント

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Firebase iOS Documentation](https://firebase.google.com/docs/ios/setup)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

### 16.2 デザインリソース

- SF Symbols（アイコン）
- システムカラー（iOS 標準色）

### 16.3 サポート

- 開発者：個人開発
- 連絡先：[メールアドレス]
- リポジトリ：[GitHub リンク]

## デプロイチェックリスト

- [ ] ビルドエラーがないことを確認
- [ ] Firebase 設定ファイル（GoogleService-Info.plist）が正しい
- [ ] Cloud Functions がデプロイされている
- [ ] Firestore のセキュリティルールが設定されている
- [ ] プッシュ通知の証明書が Firebase に登録されている（本番環境）
- [ ] プライバシーポリシー URL 設定
- [ ] 利用規約 URL 設定
- [ ] App Store Connect 設定完了

## 注意事項

- Apple Developer Program の登録は実機テスト時に必要（年間$99）
- プッシュ通知のテストにはシミュレーターでは制限あり
- Firebase 無料枠:
  - Firestore 読み取り: 50,000 回/日
  - Firestore 書き込み: 20,000 回/日
  - Cloud Functions 実行: 125,000 回/月
  - FCM 送信: 無制限（無料）
