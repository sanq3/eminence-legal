const admin = require('firebase-admin');

// Firebase Admin SDKの初期化（既に初期化されている場合はスキップ）
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

/**
 * 特定のユーザーに開発者バッジを付与する
 * 使い方: node grantDeveloperBadge.js
 */
async function grantDeveloperBadge() {
    const userId = 'CeLLQFBX';  // あなたのユーザーID
    
    try {
        console.log(`ユーザー ${userId} に開発者バッジを付与しています...`);
        
        // userProfilesコレクションにドキュメントを作成/更新
        await db.collection('userProfiles').doc(userId).set({
            uid: userId,
            allBadges: admin.firestore.FieldValue.arrayUnion('developer'),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        
        console.log('✅ 開発者バッジを付与しました！');
        console.log('📱 アプリの設定画面で以下の操作を行ってください：');
        console.log('   1. アプリを完全に終了して再起動');
        console.log('   2. プロフィール画面を確認（開発者バッジが表示されます）');
        console.log('   3. 設定画面のバージョン番号を10回タップ（管理者パネルが開きます）');
        
        // 現在のバッジ状態を確認
        const doc = await db.collection('userProfiles').doc(userId).get();
        if (doc.exists) {
            const data = doc.data();
            console.log('\n現在のバッジ:', data.allBadges || []);
        }
        
    } catch (error) {
        console.error('❌ エラーが発生しました:', error);
    }
    
    process.exit();
}

// 実行
grantDeveloperBadge();