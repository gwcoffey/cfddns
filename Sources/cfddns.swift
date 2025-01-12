import Foundation
import ArgumentParser
import Logging

fileprivate let TOKEN_ENV_VAR = "CLOUDFLARE_API_TOKEN"

enum CfddnsError: Error, CustomStringConvertible {
    case noToken
    
    var description: String {
        switch self {
        case .noToken:
            return "A Cloudflare API token is expected in environemnt variable \(TOKEN_ENV_VAR) but none was provided"
        }
    }

}

@main struct Cfddns: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Dynaminc DNS tool for CloudFlare.",
        subcommands: [RefreshCommand.self, CheckCommand.self],
        defaultSubcommand: RefreshCommand.self)
}

struct GlobalOptions: ParsableArguments {
    @Flag(name: .shortAndLong, help: "Use verbose logging.")
    var verbose = false
    
    var token = ""
    
    mutating func apply() throws {
        let copy = self
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardError(label: label)
            handler.logLevel = copy.verbose ? .info : .error
            return handler
        }
        
        guard let myToken = ProcessInfo.processInfo.environment[TOKEN_ENV_VAR] else {
            throw CfddnsError.noToken
        }
        
        token = myToken
    }
}

struct CloudflareRecordOptions: ParsableArguments {
    @Argument(help: "The Cloudflare zone name (eg, 'example.com').")
    var zone: String

    @Argument(help: "The full record name (eg, 'host.example.com').")
    var name: String
}
