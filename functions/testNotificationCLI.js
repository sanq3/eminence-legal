// Firebase CLIを使用したテスト用スクリプト

// Firebaseプロジェクトの設定
const projectId = 'meigen-66989';

console.log('Testing notification system...');
console.log('Project ID:', projectId);
console.log('');
console.log('手動テスト方法:');
console.log('1. Firebase Consoleにアクセス: https://console.firebase.google.com');
console.log('2. プロジェクト「meigen-66989」を選択');
console.log('3. 左メニューから「Cloud Messaging」を選択');
console.log('4. 「新しい通知」または「最初のキャンペーンを作成」をクリック');
console.log('5. 以下の内容で通知を送信:');
console.log('   - タイトル: テスト通知');
console.log('   - テキスト: プッシュ通知のテストです');
console.log('   - ターゲット: アプリ（名言sns）');
console.log('');
console.log('実機での確認項目:');
console.log('✅ アプリが実機にインストールされている');
console.log('✅ 通知が許可されている（設定 > 通知 > 名言sns）');
console.log('✅ アプリを一度起動してFCMトークンを登録済み');
console.log('');
console.log('Firestore確認コマンド:');
console.log('firebase firestore:export users.json --collection users');
