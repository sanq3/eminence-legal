# アプリ概要（名言 sns）

## 目的

- みんなの心に残った言葉（名言）を共有し、いいねで応援するシンプルな SNS。

## 主要機能（MVP）

- タイムライン
  - Firestore の `quotes` コレクションを新着順でリスト表示
  - 無限監視（snapshot listener）でリアルタイム反映
- 投稿
  - 本文と作者名（未入力なら匿名表記）
- いいね
  - `likes` を原子的にインクリメント
- 編集/削除
  - 自分の投稿を編集、削除（暫定：誰でも操作できる UI だが、将来は認証で制御）
- 検索
  - クライアント側で本文・作者名を部分一致フィルタ

## データモデル

- コレクション: `quotes`
- ドキュメント: `Quote`
  - `id: String?`（@DocumentID）
  - `text: String`
  - `author: String`
  - `likes: Int`
  - `createdAt: Date`

## 技術スタック

- iOS: SwiftUI, iOS 15+（シミュレータは 18.2 で検証）
- データ: Firebase Firestore（Firebase iOS SDK v12）
  - import は `FirebaseFirestore` のみを使用

## 将来拡張（提案ベース）

- 認証（匿名 or Apple Sign In）
- 自分の投稿のみ編集/削除可能にする権限設計
- サーバータイムスタンプ、Cloud Functions での整合性付与
- ページング／サーバーサイド検索

## 非機能要件

- 最小差分・高いビルド成功率
- 実機依存のないシミュレーター運用（署名不要）
