import SwiftUI
import Security

// MARK: - Saved Credentials Helper (Keychain for password, UserDefaults for email)
enum SavedCredentials {

    private static let rememberKey = "rememberMeEnabled"
    private static let emailKey = "rememberedEmail"
    private static let keychainAccount = "stagetimepnw.login.password"

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: rememberKey)
    }

    static var savedEmail: String {
        UserDefaults.standard.string(forKey: emailKey) ?? ""
    }

    static var savedPassword: String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else { return "" }
        return password
    }

    static func save(email: String, password: String) {
        UserDefaults.standard.set(true, forKey: rememberKey)
        UserDefaults.standard.set(email, forKey: emailKey)

        let passwordData = Data(password.utf8)
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount
        ]
        // Delete any existing entry, then add fresh
        SecItemDelete(baseQuery as CFDictionary)
        var addQuery = baseQuery
        addQuery[kSecValueData as String] = passwordData
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func clear() {
        UserDefaults.standard.set(false, forKey: rememberKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
}

struct LoginView: View {
    
    @EnvironmentObject var authManager: AuthManager
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showPassword: Bool = false
    @State private var rememberMe: Bool = false
    
    var body: some View {
        
        ZStack {
            
            // Background: Misty forest/mountain aesthetic
            LinearGradient(
                colors: [
                    Color(red: 0.42, green: 0.53, blue: 0.51),
                    Color(red: 0.28, green: 0.38, blue: 0.38),
                    Color(red: 0.18, green: 0.25, blue: 0.26)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Optional: Add a subtle pattern overlay
            Color.black.opacity(0.05)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                
                VStack(spacing: 0) {
                    
                    Spacer(minLength: 80)
                    
                    // MARK: - Title
                    
                    Text("Sign in")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)  // Already white!
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                        .accessibilityIdentifier("signin_header_title")
                    
                    // MARK: - Input Fields
                    
                    VStack(spacing: 16) {
                        
                        // Email Field with Custom White Placeholder
                        ZStack(alignment: .leading) {
                            if email.isEmpty {
                                Text("Email")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.system(size: 15))
                                    .padding(.horizontal, 20)
                            }
                            TextField("", text: $email)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textContentType(.emailAddress)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .accessibilityIdentifier("signin_email_input")
                        }
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        
                        // Password Field with Custom White Placeholder
                        ZStack(alignment: .leading) {
                            if password.isEmpty && !showPassword {
                                Text("Password")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.system(size: 15))
                                    .padding(.horizontal, 20)
                            }
                            
                            HStack {
                                Group {
                                    if showPassword {
                                        TextField("", text: $password)
                                            .textContentType(.password)
                                    } else {
                                        SecureField("", text: $password)
                                            .textContentType(.password)
                                    }
                                }
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .accessibilityIdentifier("signin_password_input")
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye" : "eye.slash")
                                        .foregroundColor(.white.opacity(0.6))
                                        .font(.system(size: 16))
                                }
                                .accessibilityIdentifier("signin_password_toggle_button")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        
                        // Remember Me + Forgot Password
                        HStack {
                            Button(action: { rememberMe.toggle() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 18))
                                        .foregroundColor(rememberMe ? Color(red: 0.65, green: 0.78, blue: 0.73) : .white.opacity(0.6))
                                    Text("Remember me")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .accessibilityIdentifier("signin_remember_me_toggle")

                            Spacer()

                            Button(action: {}) {
                                Text("Forgot password?")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .accessibilityIdentifier("signin_forgot_password_button")
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 32)
                    
                    // MARK: - Error Message
                    
                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 16)
                    }
                    
                    // MARK: - Sign In Button
                    
                    Button(action: handleLogin) {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        } else {
                            Text("Sign in")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.18, green: 0.25, blue: 0.26))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                    .background(
                        Color(red: 0.65, green: 0.78, blue: 0.73)
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    .disabled(isSubmitting)
                    .accessibilityIdentifier("signin_submit_button")
                    
                    // Privacy Policy Text
                    Text("By registration process, you accept our Privacy Policy\nand Terms of Service")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 16)
                    
                    // MARK: - Divider
                    
                    HStack(spacing: 16) {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 32)
                    
                    // MARK: - Social Login Buttons
                    
                    VStack(spacing: 12) {
                        
                        // Google Button
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 20))
                                Text("Continue with Google")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .accessibilityIdentifier("signin_google_button")
                        
                        // Apple Button
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 20))
                                Text("Continue with Apple")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .accessibilityIdentifier("signin_apple_button")
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    
                    // MARK: - Sign Up Link
                    
                    Spacer(minLength: 40)
                    
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                        
                        NavigationLink(destination: SignUpView().environmentObject(authManager)) {
                            Text("Sign up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .accessibilityIdentifier("signin_to_signup_link")
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: loadSavedCredentials)
    }

    // MARK: - Load Saved Credentials

    private func loadSavedCredentials() {
        guard SavedCredentials.isEnabled else { return }
        rememberMe = true
        if email.isEmpty { email = SavedCredentials.savedEmail }
        if password.isEmpty { password = SavedCredentials.savedPassword }
    }
    
    // MARK: - Handle Login
    
    private func handleLogin() {
        
        authManager.errorMessage = nil
        
        let cleanEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        guard !cleanEmail.isEmpty else {
            authManager.errorMessage = "Please enter your email address."
            return
        }
        
        guard !password.isEmpty else {
            authManager.errorMessage = "Please enter your password."
            return
        }
        
        isSubmitting = true
        
        Task {
            
            do {
                
                try await authManager.signIn(
                    email: cleanEmail,
                    password: password
                )
                
                // Persist or clear credentials based on the checkbox
                if authManager.isAuthenticated {
                    if rememberMe {
                        SavedCredentials.save(email: cleanEmail, password: password)
                    } else {
                        SavedCredentials.clear()
                    }
                }
                
                // If login succeeds, StageTimePNWApp.swift
                // will automatically switch to ContentView
                
            } catch {
                
                // AuthManager already handles error messages
                
            }
            
            isSubmitting = false
        }
    }
}
