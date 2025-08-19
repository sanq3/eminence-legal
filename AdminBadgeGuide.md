# 運営者・認証バッジの付与方法

## 方法1: Firebase Console から直接付与（推奨）

### 手順：

1. **Firebase Console にログイン**
   - https://console.firebase.google.com/
   - プロジェクト「meigen-66989」を選択

2. **Firestore Database を開く**
   - 左メニューから「Firestore Database」を選択

3. **ユーザーのプロフィールを探す**
   - `userProfiles` コレクションを開く
   - 付与したいユーザーのドキュメントID（ユーザーID）を探す
   - ※ユーザーIDは、アプリの設定画面でユーザー名の下に表示される「@」から始まる8文字

4. **バッジを追加**
   - 該当ユーザーのドキュメントを開く
   - `allBadges` フィールドを編集
   - 配列に以下の値を追加：
     - **運営者バッジ**: `"admin"`
     - **認証バッジ**: `"verified"`

### 例：
```
allBadges: [
  "first_post",     // 既存のバッジ
  "ten_likes",      // 既存のバッジ
  "admin",          // 運営者バッジを追加
  "verified"        // 認証バッジを追加
]
```

## 方法2: 管理者用コマンド（Cloud Functions）

### セットアップ：

1. **Cloud Function を作成**
```javascript
// functions/index.js に追加

// 管理者バッジ付与関数
exports.grantAdminBadge = functions.https.onCall(async (data, context) => {
  // 管理者チェック（あなたのユーザーIDを設定）
  const ADMIN_UIDS = ['YOUR_ADMIN_UID_HERE'];
  
  if (!context.auth || !ADMIN_UIDS.includes(context.auth.uid)) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can grant badges');
  }
  
  const { targetUserId, badgeType } = data;
  
  if (!targetUserId || !['admin', 'verified'].includes(badgeType)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid parameters');
  }
  
  // バッジ付与
  await admin.firestore()
    .collection('userProfiles')
    .doc(targetUserId)
    .update({
      allBadges: admin.firestore.FieldValue.arrayUnion(badgeType),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  
  return { success: true, message: `${badgeType} badge granted to ${targetUserId}` };
});
```

2. **デプロイ**
```bash
cd functions
npm run deploy --only functions:grantAdminBadge
```

## 方法3: アプリ内秘密コマンド（簡易版）

### 実装済みの隠し機能：

設定画面のバージョン番号を**10回連続タップ**すると、管理者モードが有効になります。

### 使い方：

1. 設定画面を開く
2. バージョン番号「1.0.0」を10回タップ
3. 管理者パネルが表示される
4. ユーザーIDを入力してバッジを付与

---

## バッジの意味

### 🛡️ 運営者バッジ（admin）
- アプリの運営者・開発者
- 赤色のシールドアイコン
- 信頼性の証

### ✓ 認証バッジ（verified）  
- 公式認証されたアカウント
- 青色のチェックマーク
- 有名人・インフルエンサー向け

## 注意事項

- バッジを付与すると即座に反映されます
- 一度付与したバッジは、Firebase Console から手動で削除する必要があります
- ユーザーIDは大文字小文字を区別します

## トラブルシューティング

### バッジが表示されない場合：

1. ユーザーがログアウト→ログインし直す
2. アプリを完全に終了して再起動
3. Firebase Console でデータが正しく保存されているか確認

### ユーザーIDの確認方法：

1. アプリの設定画面で確認
2. Firebase Console の `userProfiles` コレクションで確認
3. Firebase Authentication でメールアドレスから検索