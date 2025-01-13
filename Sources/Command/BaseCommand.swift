import ArgumentParser
import Logging
import Foundation

// common options applied to all commands
public struct CommonOptions: ParsableCommand {
    @Flag(name: .shortAndLong, help: "Use verbose logging.")
    var verbose = false

    var cloudflareToken = ""
    
    public init() {
        cloudflareToken = ProcessInfo.processInfo.environment[TOKEN_ENV_VAR] ?? ""
    }
    
    public mutating func validate() throws {
        if cloudflareToken.isEmpty {
            throw CfddnsError.missingCloudflareToken
        }
    }

}

// a set of options for specifying a DNS record
struct CloudflareRecordOptions: ParsableArguments {
    @Argument(help: "The Cloudflare zone name (eg, 'example.com').")
    var zone: String

    @Argument(help: "The full record name (eg, 'host.example.com').")
    var name: String
}


public protocol BaseCommand : AsyncParsableCommand {
    var commonOptions: CommonOptions { get }
    func runCommand() async throws
}

extension BaseCommand {
    public func run() async throws {
        let logLevel: Logger.Level = commonOptions.verbose ? .info : .error
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardError(label: label)
            handler.logLevel = logLevel
            return handler
        }
        
        try await self.runCommand()
    }
}
