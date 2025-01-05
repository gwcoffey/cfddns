import Foundation
import Logging

fileprivate let IPIFY_API_ENDPOINT = URL(string: "https://api.ipify.org/?format=json")!
fileprivate let LOGGER = Logger(label: "com.gwcoffey.cfddns.IpUtils")

fileprivate struct IP: Decodable {
    let ip: String
}

func lookupIp() async throws -> String {
    LOGGER.info("Call: \(IPIFY_API_ENDPOINT.absoluteString)")
    let (data, _) = try await URLSession.shared.data(from: IPIFY_API_ENDPOINT)
    let ip = try decodeJson(IP.self, from: data)
    return ip.ip
}
