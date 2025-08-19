import SwiftUI
import FirebaseAuth
import UIKit

struct AuthenticationView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @Environment(\.dismiss) var dismiss
    
    // Apple/Google Sign-In
    @StateObject private var appleSignInManager = AppleSignInManager()
    @StateObject private var googleSignInManager = GoogleSignInManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // アプリロゴ・タイトル
                VStack(spacing: 8) {
                    Text("💬")
                        .font(.system(size: 60))
                    Text("エミネンス")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(isSignUp ? "アカウントを作成" : "ログイン")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // 入力フォーム
                VStack(spacing: 16) {
                    // メールアドレス入力
                    TextField("メールアドレス", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                    
                    // パスワード入力フィールド（表示切り替え付き）
                    ZStack(alignment: .trailing) {
                        if showPassword {
                            TextField("パスワード", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("パスワード", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.password)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.secondary)
                                .padding(.trailing, 8)
                        }
                    }
                    
                    // パスワード確認フィールド（サインアップ時のみ）
                    if isSignUp {
                        ZStack(alignment: .trailing) {
                            if showConfirmPassword {
                                TextField("パスワード（確認）", text: $confirmPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("パスワード（確認）", text: $confirmPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .textInputAutocapitalization(.never)
                            }
                            
                            Button(action: {
                                showConfirmPassword.toggle()
                            }) {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.secondary)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                
                // メインボタン
                Button(action: {
                    if isSignUp {
                        signUp()
                    } else {
                        signIn()
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isSignUp ? "アカウント作成" : "ログイン")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(email.isEmpty || password.isEmpty || isLoading)
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                // 切り替えボタン
                Button(action: {
                    isSignUp.toggle()
                }) {
                    Text(isSignUp ? "既にアカウントをお持ちの方" : "アカウントをお持ちでない方")
                        .foregroundColor(.blue)
                }
                .padding(.top, 10)
                
                Spacer()
                
                // ソーシャルログイン
                VStack(spacing: 12) {
                    Button(action: {
                        // Apple Sign-In
                        appleSignInManager.onSignInSuccess = {
                            NotificationCenter.default.post(name: NSNotification.Name("UserLoggedIn"), object: nil)
                            dismiss()
                        }
                        appleSignInManager.onSignInError = { error in
                            alertMessage = error
                            showingAlert = true
                        }
                        appleSignInManager.startSignInWithAppleFlow()
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                            Text("Appleでサインイン")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    // Google Sign-In（後日実装予定）
                    // SDKは追加済み、FirebaseConsoleも設定済み
                    // TODO: Xcodeでターゲットへのライブラリリンクが必要
                    // 参照: GoogleSignInManager.swift
                    /*
                    Button(action: {
                        googleSignInManager.signInWithGoogle { success, error in
                            if success {
                                NotificationCenter.default.post(name: NSNotification.Name("UserLoggedIn"), object: nil)
                                dismiss()
                            } else {
                                alertMessage = error ?? "Google Sign-Inに失敗しました"
                                showingAlert = true
                            }
                        }
                    }) {
                        HStack {
                            Text("G")
                                .fontWeight(.bold)
                            Text("Googleでサインイン")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    */
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .alert("エラー", isPresented: $showingAlert) {
            Button("了解") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func signIn() {
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
            } else {
                // ログイン成功後、データをリロード
                NotificationCenter.default.post(name: NSNotification.Name("UserLoggedIn"), object: nil)
                dismiss()
            }
        }
    }
    
    private func signUp() {
        // パスワードの確認
        if password != confirmPassword {
            alertMessage = "パスワードが一致しません"
            showingAlert = true
            return
        }
        
        if password.count < 6 {
            alertMessage = "パスワードは6文字以上にしてください"
            showingAlert = true
            return
        }
        
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                isLoading = false
                alertMessage = error.localizedDescription
                showingAlert = true
            } else {
                // アカウント作成成功後、少し待ってから画面遷移
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoading = false
                    // サインアップ成功後もデータをリロード
                    NotificationCenter.default.post(name: NSNotification.Name("UserLoggedIn"), object: nil)
                    dismiss()
                }
            }
        }
    }
}


#Preview {
    AuthenticationView()
}