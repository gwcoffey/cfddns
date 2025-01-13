import Foundation
import ArgumentParser
import Logging

let TOKEN_ENV_VAR = "CLOUDFLARE_API_TOKEN"

enum CfddnsError: Error, CustomStringConvertible {
    case missingCloudflareToken

    // CHECK command
    case ipMismatch(current: String, configured: String)

    var description: String {
        switch self {
        case .missingCloudflareToken:
            return "A Cloudflare API token is expected in environemnt variable \(TOKEN_ENV_VAR) but none was provided"
        case .ipMismatch(let current, let configured):
            return "Configured IP is \(configured), but current IP is \(current)"
        }
    }
}

@main struct Cfddns: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Dynaminc DNS tool for CloudFlare.",
        subcommands: [RefreshCommand.self, CheckCommand.self],
        defaultSubcommand: RefreshCommand.self)
}

