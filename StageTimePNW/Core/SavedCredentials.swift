import Foundation
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
