# App Store審査対応メモ

## 1. Safety - User Generated Content（対応済み）

### 実装済みの安全対策：
- ✅ 利用規約への同意機能（投稿/リプライ時に表示、18歳以上の確認を含む）
- ✅ 不適切コンテンツの自動フィルタリング（ContentModerationService.swift）
- ✅ ユーザーによる通報機能（ReportView.swift、BlockAndReportManager.swift）
- ✅ ユーザーブロック機能
- ✅ アプリ内問い合わせフォーム（ContactSupportView.swift）
- ✅ 24時間以内の対応を明記
- ✅ 投稿の即座削除機能（運営者権限）

### App Store Connectでの設定：
- 年齢レーティング：4+（全年齢対象）に設定する（18歳制限を削除したため）

## 2. Support URL（対応済み）

### 更新済みのサポートURL：
- URL: https://sanq3.github.io/eminence-legal/legal-docs/contact.html
- 不適切コンテンツの24時間以内対応を明記
- 連絡先メールアドレス掲載
- FAQ セクション追加

## 3. App Tracking Transparency（対応必要）

### 現在の状況：
- **アプリはユーザーを追跡していません**
- Firebase Analyticsは使用していますが、広告目的のトラッキングは行っていません
- サードパーティとのデータ共有もありません

### App Store Connectでの対応：
1. App Privacy情報を更新：
   - 「データを収集していません」または
   - 「トラッキングに使用されるデータ」のチェックを外す

### 審査への返信内容（案）：
```
このアプリはユーザーをトラッキングしていません。
Firebase Analyticsは使用していますが、これはアプリの改善のための分析目的のみで、
広告目的のトラッキングやサードパーティとのデータ共有は行っていません。
App Store ConnectのPrivacy情報を適切に更新いたします。
```

## 実装ファイル一覧

### 安全対策関連：
- `ContentModerationService.swift` - 不適切コンテンツのフィルタリング
- `TermsAgreementView.swift` - 利用規約への同意画面（投稿/リプライ時に表示）
- `ContactSupportView.swift` - アプリ内問い合わせフォーム
- `ReportView.swift` - 通報画面
- `BlockAndReportManager.swift` - ブロック・通報管理

### 修正済みファイル：
- `QuoteViewModel.swift` - 投稿時のコンテンツフィルタリング追加
- `AddQuoteView.swift` - 投稿時に利用規約同意を確認
- `QuoteDetailView.swift` - リプライ時に利用規約同意を確認
- `SettingsView.swift` - 問い合わせフォームへのリンク追加
- `legal-docs/contact.html` - サポートページ更新（24時間対応明記）

### 利用規約同意の仕様：
- **アプリ起動時**: 同意不要（閲覧のみ可能）
- **初回投稿時**: 利用規約への同意が必要
- **初回リプライ時**: 利用規約への同意が必要
- **同意後**: 再度の同意は不要（バージョン更新時を除く）

### UI表示の重要な仕様：
- **ホーム画面（カード表示）**: 名言文と右下の作者名のみ表示（投稿時間は表示しない）
- **詳細画面**: 投稿時間を表示
- **投稿ボタン**: 「保存」ではなく「投稿」と表示
- **投稿後**: 自動的に投稿画面を閉じる
- **連打防止**: 投稿中は「投稿中...」表示でボタンをdisable

## 次のステップ

1. App Store Connectにログイン
2. App Privacy情報を更新（トラッキングなしに設定）
3. 年齢レーティングを17+に設定
4. 審査への返信で上記の対応を説明
5. アプリを再提出

## 注意事項

- 利用規約への同意は初回起動時に表示される
- 不適切コンテンツは投稿時に自動フィルタリング
- 通報機能はFirestoreのreportsコレクションに保存
- 24時間以内の対応はマニュアルで行う必要あり（Cloud Functionsで自動化も可能）