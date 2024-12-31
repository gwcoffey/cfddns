import Foundation

func promptForSecret(prompt: String) -> String? {
    if let secret = getpass("\(prompt): ") {
        let secretString = String(cString: secret)
        return secretString == "" ? nil : secretString
    }
    return nil
}

func die(message: String, code: Int32) -> Never {
    fputs("Error: \(message)\n", stderr)
    exit(code)
}
