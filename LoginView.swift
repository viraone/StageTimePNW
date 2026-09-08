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
            
            // Background: Beautiful blue/purple mountain aesthetic
            ZStack {
                // Base gradient - Deep blue to purple
                LinearGradient(
                    colors: [
                        Color(red: 0.35, green: 0.45, blue: 0.65), // Soft blue
                        Color(red: 0.25, green: 0.35, blue: 0.55), // Medium blue
                        Color(red: 0.15, green: 0.20, blue: 0.40), // Deep navy
                        Color(red: 0.12, green: 0.15, blue: 0.30)  // Dark navy/purple
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Add depth with radial highlights
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 50,
                    endRadius: 500
                )
                
                // Subtle overlay for texture
                Color.black.opacity(0.15)
            }
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                
                VStack(spacing: 0) {
                    
                    Spacer(minLength: 50)
                    
                    // MARK: - Hero Section
                    
                    VStack(spacing: 16) {
                        
                        Text("STAGE TIME PNW")
                            .font(.system(size: 22, weight: .thin, design: .default))
                            .foregroundColor(.white)
                            .tracking(4)
                    }
                    .padding(.bottom, 40)
                    
                    // MARK: - Form Content
                    
                    VStack(spacing: 24) {
                        
                        // Title
                        Text("Sign in")
                            .font(.system(size: 28, weight: .thin))
                            .foregroundColor(.white)
                    
                        // MARK: - Input Fields
                        
                        VStack(spacing: 14) {
                            
                            // Email Field with Icon
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 20)
                                
                                ZStack(alignment: .leading) {
                                    if email.isEmpty {
                                        Text("Email address")
                                            .foregroundColor(.white.opacity(0.5))
                                            .font(.system(size: 15))
                                    }
                                    TextField("", text: $email)
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .textContentType(.emailAddress)
                                        .accessibilityIdentifier("signin_email_input")
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            
                            // Password Field with Icon
                            HStack(spacing: 12) {
                                Image(systemName: "lock")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 20)
                                
                                ZStack(alignment: .leading) {
                                    if password.isEmpty && !showPassword {
                                        Text("Password")
                                            .foregroundColor(.white.opacity(0.5))
                                            .font(.system(size: 15))
                                    }
                                    
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
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .accessibilityIdentifier("signin_password_toggle_button")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            
                            // Remember Me + Forgot Password
                            HStack {
                                Button(action: { rememberMe.toggle() }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 16))
                                            .foregroundColor(rememberMe ? Color(red: 0.50, green: 0.60, blue: 0.80) : .white.opacity(0.6))
                                        Text("Remember me")
                                            .font(.system(size: 13, weight: .light))
                                            .foregroundColor(.white.opacity(0.75))
                                    }
                                }
                                .accessibilityIdentifier("signin_remember_me_toggle")

                                Spacer()

                                Button(action: {}) {
                                    Text("Forgot password?")
                                        .font(.system(size: 13, weight: .light))
                                        .foregroundColor(.white.opacity(0.75))
                                }
                                .accessibilityIdentifier("signin_forgot_password_button")
                            }
                            .padding(.top, 8)
                        }
                        
                        // MARK: - Error Message
                        
                        if let error = authManager.errorMessage {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red.opacity(0.9))
                                
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.red.opacity(0.95))
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.top, 8)
                        }
                        
                        // MARK: - Sign In Button
                        
                        Button(action: handleLogin) {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                            } else {
                                HStack(spacing: 8) {
                                    Text("Sign in")
                                        .font(.system(size: 17, weight: .medium))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                            }
                        }
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.50, green: 0.60, blue: 0.80), // Soft blue
                                    Color(red: 0.40, green: 0.50, blue: 0.70)  // Medium blue
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color(red: 0.40, green: 0.50, blue: 0.70).opacity(0.4), radius: 10, x: 0, y: 5)
                        .padding(.top, 8)
                        .disabled(isSubmitting)
                        .accessibilityIdentifier("signin_submit_button")
                        
                        // Privacy Policy Text
                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text("By signing in, you accept our Privacy Policy and Terms of Service")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                        
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)
                    
                    // MARK: - Divider
                    
                    HStack(spacing: 16) {
                        Rectangle()
                            .fill(Color.white.opacity(0.25))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.25))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    
                    // MARK: - Social Login Buttons
                    
                    VStack(spacing: 12) {
                        
                        // Google Button
                        Button(action: {}) {
                            HStack(spacing: 10) {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 18))
                                Text("Continue with Google")
                                    .font(.system(size: 15, weight: .light))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .accessibilityIdentifier("signin_google_button")
                        
                        // Apple Button
                        Button(action: {}) {
                            HStack(spacing: 10) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 18))
                                Text("Continue with Apple")
                                    .font(.system(size: 15, weight: .light))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .accessibilityIdentifier("signin_apple_button")
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    
                    // MARK: - Sign Up Link
                    
                    Spacer(minLength: 30)
                    
                    HStack(spacing: 6) {
                        Text("Don't have an account?")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                        
                        NavigationLink(destination: SignUpView().environmentObject(authManager)) {
                            Text("Sign up")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .underline()
                        }
                        .accessibilityIdentifier("signin_to_signup_link")
                    }
                    .padding(.bottom, 50)
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
