import Foundation
import ArgumentParser

struct RefreshCommand: BaseCommand {
    @OptionGroup var commonOptions: CommonOptions
    @OptionGroup var cfRecordOptions: CloudflareRecordOptions

    static let configuration = CommandConfiguration(
        commandName: "refresh",
        abstract: "Update CloudFlare DNS with your current IP address.")
    
    func runCommand() async throws {
        let ip = try await lookupIp()
        try await updateARecord(
            zoneName: cfRecordOptions.zone,
            recordName: cfRecordOptions.name,
            ipAddress: ip,
            token: commonOptions.cloudflareToken)
    }
}
