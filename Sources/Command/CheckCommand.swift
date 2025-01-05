import Foundation
import ArgumentParser

enum CheckError: Error, CustomStringConvertible {
    case ipMismatch(current: String, configured: String)
    
    var description: String {
        switch self {
        case .ipMismatch(let current, let configured):
            return "Configured IP is \(configured), but current IP is \(current)"
        }
    }

}

struct CheckCommand: AsyncParsableCommand {
    @OptionGroup var globalOptions: GlobalOptions
    @OptionGroup var cfRecordOptions: CloudflareRecordOptions

    static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Check the DNS record configuration.")
    
    mutating func run() async throws {
        globalOptions.apply()
        
        let (currentIp, configuredIp) = try await (
            lookupIp(),
            getARecordIp(zoneName: cfRecordOptions.zone, recordName: cfRecordOptions.name)
        )
        
        if currentIp == configuredIp {
            print("OK")
        } else {
            throw CheckError.ipMismatch(current: currentIp, configured: configuredIp)
        }
    }
}
