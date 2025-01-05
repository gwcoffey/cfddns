import Foundation

fileprivate enum CliUtilsErrors: Error, CustomStringConvertible {
    case noSecretProvided
    
    var description: String {
        switch self {
        case .noSecretProvided:
            return "No secret was provided"
        }
    }
}

func promptForSecret(prompt: String) throws -> String {
    if let secret = getpass("\(prompt): ") {
        let secretString = String(cString: secret)
        if secretString != "" {
            return secretString
        }
    }
    throw CliUtilsErrors.noSecretProvided
}

