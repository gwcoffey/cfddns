/*
 cfddns -> prompts for secret and uses it
 cfddns --save-secret -> prompts for secret and stores it
 cfddns --keychain -> reads secret from keychain
 */

import Foundation
import ArgumentParser

@main struct Cfddns: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Dynaminc DNS tool for CloudFlare.",
        subcommands: [RefreshCommand.self, SecretCommand.self],
        defaultSubcommand: RefreshCommand.self)
}

//do {
//    let ip = try await myIp()
//    print(ip)
//    var secret = try cloudflareSecret()
//    if secret == nil {
//        print("need to store secret")
//        secret = try promptForCloudflareSecret()
//    }
//    print("secret: \(secret!)")
//}
//catch IPFetcherError.invalidResponse(let data) {
//    die(message: "invalid response from IPify service: \(data)", code: 1)
//}
//catch IPFetcherError.networkError(let error) {
//    die(message: "Error: network request failed with error: \(error)", code: 2)
//}
//catch IPFetcherError.unexpectedInvalidUrl(let urlString) {
//    die(message: "Error: invalid URL: \(urlString)", code: 3)
//}
//catch {
//    die(message: "Unexpected error: \(error)", code: -1)
//}

