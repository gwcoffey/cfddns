import Foundation
import ArgumentParser
import Logging

@main struct Cfddns: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Dynaminc DNS tool for CloudFlare.",
        subcommands: [RefreshCommand.self, CheckCommand.self, SecretCommand.self],
        defaultSubcommand: RefreshCommand.self)
}

struct GlobalOptions: ParsableArguments {
    @Flag(name: .shortAndLong, help: "Use verbose logging.")
    var verbose = false
    
    func apply() {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardError(label: label)
            handler.logLevel = verbose ? .info : .error
            return handler
        }
    }
}

struct CloudflareRecordOptions: ParsableArguments {
    @Argument(help: "The Cloudflare zone name (eg, 'example.com').")
    var zone: String

    @Argument(help: "The full record name (eg, 'host.example.com').")
    var name: String
}
