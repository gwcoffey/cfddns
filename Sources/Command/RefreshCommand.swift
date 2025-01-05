import Foundation
import ArgumentParser

struct RefreshCommand: AsyncParsableCommand {
    @OptionGroup var globalOptions: GlobalOptions
    @OptionGroup var cfRecordOptions: CloudflareRecordOptions

    static let configuration = CommandConfiguration(
        commandName: "refresh",
        abstract: "Update CloudFlare DNS with your current IP address.")
    
    mutating func run() async throws {
        globalOptions.apply()

        let ip = try await lookupIp()
        try await updateARecord(
            zoneName: cfRecordOptions.zone,
            recordName: cfRecordOptions.name,
            ipAddress: ip)
    }
}
