const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // この後作成します

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkTokens() {
  console.log('\n📱 FCMトークンの登録状況を確認中...\n');
  
  try {
    const usersSnapshot = await db.collection('users').get();
    
    if (usersSnapshot.empty) {
      console.log('❌ usersコレクションが空です');
      console.log('→ アプリを実機で起動してください\n');
      return;
    }
    
    let tokenCount = 0;
    let enabledCount = 0;
    
    console.log(`👥 登録ユーザー数: ${usersSnapshot.size}\n`);
    
    usersSnapshot.forEach(doc => {
      const data = doc.data();
      console.log(`ユーザーID: ${doc.id}`);
      
      if (data.fcmToken) {
        tokenCount++;
        console.log(`  ✅ FCMトークン: ${data.fcmToken.substring(0, 20)}...`);
      } else {
        console.log(`  ❌ FCMトークン: なし`);
      }
      
      if (data.notificationsEnabled) {
        enabledCount++;
        console.log(`  ✅ 通知設定: 有効`);
      } else {
        console.log(`  ⚠️ 通知設定: 無効または未設定`);
      }
      
      console.log('');
    });
    
    console.log('📊 サマリー:');
    console.log(`  FCMトークン登録済み: ${tokenCount}/${usersSnapshot.size}`);
    console.log(`  通知有効: ${enabledCount}/${usersSnapshot.size}`);
    
    if (tokenCount === 0) {
      console.log('\n⚠️ 対処法:');
      console.log('1. 実機でアプリを削除して再インストール');
      console.log('2. 通知許可ダイアログで「許可」を選択');
      console.log('3. アプリを完全に終了して再起動');
    }
    
  } catch (error) {
    console.error('エラー:', error);
  }
  
  process.exit(0);
}

checkTokens();