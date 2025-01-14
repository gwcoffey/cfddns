import Foundation
import ArgumentParser

struct RefreshCommand: BaseCommand {
    @OptionGroup var commonOptions: CommonOptions
    @OptionGroup var cfRecordOptions: CloudflareRecordOptions

    static let configuration = CommandConfiguration(
        commandName: "refresh",
        abstract: "Update CloudFlare DNS with your current IP address.")

    func runCommand() async throws {
        let cfapi = CloudflareApi(token: try commonOptions.cloudflareToken())
        let (currentIp, configuredIp) = try await (
            lookupIp(),
            cfapi.getARecordIp(zoneName: cfRecordOptions.zone, recordName: cfRecordOptions.name)
        )
        
        if currentIp != configuredIp {
            try await cfapi.updateARecord(
                zoneName: cfRecordOptions.zone,
                recordName: cfRecordOptions.name,
                ipAddress: currentIp)
        }
    }
}
