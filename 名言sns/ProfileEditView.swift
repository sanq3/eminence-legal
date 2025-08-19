import SwiftUI
import FirebaseAuth

struct ProfileEditView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isUploading = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // プロフィール画像
                    VStack(spacing: 12) {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            ZStack {
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else if let imageURL = profileViewModel.userProfile?.profileImageURL,
                                          !imageURL.isEmpty {
                                    if imageURL.hasPrefix("data:") {
                                        // Base64画像の場合
                                        if let data = Data(base64Encoded: String(imageURL.dropFirst(23))),
                                           let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .font(.system(size: 100))
                                                .foregroundColor(.secondary)
                                        }
                                    } else if let url = URL(string: imageURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                    }
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 100))
                                        .foregroundColor(.secondary)
                                }
                                
                                Circle()
                                    .fill(Color.black.opacity(0.4))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text("プロフィール写真を変更")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 20)
                    
                    // 名前入力
                    VStack(alignment: .leading, spacing: 8) {
                        Text("表示名")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("名前を入力", text: $displayName)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                            .onChange(of: displayName) { newValue in
                                // 10文字以内に制限
                                if newValue.count > 10 {
                                    displayName = String(newValue.prefix(10))
                                }
                            }
                        
                        // 文字数表示
                        HStack {
                            Spacer()
                            Text("\(displayName.count)/10")
                                .font(.caption)
                                .foregroundColor(displayName.count > 8 ? .red : .secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 自己紹介入力
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("自己紹介")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(bio.count)/150")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        TextEditor(text: $bio)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .disableAutocorrection(true)
                            .onChange(of: bio) { newValue in
                                if newValue.count > 150 {
                                    bio = String(newValue.prefix(150))
                                }
                            }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveProfile()
                    }
                    .disabled(displayName.isEmpty || isUploading)
                    .fontWeight(.semibold)
                }
            }
            .overlay {
                if isUploading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView("アップロード中...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(selectedImage: $selectedImage)
        }
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("了解") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // 現在のプロフィールデータを即座に反映
            if let profile = profileViewModel.userProfile {
                displayName = profile.displayName
                bio = profile.bio
            } else {
                // プロフィールがない場合は新規作成の準備
                displayName = ""
                bio = ""
            }
        }
    }
    
    private func saveProfile() {
        // ユーザーがログインしているか確認
        guard Auth.auth().currentUser?.isAnonymous == false else {
            errorMessage = "ログインが必要です"
            showingErrorAlert = true
            return
        }
        
        isUploading = true
        
        // プロフィールが存在しない場合は新規作成
        if profileViewModel.userProfile == nil {
            guard let uid = Auth.auth().currentUser?.uid else {
                isUploading = false
                errorMessage = "ユーザー情報を取得できませんでした"
                showingErrorAlert = true
                return
            }
            profileViewModel.userProfile = UserProfile(uid: uid)
        }
        
        // プロフィール情報を一括更新
        profileViewModel.userProfile?.displayName = displayName
        profileViewModel.userProfile?.bio = bio
        
        // 画像が選択されている場合
        if let selectedImage = selectedImage {
            // 🚨 PRODUCTION FIX: 画像サイズを厳しく制限
            let maxSizeKB = 30 // 30KB制限（厳格）
            
            // 段階的に圧縮して最適サイズを見つける
            var compressionQuality: CGFloat = 0.05 // さらに低品質から開始
            var imageData: Data? = nil
            
            repeat {
                imageData = selectedImage.jpegData(compressionQuality: compressionQuality)
                guard let data = imageData else { break }
                if data.count <= maxSizeKB * 1024 {
                    break
                }
                compressionQuality -= 0.01
            } while compressionQuality > 0.01
            
            guard let finalImageData = imageData else {
                print("ERROR: Failed to compress image")
                errorMessage = "画像の処理に失敗しました。"
                showingErrorAlert = true
                return
            }
            
            if finalImageData.count <= maxSizeKB * 1024 {
                let sizeKB = finalImageData.count / 1024
                print("📊 Optimized profile image: \(sizeKB)KB")
                
                // 🚨 WARNING: Still using Base64 - needs Firebase Storage
                let base64String = finalImageData.base64EncodedString()
                let dataURL = "data:image/jpeg;base64,\(base64String)"
                profileViewModel.userProfile?.profileImageURL = dataURL
            } else {
                print("ERROR: Profile image too large, skipping")
                errorMessage = "画像サイズが大きすぎます。別の画像を選択してください。"
                showingErrorAlert = true
                return
            }
        }
        
        // 保存実行
        profileViewModel.saveUserProfile { success in
            DispatchQueue.main.async {
                isUploading = false
                if success {
                    dismiss()
                } else {
                    errorMessage = "プロフィールの保存に失敗しました。もう一度お試しください。"
                    showingErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    ProfileEditView(profileViewModel: ProfileViewModel())
}