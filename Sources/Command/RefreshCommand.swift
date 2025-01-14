import ArgumentParser
import Foundation
import Logging

private let logger = Logger(label: "com.gwcoffey.cfddns.RefreshCommand")

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

        if currentIp == configuredIp {
            logger.info(
                Logger.Message(stringLiteral:
                               "record \(cfRecordOptions.name) " +
                               "in zone \(cfRecordOptions.zone) " +
                               "has ip \(configuredIp) which matches current ip"))
        } else {
            logger.notice(
                Logger.Message(stringLiteral:
                               "updating record \(cfRecordOptions.name) " +
                               "in zone \(cfRecordOptions.zone) " +
                               "from \(configuredIp) to \(currentIp)"))
            try await cfapi.updateARecord(
                zoneName: cfRecordOptions.zone,
                recordName: cfRecordOptions.name,
                ipAddress: currentIp)
        }
    }
}
