import Foundation

fileprivate let KEYCHAIN_CLOUDFLARE_SERVICE_NAME = "com.gwcoffey.cfddns.CloudflareApiKey"

enum SecretError: Error {
    case secretNotFound
    case keychainError(status: OSStatus)
}

func readCloudflareSecret() throws -> String {
    let query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: KEYCHAIN_CLOUDFLARE_SERVICE_NAME,
        kSecReturnData: true,
        kSecMatchLimit: kSecMatchLimitOne
    ]
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    if status == errSecSuccess, let data = result as? Data, let secret = String(data: data, encoding: .utf8) {
        return secret
    } else if status == errSecItemNotFound {
        throw SecretError.secretNotFound
    } else {
        throw SecretError.keychainError(status: status)
    }
}
    
func storeCloudflareSecret(_ secret: String) throws {
    let query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: KEYCHAIN_CLOUDFLARE_SERVICE_NAME,
        kSecValueData: secret.data(using: .utf8)!
    ]
    
    let deleteStatus = SecItemDelete(query as CFDictionary)
    if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
        throw SecretError.keychainError(status: deleteStatus)
    }
    
    let addStatus = SecItemAdd(query as CFDictionary, nil)
    if addStatus != errSecSuccess {
        throw SecretError.keychainError(status: addStatus)
    }
}

func deleteCloudflareSecret() throws {
    let query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: KEYCHAIN_CLOUDFLARE_SERVICE_NAME,
    ]
    
    let status = SecItemDelete(query as CFDictionary)
    if status != errSecSuccess && status != errSecItemNotFound {
        throw SecretError.keychainError(status: status)
    }
}
