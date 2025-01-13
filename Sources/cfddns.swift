import Foundation
import ArgumentParser
import Logging

@main struct Cfddns: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Dynaminc DNS tool for CloudFlare.",
        subcommands: [RefreshCommand.self, CheckCommand.self],
        defaultSubcommand: RefreshCommand.self)
}

