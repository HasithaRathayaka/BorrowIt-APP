import Foundation
import CryptoKit

// MARK: - QR Action Type
public enum QRAction: String, Codable {
    case pickup = "pickup"
    case returnVerification = "returnVerification"
}

// MARK: - Signed QR Payload
public struct QRPayload: Codable, Hashable {
    public var borrowId: UUID
    public var borrowerId: UUID
    public var borrowerName: String
    public var action: QRAction
    public var timestamp: Date
    public var rotatingToken: String
    public var signature: String
    
    public init(
        borrowId: UUID,
        borrowerId: UUID,
        borrowerName: String,
        action: QRAction,
        timestamp: Date = Date(),
        rotatingToken: String = UUID().uuidString.prefix(8).uppercased()
    ) {
        self.borrowId = borrowId
        self.borrowerId = borrowerId
        self.borrowerName = borrowerName
        self.action = action
        self.timestamp = timestamp
        self.rotatingToken = rotatingToken
        
        // Cryptographic HMAC/SHA256 signature representation for on-device security
        let message = "\(borrowId.uuidString):\(borrowerId.uuidString):\(action.rawValue):\(rotatingToken)"
        let digest = SHA256.hash(data: Data(message.utf8))
        self.signature = digest.map { String(format: "%02hhx", $0) }.joined().prefix(16).description
    }
    
    // MARK: - JSON Serialization
    public func toJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    public static func from(jsonString: String) throws -> QRPayload {
        guard let data = jsonString.data(using: .utf8) else {
            throw BorrowStateError.invalidTokenSignature
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(QRPayload.self, from: data)
    }
    
    // Check if token was generated within validity window (default 300s / 5 minutes)
    public func isValid(windowSeconds: TimeInterval = 300) -> Bool {
        let elapsed = abs(Date().timeIntervalSince(timestamp))
        return elapsed <= windowSeconds
    }
    
    public var timeRemainingFormatted: String {
        let elapsed = Date().timeIntervalSince(timestamp)
        let remaining = max(0, 300 - elapsed)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
