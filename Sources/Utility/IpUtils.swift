import Foundation

fileprivate let IPIFY_API_ENDPOINT = URL(string: "https://api.ipify.org/?format=json")!

struct IP: Decodable {
    let ip: String
}

enum IpUtilsError: Error {
    case invalidResponse(String)
    case networkError(Error)
}

func lookupIp() async throws -> String {
    do {
        let (data, _) = try await URLSession.shared.data(from: IPIFY_API_ENDPOINT)
        if let ip = try? JSONDecoder().decode(IP.self, from: data) {
            return ip.ip
        } else {
            throw IpUtilsError.invalidResponse(String(decoding: data, as: UTF8.self))
        }
    } catch {
        throw IpUtilsError.networkError(error)
    }
}

