import Foundation
import FirebaseFirestore
import CryptoKit

struct BlockchainEntry: Identifiable, Codable {
    var id: String
    var medicineId: String
    var timestamp: Date
    var eventType: EventType
    var fromOwner: String // User ID
    var toOwner: String? // User ID (nil for registration events)
    var location: String? // Current location
    var additionalInfo: [String: String]? // For any extra information
    var previousEntryHash: String? // Hash of the previous blockchain entry (nil for first entry)
    var entryHash: String // Hash of this entry (calculated)
    
    init(id: String = UUID().uuidString,
         medicineId: String,
         timestamp: Date = Date(),
         eventType: EventType,
         fromOwner: String,
         toOwner: String? = nil,
         location: String? = nil,
         additionalInfo: [String: String]? = nil,
         previousEntryHash: String? = nil) {
        
        self.id = id
        self.medicineId = medicineId
        self.timestamp = timestamp
        self.eventType = eventType
        self.fromOwner = fromOwner
        self.toOwner = toOwner
        self.location = location
        self.additionalInfo = additionalInfo
        self.previousEntryHash = previousEntryHash
        
        // Calculate the hash for this entry
        self.entryHash = computeHash()
    }
    
    private func computeHash() -> String {
        // Create a string with all the entry data
        var dataString = "\(id)-\(medicineId)-\(timestamp.timeIntervalSince1970)-\(eventType.rawValue)-\(fromOwner)"
        
        if let toOwner = toOwner {
            dataString += "-\(toOwner)"
        }
        
        if let location = location {
            dataString += "-\(location)"
        }
        
        if let additionalInfo = additionalInfo {
            for (key, value) in additionalInfo.sorted(by: { $0.key < $1.key }) {
                dataString += "-\(key):\(value)"
            }
        }
        
        if let previousEntryHash = previousEntryHash {
            dataString += "-\(previousEntryHash)"
        }
        
        // Calculate SHA-256 hash
        let inputData = Data(dataString.utf8)
        let hashed = SHA256.hash(data: inputData)
        
        // Return the hash as a hexadecimal string
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum EventType: String, Codable {
    case registration = "registration"
    case dispatch = "dispatch"
    case receive = "receive"
    case verification = "verification"
    case rejection = "rejection"
    case sale = "sale"
    case flag = "flag" // For marking suspicious activity
} 