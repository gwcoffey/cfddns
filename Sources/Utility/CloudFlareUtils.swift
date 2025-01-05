// wraps the relevant Cloudflare APIs

import Foundation
import Logging

fileprivate let CLOUDFLARE_API_BASE = "https://api.cloudflare.com/client/v4"
fileprivate let LOGGER = Logger(label: "com.gwcoffey.cfddns.CloudFlairUtils")


// PAYLOADS

fileprivate struct CFAPIResponse<T: Decodable>: Decodable {
    let success: Bool
    let errors: [CFAPIMessage]
    let messages: [CFAPIMessage]
    let result: T?
}

fileprivate struct CFAPIMessage: Decodable {
    let code: Int
    let message: String
}

fileprivate struct CFAPIZone: Decodable {
    let id: String
}

fileprivate struct CFAPIARecord: Decodable {
    let id: String
    let content: String
}

fileprivate struct CFAPIUpdateARecord: Encodable {
    let comment: String
    let content: String
}


// URLs

fileprivate func listZonesUrl(zoneName: String) throws -> URL {
    let str = String(format: "%@/zones?name=%@", CLOUDFLARE_API_BASE, zoneName)
    guard let url = URL(string: str) else {
        throw CloudflareUtilsError.invalidZoneName(zoneName)
    }
    return url
}

fileprivate func listDnsRecordsUrl(zoneId: String, name: String) throws -> URL {
    let str = String(format: "%@/zones/%@/dns_records?name=%@", CLOUDFLARE_API_BASE, zoneId, name)
    guard let url = URL(string: str) else {
        throw CloudflareUtilsError.invalidRecordName(name)
    }
    return url
}

fileprivate func recordUrl(zoneId: String, dnsRecordId: String) -> URL {
    let str = String(format: "%@/zones/%@/dns_records/%@", CLOUDFLARE_API_BASE, zoneId, dnsRecordId)
    return URL(string: str)!
}


// UTILS

fileprivate func appendBearerToken(request: inout URLRequest) throws {
    let secret = try readCloudflareSecret()
    request.setValue("Bearer \(secret)", forHTTPHeaderField: "Authorization")
}

fileprivate func cfapiCall<T: Decodable>(url: URL) async throws -> T {
    let request = URLRequest(url: url)
    return try await cfapiCall(request: request)
}

fileprivate func cfapiCall<T: Decodable>(request: URLRequest) async throws -> T {
    LOGGER.info("Call: \(request)")
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
        throw CloudflareUtilsError.updateFailed(response.errors.map(\.message))
    }
}


// API CALLS

fileprivate func cfapiListZones(domain: String) async throws -> [CFAPIZone] {
    return try await cfapiCall(url: try listZonesUrl(zoneName: domain))
}

fileprivate func cfapiListDnsRecords(zoneId: String, name: String) async throws -> [CFAPIARecord] {
    return try await cfapiCall(url: try listDnsRecordsUrl(zoneId: zoneId, name: name))
}

fileprivate func cfapiUpdateDnsRecord(
    zoneId: String,
    recordId: String,
    ipAddress: String
) async throws -> CFAPIARecord {
    let payload = CFAPIUpdateARecord.init(comment: "updated by cfddns", content: ipAddress)

    var request = URLRequest(url: recordUrl(zoneId: zoneId, dnsRecordId: recordId))
    request.httpMethod = "PATCH"
    request.httpBody = try JSONEncoder().encode(payload)
    return try await cfapiCall(request: request)
}

// EXPORTED

enum CloudflareUtilsError: Error, CustomStringConvertible {
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
           let formattedMessages = messages.map{ "Cloudflare Message: \($0)"}.joined(separator: "\n")
            return "Unable to update Cloudflare record.\n\(formattedMessages)"
        }
    }
}

func updateARecord(zoneName: String, recordName: String, ipAddress: String) async throws {
    guard let zone = try await cfapiListZones(domain: zoneName).first else {
        throw CloudflareUtilsError.invalidZoneName(zoneName)
    }
    guard let record = try await cfapiListDnsRecords(zoneId: zone.id, name: recordName).first else {
        throw CloudflareUtilsError.invalidRecordName(recordName)
    }
    
    let _ = try await cfapiUpdateDnsRecord(
        zoneId: zone.id,
        recordId: record.id,
        ipAddress: ipAddress)
}

func getARecordIp(zoneName: String, recordName: String) async throws -> String {
    guard let zone = try await cfapiListZones(domain: zoneName).first else {
        throw CloudflareUtilsError.invalidZoneName(zoneName)
    }
    guard let record = try await cfapiListDnsRecords(zoneId: zone.id, name: recordName).first else {
        throw CloudflareUtilsError.invalidRecordName(recordName)
    }
    
    return record.content
}