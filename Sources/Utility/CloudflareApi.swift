// wraps the relevant Cloudflare APIs

import Foundation
import Logging

private var dateFormatter: DateFormatter {
    let value = DateFormatter()
    value.timeZone = TimeZone(identifier: "UTC")
    value.dateFormat = "yyyy-MM-dd HH:mm:ss UTC"
    return value
}

class CloudflareApi {
    private let token: String

    init(token: String) {
        self.token = token
    }

    func updateARecord(zoneName: String, recordName: String, ipAddress: String) async throws {
        guard let zone = try await cfapiListZones(domain: zoneName).first else {
            throw CloudflareApiError.invalidZoneName(zoneName)
        }
        guard let record = try await cfapiListDnsRecords(zoneId: zone.id, name: recordName).first else {
            throw CloudflareApiError.invalidRecordName(recordName)
        }

        _ = try await cfapiUpdateDnsRecord(
            zoneId: zone.id,
            recordId: record.id,
            ipAddress: ipAddress)
    }

    func getARecordIp(zoneName: String, recordName: String) async throws -> String {
        guard let zone = try await cfapiListZones(domain: zoneName).first else {
            throw CloudflareApiError.invalidZoneName(zoneName)
        }
        guard let record = try await cfapiListDnsRecords(zoneId: zone.id, name: recordName).first else {
            throw CloudflareApiError.invalidRecordName(recordName)
        }

        return record.content
    }

    // private
    private func appendBearerToken(request: inout URLRequest) throws {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    private func cfapiCall<T: Decodable>(url: URL) async throws -> T {
        let request = URLRequest(url: url)
        return try await cfapiCall(request: request)
    }

    private func cfapiCall<T: Decodable>(request: URLRequest) async throws -> T {
        logger.info("Call: \(request)")
        var request = request
        try appendBearerToken(request: &request)
        request.setValue("application/json", forHTTPHeaderField: "Accepts")

        if request.httpBody != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try decodeJson(CFAPIResponse<T>.self, from: data)
        if response.success {
            return response.result!
        } else {
            throw CloudflareApiError.updateFailed(response.errors.map(\.message))
        }
    }

    private func cfapiListZones(domain: String) async throws -> [CFAPIZone] {
        return try await cfapiCall(url: try listZonesUrl(zoneName: domain))
    }

    private func cfapiListDnsRecords(zoneId: String, name: String) async throws -> [CFAPIARecord] {
        return try await cfapiCall(url: try listDnsRecordsUrl(zoneId: zoneId, name: name))
    }

    private func cfapiUpdateDnsRecord(
        zoneId: String,
        recordId: String,
        ipAddress: String
    ) async throws -> CFAPIARecord {
        let stamp = dateFormatter.string(from: Date())
        let payload = CFAPIUpdateARecord.init(
            comment: "updated by cfddns \(stamp)",
            content: ipAddress)

        var request = URLRequest(url: recordUrl(zoneId: zoneId, dnsRecordId: recordId))
        request.httpMethod = "PATCH"
        request.httpBody = try JSONEncoder().encode(payload)
        return try await cfapiCall(request: request)
    }
}

private let cloudflareApiBaseUrl = "https://api.cloudflare.com/client/v4"
private let logger = Logger(label: "com.gwcoffey.cfddns.CloudFlairUtils")

private enum CloudflareApiError: Error, CustomStringConvertible {
    case invalidZoneName(String)
    case invalidRecordName(String)
    case updateFailed([String])

    var description: String {
        switch self {
        case .invalidZoneName(let name):
            return "Your Cloudflare account has no zone named '\(name)'."
        case .invalidRecordName(let name):
            return "This Cloudflare zone has no record named '\(name)'."
        case .updateFailed(let messages):
           let formattedMessages = messages.map { "Cloudflare Message: \($0)"}.joined(separator: "\n")
            return "Unable to update Cloudflare record.\n\(formattedMessages)"
        }
    }
}

// PAYLOADS

private struct CFAPIResponse<T: Decodable>: Decodable {
    let success: Bool
    let errors: [CFAPIMessage]
    let messages: [CFAPIMessage]
    let result: T?
}

private struct CFAPIMessage: Decodable {
    let code: Int
    let message: String
}

private struct CFAPIZone: Decodable {
    let id: String
}

private struct CFAPIARecord: Decodable {
    let id: String
    let content: String
}

private struct CFAPIUpdateARecord: Encodable {
    let comment: String
    let content: String
}

// URLs

private func listZonesUrl(zoneName: String) throws -> URL {
    let str = String(format: "%@/zones?name=%@", cloudflareApiBaseUrl, zoneName)
    guard let url = URL(string: str) else {
        throw CloudflareApiError.invalidZoneName(zoneName)
    }
    return url
}

private func listDnsRecordsUrl(zoneId: String, name: String) throws -> URL {
    let str = String(format: "%@/zones/%@/dns_records?name=%@", cloudflareApiBaseUrl, zoneId, name)
    guard let url = URL(string: str) else {
        throw CloudflareApiError.invalidRecordName(name)
    }
    return url
}

private func recordUrl(zoneId: String, dnsRecordId: String) -> URL {
    let str = String(format: "%@/zones/%@/dns_records/%@", cloudflareApiBaseUrl, zoneId, dnsRecordId)
    return URL(string: str)!
}
