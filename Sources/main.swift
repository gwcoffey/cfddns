import Foundation

struct IP: Decodable {
    let ip: String
}

defer { exit(0) }

do {
	let ip = try await myIp()
	print(ip)
	var secret = try cloudflareSecret()
	if secret == nil {
		print("need to store secret")
        secret = try promptForCloudflareSecret()
	}
	print("secret: \(secret!)")
}
catch IPFetcherError.invalidResponse(let data) {
	die(message: "invalid response from IPify service: \(data)", code: 1)
}
catch IPFetcherError.networkError(let error) {
	die(message: "Error: network request failed with error: \(error)", code: 2)
}
catch IPFetcherError.unexpectedInvalidUrl(let urlString) {
	die(message: "Error: invalid URL: \(urlString)", code: 3)
}
catch {
	die(message: "Unexpected error: \(error)", code: -1)
}

func die(message: String, code: Int32) {
	fputs(message, stderr)
	exit(code)
}

enum IPFetcherError: Error {
	case unexpectedInvalidUrl(String)
	case invalidResponse(String)
	case networkError(Error)
}

func myIp() async throws -> String {
	let urlString = "https://api.ipify.org/?format=json"
	guard let url = URL(string: urlString) else {
		throw IPFetcherError.unexpectedInvalidUrl(urlString)
	}
	
	do {
		let (data, _) = try await URLSession.shared.data(from: url)
		if let ip = try? JSONDecoder().decode(IP.self, from: data) {
			return ip.ip
		} else {
			throw IPFetcherError.invalidResponse(String(decoding: data, as: UTF8.self))
		}
	} catch {
		throw IPFetcherError.networkError(error)
	}
}

enum SecretError: Error {
	case keychainError(status: OSStatus)
	case invalidInput
}
func cloudflareSecret() throws -> String? {
	let query: [CFString: Any] = [
		   kSecClass: kSecClassGenericPassword,
		   kSecAttrService: "cloudflare-token",
		   kSecReturnData: true,
		   kSecMatchLimit: kSecMatchLimitOne
	   ]
	var result: AnyObject?
	let status = SecItemCopyMatching(query as CFDictionary, &result)
		if status == errSecSuccess, let data = result as? Data, let secret = String(data: data, encoding: .utf8) {
			return secret
		} else if status == errSecItemNotFound {
			return nil
		} else {
			throw SecretError.keychainError(status: status)
		}
}

func promptForCloudflareSecret() throws -> String? {
	if let secret = getpass("Enter your Cloudflare token: ") {
        let secretString = String(cString: secret)
        try storeCloudflareSecret(secretString)
		return secretString
	}
	return nil
}
    
func storeCloudflareSecret(_ secret: String) throws {
    let query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: "cloudflare-token",
        kSecAttrAccount: "cloudflare-token",
        kSecValueData: secret.data(using: .utf8)!
    ]
    
    SecItemDelete(query as CFDictionary)
    let status = SecItemAdd(query as CFDictionary, nil)
    if status != errSecSuccess {
        throw SecretError.keychainError(status: status)
    }
}
