import Foundation
import ArgumentParser

enum InstallError: Error, CustomStringConvertible {
    case inputError

    var description: String {
        switch self {
        case .inputError:
            return "Unexpected input"
        }
    }
}

struct LaunchDaemon: Codable {
    var label = "com.gwcoffey.cfddns"
    var runAtLoad = true
    
    var userName: String
    var programArguments: [String]
    var startInterval: Int
    var standardOutPath: String
    var standardErrorPath: String
    
    enum CodingKeys: String, CodingKey {
        case label = "Label"
        case runAtLoad = "RunAtLoad"
        case userName = "UserName"
        case programArguments = "ProgramArguments"
        case startInterval = "StartInterval"
        case standardOutPath = "StandardOutPath"
        case standardErrorPath = "StandardErrorPath"
    }

}

struct InstallCommand: BaseCommand {
    @OptionGroup var commonOptions: CommonOptions

    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install as a launch daemon.")

    func runCommand() async throws {
        print("Configuring Launch Daemon. Press enter to accept defaults, or provide overrides.")
        
        let username = try prompt(
            for: "Run as user",
            default: ProcessInfo.processInfo.environment["USER"] ?? "root")
        let startInterval = try prompt(
            for: "Run frequency (in seconds)",
            default: 600,
            receive: { Int($0) })
        let logPath = try prompt(
            for: "Log directory",
            default: "/var/log")
        let zoneName = try prompt(
            for: "Cloudflare zone name",
            receive: { $0.isEmpty ? nil : $0 })
        let recordName = try prompt(
            for: "Cloudflare DNS record name",
            receive: { $0.isEmpty ? nil : $0 })

        let plist = LaunchDaemon(
            userName: username,
            programArguments: [
                "/bin/sh",
                "-c"
                "CLOUDFLARE_API_TOKEN=$(cat /etc/cloudflare/api_token) /usr/bin/cfddns refresh \(zoneName) \(recordName)"
            ],
            startInterval: startInterval,
            standardOutPath: logPath,
            standardErrorPath: logPath)

        // create log files
        print("creating log files...", terminator: "")
        
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let data = try encoder.encode(plist)
        print(String(data: data, encoding: .utf8) ?? "")
    }
}

func prompt(for message: String, default defaultValue: String? = nil) throws -> String {
    return try prompt(for: message, default: defaultValue, receive: { $0 })
}

func prompt<T>(
    for message: String,
    default defaultValue: T? = nil,
    receive: (String) -> T?
) throws -> T {
    if let defaultValue = defaultValue {
        print("  \u{001B}[1m\(message)\u{001B}[0m [\(defaultValue)]: ", terminator: "")
    } else {
        print("  \u{001B}[1m\(message)\u{001B}[0m: ", terminator: "")
    }

    while true {
        if let input = readLine() {
            if let defaultValue = defaultValue, input.isEmpty {
                return defaultValue
            }
            if let result = receive(input) {
                return result
            } else {
                print("    Invalid input, try again: ", terminator: "")
            }
        } else {
            throw InstallError.inputError
        }
    }
}
