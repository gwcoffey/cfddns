import ArgumentParser
import Logging
import Foundation

private let tokenEnvVarName = "CLOUDFLARE_API_TOKEN"

enum CommonError: Error, CustomStringConvertible {
    case missingCloudflareToken

    var description: String {
        switch self {
        case .missingCloudflareToken:
            return "A Cloudflare API token is expected in environemnt variable \(tokenEnvVarName) but none was provided"
        }
    }
}

// common options applied to all commands
public struct CommonOptions: ParsableCommand {
    @Flag(name: .shortAndLong, help: "Use verbose logging.")
    var verbose = false

    func cloudflareToken() throws -> String {
        guard let value = ProcessInfo.processInfo.environment[tokenEnvVarName] else {
            throw CommonError.missingCloudflareToken
        }
        return value
    }

    public init() {
    }
}

// a set of options for specifying a DNS record
struct CloudflareRecordOptions: ParsableArguments {
    @Argument(help: "The Cloudflare zone name (eg, 'example.com').")
    var zone: String

    @Argument(help: "The full record name (eg, 'host.example.com').")
    var name: String
}

public protocol BaseCommand: AsyncParsableCommand {
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
