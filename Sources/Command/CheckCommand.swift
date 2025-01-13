import Foundation
import ArgumentParser

enum CheckCommandError: Error, CustomStringConvertible {
    case ipMismatch(current: String, configured: String)
    
    var description: String {
        switch self {
        case .ipMismatch(let current, let configured):
            return "Configured IP is \(configured), but current IP is \(current)"
        }
    }
}

struct CheckCommand: BaseCommand {
    @OptionGroup var commonOptions: CommonOptions
    @OptionGroup var cfRecordOptions: CloudflareRecordOptions

    static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Check the DNS record configuration.")
    
    func runCommand() async throws {
        let cfapi = CloudflareApi(token: commonOptions.cloudflareToken)
        let (currentIp, configuredIp) = try await (
            lookupIp(),
            cfapi.getARecordIp(zoneName: cfRecordOptions.zone, recordName: cfRecordOptions.name)
        )
        
        if currentIp == configuredIp {
            print("OK")
        } else {
            throw CheckCommandError.ipMismatch(current: currentIp, configured: configuredIp)
        }
    }
}
