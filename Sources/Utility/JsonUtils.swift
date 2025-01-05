import Foundation

enum JsonUtilsError: Error, CustomStringConvertible {
    case invalidResponse(Error, String)
    
    var description: String {
        switch self {
        case .invalidResponse(let error, let body):
            return "Unexpectedly unable to parse response from Cloudflare. Body:\n\n\(body)\n\nError:\n\n\(error)"
        }
    }
}

func decodeJson<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
    do {
        return try JSONDecoder().decode(type, from: data)
    } catch let decodingError as DecodingError {
        throw JsonUtilsError.invalidResponse(
            decodingError, String(data: data, encoding: .utf8) ?? "<unknown>")
    }
}
