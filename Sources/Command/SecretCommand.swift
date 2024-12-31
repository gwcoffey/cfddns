import Foundation
import ArgumentParser

struct SecretCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "secret",
        abstract: "Manage the CloudFlare secret.")
    
    @Flag(name: .shortAndLong, help: "Delete saved secrets.")
    var delete: Bool = false

    mutating func run() async throws {
        if delete {
            try deleteCloudflareSecret()
        }
        else {
            guard let secret = promptForSecret(prompt: "Enter your Cloudflare API key") else {
                die(message: "No secret provided", code: -1)
            }
            try storeCloudflareSecret(secret)
        }
    }
}
