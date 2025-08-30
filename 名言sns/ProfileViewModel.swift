import Foundation
import FirebaseFirestore
import FirebaseAuth
// import FirebaseStorage // TODO: Add Firebase Storage package
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var bookmarkedQuotesCount = 0 // ブックマーク数を追跡
    
    private let db = Firestore.firestore()
    private let badgeManager = BadgeManager()
    private var bookmarkListener: ListenerRegistration?
    
    func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        // ブックマーク数をリアルタイムで監視
        setupBookmarkCountListener()
        
        db.collection("userProfiles").document(uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                if let document = document, document.exists {
                    do {
                        self?.userProfile = try document.data(as: UserProfile.self)
                        
                    } catch {
                        self?.errorMessage = error.localizedDescription
                    }
                } else {
                    // 新しいプロフィールを作成
                    self?.createNewProfile(uid: uid)
                }
            }
        }
    }
    
    // ブックマーク数をリアルタイムで監視
    private func setupBookmarkCountListener() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        bookmarkListener?.remove()
        
        // ブックマークした名言数を監視
        bookmarkListener = db.collection("quotes")
            .whereField("bookmarkedBy", arrayContains: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let documents = snapshot?.documents {
                        self?.bookmarkedQuotesCount = documents.count
                    }
                }
            }
    }
    
    private func createNewProfile(uid: String) {
        let newProfile = UserProfile(uid: uid)
        userProfile = newProfile
        saveUserProfile()
    }
    
    func saveUserProfile(completion: ((Bool) -> Void)? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else { 
            print("ERROR: No user ID found. Current user: \(String(describing: Auth.auth().currentUser))")
            completion?(false)
            return 
        }
        
        guard let profile = userProfile else { 
            print("ERROR: No profile found for user: \(uid)")
            completion?(false)
            return 
        }
        
        print("Saving profile for user: \(uid), isAnonymous: \(Auth.auth().currentUser?.isAnonymous ?? true)")
        
        var updatedProfile = profile
        updatedProfile.updatedAt = Date()
        
        // シンプルな辞書形式でデータを保存
        let data: [String: Any] = [
            "uid": updatedProfile.uid,
            "displayName": updatedProfile.displayName,
            "bio": updatedProfile.bio,
            "profileImageURL": updatedProfile.profileImageURL,
            "createdAt": Timestamp(date: updatedProfile.createdAt),
            "updatedAt": Timestamp(date: updatedProfile.updatedAt),
            "postCount": updatedProfile.postCount,
            "likesReceived": updatedProfile.likesReceived,
            "selectedBadges": updatedProfile.selectedBadges,
            "allBadges": updatedProfile.allBadges
        ]
        
        db.collection("userProfiles").document(uid).setData(data, merge: true) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    print("Error saving profile: \(error)")
                    completion?(false)
                } else {
                    self?.userProfile = updatedProfile
                    // プロフィール画像データが長いのでログを短縮
                    var logData = data
                    if let imageURL = logData["profileImageURL"] as? String, imageURL.count > 100 {
                        logData["profileImageURL"] = "data:image/jpeg;base64,[TRUNCATED]"
                    }
                    print("Profile saved successfully with data: \(logData)")
                    completion?(true)
                }
            }
        }
    }
    
    func updateDisplayName(_ name: String, completion: ((Bool) -> Void)? = nil) {
        userProfile?.displayName = name
        saveUserProfile(completion: completion)
    }
    
    func updateBio(_ bio: String, completion: ((Bool) -> Void)? = nil) {
        userProfile?.bio = bio
        saveUserProfile(completion: completion)
    }
    
    func uploadProfileImage(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("⚠️ WARNING: No user ID for image upload")
            completion(false)
            return
        }
        
        // 本番環境用: 画像サイズを厳格に制限してBase64保存
        // 将来的にFirebase Storageに移行予定
        
        // 画像を大幅に圧縮 (0.05 = 5% quality)
        guard let imageData = image.jpegData(compressionQuality: 0.05) else {
            completion(false)
            return
        }
        
        // 50KB制限（本番環境での安全性を確保）
        let sizeInKB = imageData.count / 1024
        print("📊 Image size: \(sizeInKB)KB")
        if sizeInKB > 50 {
            print("❌ ERROR: Image too large (\(sizeInKB)KB). Maximum 50KB allowed.")
            completion(false)
            return
        }
        let base64String = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64String)"
        
        DispatchQueue.main.async { [weak self] in
            self?.userProfile?.profileImageURL = dataURL
            self?.saveUserProfile { success in
                completion(success)
            }
        }
        
        /* Firebase Storage implementation (uncomment after adding package):
        let storageRef = Storage.storage().reference()
        let profileImageRef = storageRef.child("profileImages/\(uid).jpg")
        
        profileImageRef.putData(imageData, metadata: nil) { [weak self] metadata, error in
            if let error = error {
                print("Error uploading image: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            profileImageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error)")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                
                if let downloadURL = url {
                    DispatchQueue.main.async {
                        self?.userProfile?.profileImageURL = downloadURL.absoluteString
                        self?.saveUserProfile()
                        completion(true)
                    }
                }
            }
        }
        */
    }
    
    func updateSelectedBadges(_ badges: [String]) {
        // 最大4つまで
        let limitedBadges = Array(badges.prefix(4))
        userProfile?.selectedBadges = limitedBadges
        saveUserProfile()
    }
    
    func addBadge(_ badgeId: String) {
        guard var profile = userProfile else { return }
        
        if !profile.allBadges.contains(badgeId) {
            profile.allBadges.append(badgeId)
            
            // 自動的に表示バッジに追加（4つ未満の場合）
            if profile.selectedBadges.count < 4 {
                profile.selectedBadges.append(badgeId)
            }
            
            userProfile = profile
            saveUserProfile()
        }
    }
    
    func checkAndAwardBadges() {
        guard let profile = userProfile else { return }
        
        // 初投稿バッジ
        if profile.postCount >= 1 && !profile.allBadges.contains("first_post") {
            addBadge("first_post")
        }
        
        // いいね10個バッジ
        if profile.likesReceived >= 10 && !profile.allBadges.contains("like_collector") {
            addBadge("like_collector")
        }
        
        // いいね50個バッジ
        if profile.likesReceived >= 50 && !profile.allBadges.contains("popular") {
            addBadge("popular")
        }
        
        // 100投稿バッジ
        if profile.postCount >= 100 && !profile.allBadges.contains("wisdom_master") {
            addBadge("wisdom_master")
        }
    }
    
    func incrementPostCount() {
        userProfile?.postCount += 1
        checkAndAwardBadges()
        saveUserProfile()
    }
    
    func incrementLikesReceived() {
        userProfile?.likesReceived += 1
        checkAndAwardBadges()
        saveUserProfile()
    }
    
    // 実際の投稿数を取得して更新
    func updateActualPostCount() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("quotes")
            .whereField("authorUid", isEqualTo: uid)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let documents = snapshot?.documents {
                        let actualCount = documents.count
                        self?.userProfile?.postCount = actualCount
                        self?.checkAndAwardBadges()
                        self?.saveUserProfile()
                    }
                }
            }
    }
    
    func clearUserProfile() {
        userProfile = nil
        bookmarkListener?.remove()
        bookmarkListener = nil
        bookmarkedQuotesCount = 0
    }
}