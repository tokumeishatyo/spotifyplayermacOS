// rule.mdを読むこと
import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    
    private let service = "com.spotifymanager.spotifyplayer"
    
    func save(_ data: Data, service: String, account: String) {
        // Create query
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as [CFString : Any]
        
        // Add data in query to keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Item already exists, thus update it.
            let query = [
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecClass: kSecClassGenericPassword
            ] as [CFString : Any]
            
            let attributesToUpdate = [kSecValueData: data] as [CFString : Any]
            
            SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        }
    }
    
    func read(service: String, account: String) -> Data? {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as [CFString : Any]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        
        return result as? Data
    }
    
    func delete(service: String, account: String) {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword
        ] as [CFString : Any]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Convenience Methods for Strings
    
    func save(_ value: String, key: String) {
        if let data = value.data(using: .utf8) {
            save(data, service: service, account: key)
        }
    }
    
    func read(key: String) -> String? {
        guard let data = read(service: service, account: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func delete(key: String) {
        delete(service: service, account: key)
    }
}
