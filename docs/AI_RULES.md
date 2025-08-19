# LLM 作業ルール（必ず読む）

このプロジェクトで CLI/AI（Gemini, Cursor など）がコードを触る際の固定ルールです。毎回のセッション開始時に本ファイルと `docs/APP_SPEC.md`, `docs/TODO.md` を参照させてください。

## 基本方針

- 目的は「最小差分でビルド／実行を安定させる」こと。
- 既存挙動を壊さない。大規模改変・設計変更は提案のみで編集禁止。
- 出力は「最小差分（unified diff）」を基本とし、理由は簡潔に（3 行以内）。

## 禁止事項（重要）

- Xcode プロジェクト/依存の変更
  - `名言sns.xcodeproj/**`, `*.pbxproj`, `*.xcworkspace/**`, `Package.resolved` の変更
  - SPM 追加/削除、ターゲット/ビルド設定変更、バンドル ID/サイニング設定変更
- ファイル操作
  - Swift ファイルの新規作成・削除・リネーム（明示許可がある場合を除く）
  - `GoogleService-Info.plist`, `Assets.xcassets/**` の変更
- ライブラリの勝手な追加・置換
  - Firestore は Firebase iOS SDK v12 系。`FirebaseFirestoreSwift` は統合済みのため追加禁止。

## 許可事項

- 変更可能ファイル: `名言sns/名言sns/*.swift`（既存ファイルのみ）
- 内容: `import` の整理、コンパイル修正、NPE/クラッシュ回避など「最小差分」のみ

## Firestore に関する取り決め（v12）

- `import FirebaseFirestore` のみ使用。
- `@DocumentID`, `data(as:)`, `addDocument(from:)`, `setData(from:)` は `FirebaseFirestore` 内で利用可能。
- `FirebaseFirestoreSwift` を導入・import しないこと。

## 実行・検証ルール

- 実機ビルドは署名が必要なため、原則シミュレーターで検証。
- 参考コマンド（変更禁止の既定値）:
  ```bash
  xcodebuild \
    -workspace "名言sns/名言sns.xcodeproj/project.xcworkspace" \
    -scheme "名言sns" \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' \
    -configuration Debug build
  ```

## 出力フォーマット

- 変更提案は必ず unified diff（最小差分）。
- 影響範囲が広い場合は「編集せずに」提案だけを出す。

## 運用ルール（人間の手順）

1. 変更前に必ずスナップショット: `git add -A && git commit -m "snapshot-before-llm"`
2. CLI 実行後は `git diff` で差分確認 →OK なら commit。
3. 不明確な要求は編集せず提案のみを出すよう指示。

---

## セッション開始時に CLI に与えるプリセット（コピペ）

```
以下のドキュメントを読み込んでから作業してください：
- docs/AI_RULES.md
- docs/APP_SPEC.md
- docs/TODO.md

厳守ルール：
- 変更は最小差分。編集可: 名言sns/名言sns/*.swift のみ
- 変更禁止: 名言sns.xcodeproj/**, *.pbxproj, *.xcworkspace/**, Package.resolved, Assets.xcassets/**, GoogleService-Info.plist
- Firestore は FirebaseFirestore のみ。FirebaseFirestoreSwift を追加/使用しない
- 出力は unified diff のみ、理由は3行以内
複数案がある場合は編集せず提案のみ
```
