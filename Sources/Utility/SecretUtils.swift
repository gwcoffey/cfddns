import Foundation
import Logging

fileprivate let KEYCHAIN_CLOUDFLARE_SERVICE_NAME = "com.gwcoffey.cfddns.CloudflareApiKey"
fileprivate let LOGGER = Logger(label: "com.gwcoffey.cfddns.SecretUtils")

fileprivate enum SecretError: Error, CustomStringConvertible {
    case secretNotFound
    case keychainError(status: OSStatus)
    
    var description: String {
        switch self {
        case .secretNotFound:
            return "No Cloudflare secret has been stored. Use `cfddns secret` to store your API key first."
        case .keychainError(let status):
            return "An unexpected error occurred while accessing the keychain: \(status)."
        }
    }
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
    
    LOGGER.info("stored secret in keychain")
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
    
    LOGGER.info("deleted stored secret from keychain")
}
