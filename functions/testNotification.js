const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

async function sendTestNotification() {
  try {
    console.log('Starting test notification...');
    
    // 最新の名言を取得
    const quotesSnapshot = await db
      .collection('quotes')
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();
    
    if (quotesSnapshot.empty) {
      console.log('No quotes found');
      return;
    }
    
    const topQuote = quotesSnapshot.docs[0].data();
    console.log('Found quote:', topQuote.text);
    
    // プッシュ通知の準備
    const notification = {
      title: '【テスト】今日の名言',
      body: `「${topQuote.text.substring(0, 50)}${topQuote.text.length > 50 ? '...' : ''}」 - ${topQuote.author || '匿名'} (${topQuote.likes || 0} いいね)`,
    };
    
    // FCMトークンを持つユーザーを取得
    const tokensSnapshot = await db
      .collection('users')
      .where('fcmToken', '!=', null)
      .get();
    
    if (tokensSnapshot.empty) {
      console.log('No users with FCM tokens found');
      console.log('Make sure your app is running on a real device and has registered for notifications');
      return;
    }
    
    const tokens = [];
    tokensSnapshot.forEach((doc) => {
      const userData = doc.data();
      if (userData.fcmToken) {
        tokens.push(userData.fcmToken);
        console.log('Found token for user:', doc.id);
      }
    });
    
    console.log(`Found ${tokens.length} FCM tokens`);
    
    if (tokens.length > 0) {
      const message = {
        notification: notification,
        tokens: tokens,
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };
      
      const response = await messaging.sendEachForMulticast(message);
      console.log(`Successfully sent messages: ${response.successCount}`);
      console.log(`Failed messages: ${response.failureCount}`);
      
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`Error sending to token ${idx}:`, resp.error.message);
          }
        });
      }
    }
    
    console.log('Test notification completed');
  } catch (error) {
    console.error('Error sending test notification:', error);
  }
  process.exit(0);
}

sendTestNotification();