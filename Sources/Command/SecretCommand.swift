import Foundation
import ArgumentParser

struct SecretCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "secret",
        abstract: "Manage the CloudFlare secret.")
    
    @OptionGroup var globalOptions: GlobalOptions
    
    @Flag(name: .shortAndLong, help: "Delete saved secrets.")
    var delete: Bool = false
    
    mutating func run() async throws {        
        globalOptions.apply()
        
        if delete {
            try deleteCloudflareSecret()
        }
        else {
            let secret = try promptForSecret(prompt: "Enter your Cloudflare API key")
            try storeCloudflareSecret(secret)
        }
    }
}
