import Foundation
import ArgumentParser

struct CheckCommand: BaseCommand {
    @OptionGroup var commonOptions: CommonOptions
    @OptionGroup var cfRecordOptions: CloudflareRecordOptions

    static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Check the DNS record configuration.")
    
    func runCommand() async throws {
        let (currentIp, configuredIp) = try await (
            lookupIp(),
            getARecordIp(zoneName: cfRecordOptions.zone, recordName: cfRecordOptions.name, token: commonOptions.cloudflareToken)
        )
        
        if currentIp == configuredIp {
            print("OK")
        } else {
            throw CfddnsError.ipMismatch(current: currentIp, configured: configuredIp)
        }
    }
}
