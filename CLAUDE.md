# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

「エミネンス」 - 日々の生活に気づきと感動を与える言葉を共有し、最も心に響いた名言を毎日届けるiOSアプリ

## 開発コマンド

### iOSアプリ
```bash
# シミュレーターでビルド・実行
xcodebuild -scheme "エミネンス" -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build

# 実機でビルド（要Apple Developer Program）
xcodebuild -scheme "エミネンス" -sdk iphoneos build

# Xcodeで開く
open エミネンス.xcodeproj
```

### Firebase Functions
```bash
cd functions
npm install              # 依存関係インストール
npm run serve           # ローカルエミュレータ起動
npm run deploy          # 本番環境へデプロイ
npm run logs           # ログ確認
```

### Firebase設定
```bash
# Firestoreルールのデプロイ
firebase deploy --only firestore:rules

# インデックスのデプロイ
firebase deploy --only firestore:indexes
```

## アーキテクチャ

### 技術スタック
- **Frontend**: SwiftUI (iOS 15.0+)
- **Architecture**: MVVM
- **Backend**: Firebase (Firestore, Auth, Functions, FCM)
- **Language**: Swift 5

### 主要コンポーネント

#### ViewModels (ObservableObject)
- `QuoteViewModel`: 名言の投稿・取得・いいね・ブックマーク管理
- `ProfileViewModel`: ユーザープロフィール・バッジ管理
- `NotificationViewModel`: 通知管理

#### Views構成
- `MainTabView`: タブ管理（ホーム、検索、投稿、通知、設定）
- `ContentView`: 名言一覧（無限スクロール対応）
- `QuoteDetailView`: 名言詳細・リプライ機能
- `AddQuoteView`: 新規投稿
- `SettingsView`: 設定・プロフィール管理

#### 認証フロー
1. 起動時に匿名認証自動実行
2. プロフィール編集時にログイン促進
3. Apple/Google認証への移行サポート

### Firestore構造
```
quotes/
  {quoteId}/
    - text, author, authorUid, likes, likedBy[], bookmarkedBy[]
    - replies/{replyId}/
      - text, authorUid, createdAt

userProfiles/
  {userId}/
    - displayName, bio, allBadges[], profileImageUrl

notifications/
  {notificationId}/
    - type, fromUserId, toUserId, quoteId, isRead

dailyTopQuotes/
  {dateId}/
    - quoteId, text, author, likes
```

## 重要な実装ルール

### バッジシステム
- **adminバッジのみがAdminPanel権限を持つ**
- verifiedバッジ = 青チェック🔵（権限なし）
- adminバッジ = 赤チェック🔴 + 削除権限
- developerバッジ = バッジアイコンのみ

### セキュリティ
- 未ログインユーザーも投稿・いいね・リプライ可能
- 削除は投稿者本人またはadminバッジ保有者のみ
- プロフィール編集は本人のみ

### パフォーマンス最適化
- 無限スクロール（20件ずつ読み込み）
- LazyVStackで効率的なレンダリング
- Firebaseリスナーの適切な管理

### エラーハンドリング
- ネットワークエラー時の適切なメッセージ表示
- Firebase無料枠を考慮したクエリ設計
- バッチ処理でリクエスト数削減

## デプロイ前チェックリスト

- [ ] GoogleService-Info.plistが正しい環境用か確認
- [ ] Firebaseセキュリティルールをデプロイ
- [ ] Cloud Functionsをデプロイ
- [ ] プライバシーポリシー・利用規約URLを設定
- [ ] App Store Connect設定完了

## Firebase無料枠制限
- Firestore読み取り: 50,000回/日
- Firestore書き込み: 20,000回/日
- Cloud Functions実行: 125,000回/月
- FCM送信: 無制限