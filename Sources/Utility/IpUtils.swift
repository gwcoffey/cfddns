import Foundation
import Logging

private let ipifyApiUrl = URL(string: "https://api.ipify.org/?format=json")!
private let logger = Logger(label: "com.gwcoffey.cfddns.IpUtils")

private struct IpResponse: Decodable {
    let ipAddress: String

    enum CodingKeys: String, CodingKey {
        case ipAddress = "ip"
    }
}

func lookupIp() async throws -> String {
    logger.info("Call: \(ipifyApiUrl.absoluteString)")
    let (data, _) = try await URLSession.shared.data(from: ipifyApiUrl)
    let response = try decodeJson(IpResponse.self, from: data)
    return response.ipAddress
}
