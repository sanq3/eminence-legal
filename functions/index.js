const {onDocumentCreated, onDocumentDeleted} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue, Timestamp} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// A new reply is created - リプライカウント更新と通知送信
exports.onReplyCreated = onDocumentCreated("quotes/{quoteId}/replies/{replyId}", async (event) => {
  const quoteId = event.params.quoteId;
  const replyData = event.data.data();
  const quoteRef = db.collection("quotes").doc(quoteId);

  try {
    // Atomically increment the reply count
    await quoteRef.update({
      replyCount: FieldValue.increment(1)
    });
    console.log(`Successfully incremented replyCount for quote ${quoteId}`);
    
    // リプライ通知を送信
    const quoteDoc = await quoteRef.get();
    if (!quoteDoc.exists) return;
    
    const quoteData = quoteDoc.data();
    const authorUid = quoteData.authorUid;
    
    // 自分自身へのリプライは通知しない
    if (!authorUid || authorUid === replyData.authorUid) return;
    
    // 投稿者のFCMトークンを取得
    const userDoc = await db.collection('users').doc(authorUid).get();
    if (!userDoc.exists) return;
    
    const userData = userDoc.data();
    if (!userData.fcmToken || userData.notificationsEnabled === false) {
      return;
    }
    
    // 通知を送信
    const message = {
      notification: {
        title: '新しい返信',
        body: `${replyData.author || '誰か'}さんが返信しました: 「${replyData.text.substring(0, 30)}${replyData.text.length > 30 ? '...' : ''}」`,
      },
      token: userData.fcmToken,
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
      data: {
        quoteId: quoteId,
        type: 'reply'
      }
    };
    
    try {
      await messaging.send(message);
      logger.info('Reply notification sent successfully');
    } catch (error) {
      logger.error('Error sending reply notification:', error);
    }
  } catch (error) {
    console.error(`Error in onReplyCreated for quote ${quoteId}:`, error);
  }
});

// A reply is deleted
exports.onReplyDeleted = onDocumentDeleted("quotes/{quoteId}/replies/{replyId}", async (event) => {
  const quoteId = event.params.quoteId;
  const quoteRef = db.collection("quotes").doc(quoteId);

  try {
    // Atomically decrement the reply count
    await quoteRef.update({
      replyCount: FieldValue.increment(-1)
    });
    console.log(`Successfully decremented replyCount for quote ${quoteId}`);
  } catch (error) {
    console.error(`Error decrementing replyCount for quote ${quoteId}:`, error);
  }
});

// 毎日午後9時（JST）にトップ名言を集計してプッシュ通知を送信
exports.sendDailyTopQuote = onSchedule({
  schedule: "0 21 * * *",
  timeZone: "Asia/Tokyo",
  region: "asia-northeast1"
}, async (event) => {
  logger.info("Daily top quote function started");
  
  try {
    // 今日の日付範囲を取得（JST）
    const now = new Date();
    const todayStart = new Date(now);
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date(now);
    todayEnd.setHours(23, 59, 59, 999);
    
    // 今日投稿された名言を取得
    const quotesSnapshot = await db
      .collection("quotes")
      .where("createdAt", ">=", Timestamp.fromDate(todayStart))
      .where("createdAt", "<=", Timestamp.fromDate(todayEnd))
      .orderBy("createdAt", "desc")
      .get();
    
    if (quotesSnapshot.empty) {
      logger.info("No quotes found for today");
      return null;
    }
    
    // いいね数が最も多い名言を見つける
    let topQuote = null;
    let maxLikes = -1;
    
    quotesSnapshot.forEach((doc) => {
      const quote = doc.data();
      if (quote.likes > maxLikes) {
        maxLikes = quote.likes;
        topQuote = {
          id: doc.id,
          ...quote,
        };
      }
    });
    
    if (!topQuote) {
      logger.info("No top quote found");
      return null;
    }
    
    // トップ名言を保存
    await db.collection("dailyTopQuotes").add({
      quoteId: topQuote.id,
      text: topQuote.text,
      author: topQuote.author || "匿名",
      likes: topQuote.likes,
      date: Timestamp.fromDate(todayStart),
      createdAt: FieldValue.serverTimestamp(),
    });
    
    // プッシュ通知の準備
    const notification = {
      title: "今日の名言",
      body: `「${topQuote.text.substring(0, 50)}${topQuote.text.length > 50 ? "..." : ""}」 - ${topQuote.author || "匿名"} (${topQuote.likes} いいね)`,
    };
    
    // FCMトークンを持つユーザーに通知を送信
    const tokensSnapshot = await db
      .collection("users")
      .where("fcmToken", "!=", null)
      .where("notificationsEnabled", "==", true)
      .get();
    
    if (tokensSnapshot.empty) {
      logger.info("No users with FCM tokens found");
      return null;
    }
    
    const tokens = [];
    tokensSnapshot.forEach((doc) => {
      const userData = doc.data();
      if (userData.fcmToken) {
        tokens.push(userData.fcmToken);
      }
    });
    
    if (tokens.length > 0) {
      const message = {
        notification: notification,
        tokens: tokens,
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };
      
      const response = await messaging.sendEachForMulticast(message);
      logger.info(`Successfully sent messages: ${response.successCount}`);
      logger.info(`Failed messages: ${response.failureCount}`);
    }
    
    logger.info("Daily top quote function completed successfully");
    return null;
  } catch (error) {
    logger.error("Error in daily top quote function:", error);
    throw error;
  }
});

// ユーザーのFCMトークンを更新
exports.updateFCMToken = onCall({
  region: "asia-northeast1",
  cors: true
}, async (request) => {
  // 認証チェック
  if (!request.auth) {
    throw new Error("User must be authenticated");
  }
  
  const { fcmToken } = request.data;
  const uid = request.auth.uid;
  
  if (!fcmToken) {
    throw new Error("FCM token is required");
  }
  
  try {
    await db.collection("users").doc(uid).set(
      {
        fcmToken: fcmToken,
        notificationsEnabled: true,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    
    return { success: true };
  } catch (error) {
    logger.error("Error updating FCM token:", error);
    throw new Error("Failed to update FCM token");
  }
});

// 通知設定を更新
exports.updateNotificationSettings = onCall({
  region: "asia-northeast1",
  cors: true
}, async (request) => {
  // 認証チェック
  if (!request.auth) {
    throw new Error("User must be authenticated");
  }
  
  const { notificationsEnabled, notificationTime } = request.data;
  const uid = request.auth.uid;
  
  try {
    const updateData = {
      updatedAt: FieldValue.serverTimestamp(),
    };
    
    if (notificationsEnabled !== undefined) {
      updateData.notificationsEnabled = notificationsEnabled;
    }
    
    if (notificationTime !== undefined) {
      updateData.notificationTime = notificationTime;
    }
    
    await db.collection("users").doc(uid).set(
      updateData,
      { merge: true }
    );
    
    return { success: true };
  } catch (error) {
    logger.error("Error updating notification settings:", error);
    throw new Error("Failed to update notification settings");
  }
});

// いいね通知機能
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
exports.onQuoteLiked = onDocumentUpdated("quotes/{quoteId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const quoteId = event.params.quoteId;
  
  try {
    // いいねが増えたかチェック
    if (afterData.likes <= beforeData.likes) {
      return null;
    }
    
    // 投稿者のFCMトークンを取得
    const authorUid = afterData.authorUid;
    if (!authorUid) return null;
    
    // 新しくいいねしたユーザーを特定（最後に追加されたユーザー）
    const newLikers = afterData.likedBy.filter(uid => !beforeData.likedBy.includes(uid));
    if (newLikers.length === 0) return null;
    
    // 自分自身のいいねは通知しない
    if (newLikers[0] === authorUid) return null;
    
    const userDoc = await db.collection('users').doc(authorUid).get();
    if (!userDoc.exists) return null;
    
    const userData = userDoc.data();
    if (!userData.fcmToken || userData.notificationsEnabled === false) {
      return null;
    }
    
    // 通知を送信
    const message = {
      notification: {
        title: '新しいいいね❤️',
        body: `「${afterData.text.substring(0, 30)}${afterData.text.length > 30 ? '...' : ''}」にいいねがつきました`,
      },
      token: userData.fcmToken,
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
      data: {
        quoteId: quoteId,
        type: 'like'
      }
    };
    
    try {
      await messaging.send(message);
      logger.info('Like notification sent successfully');
    } catch (error) {
      logger.error('Error sending like notification:', error);
    }
  } catch (error) {
    logger.error(`Error in onQuoteLiked for quote ${quoteId}:`, error);
  }
});
