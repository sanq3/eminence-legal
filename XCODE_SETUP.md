# Xcode設定手順

## 1. Sign in with Appleの有効化

1. Xcodeでプロジェクトを開く
2. プロジェクトナビゲーターで「名言sns」を選択
3. 「Signing & Capabilities」タブを選択
4. 「+ Capability」ボタンをクリック
5. 「Sign in with Apple」を検索して追加

## 2. Push Notificationsの有効化

1. 同じく「Signing & Capabilities」タブで
2. 「+ Capability」ボタンをクリック
3. 「Push Notifications」を追加

## 3. Background Modesの有効化

1. 「+ Capability」ボタンをクリック
2. 「Background Modes」を追加
3. 「Remote notifications」にチェック

## 4. Bundle Identifierの確認

現在: jp.yourname.名言sns（または類似）
推奨: そのままでOK（App Store公開後は変更不可）

## 5. Deployment Target

iOS 15.0以上に設定

## 6. Device Orientation

iPhoneの場合：Portrait のみチェック
iPadの場合：すべてチェック

## 7. App Icons

Assets.xcassets > AppIcon に1024x1024のアイコンが設定済み

## これらの設定後、一度クリーンビルドを実行：
- Product > Clean Build Folder（Shift+Cmd+K）
- Product > Build（Cmd+B）