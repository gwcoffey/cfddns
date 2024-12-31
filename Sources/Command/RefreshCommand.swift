import Foundation
import ArgumentParser

struct RefreshCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "refresh",
        abstract: "Update CloudFlare DNS with your current IP address.")
    
    mutating func run() async throws {
        do {
            let ip = try await lookupIp()
            print(ip)
        } catch IpUtilsError.invalidResponse {
            die(message: "received an invalid response from ipify.org", code: -1)
        } catch IpUtilsError.networkError(let error) {
            die(message: "network error calling ipify.org: \(error)", code: -1)
        }
    }
}
