import Foundation
import CryptoKit

// Represents a single block in the blockchain
struct Block: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let previousHash: String
    let hash: String
    let data: MedicineData
    
    // Initialize a new block
    init(data: MedicineData, previousHash: String) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.data = data
        self.previousHash = previousHash
        let dataString = "\(id)\(timestamp.timeIntervalSince1970)\(previousHash)\(data.toJson())"
        let inputData = Data(dataString.utf8)
        let hashedData = SHA256.hash(data: inputData)
        self.hash = hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // Custom initializer with specific ID, timestamp and hash
    init(id: String, timestamp: Date, previousHash: String, hash: String, data: MedicineData) {
        self.id = id
        self.timestamp = timestamp
        self.previousHash = previousHash
        self.hash = hash
        self.data = data
    }
    
    // Calculate hash for this block
    func calculateHash() -> String {
        let dataString = "\(id)\(timestamp.timeIntervalSince1970)\(previousHash)\(data.toJson())"
        let inputData = Data(dataString.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // Validate that this block's hash is correct
    func isValid() -> Bool {
        return hash == calculateHash()
    }
}

// Medicine data to be stored in a block
struct MedicineData: Codable {
    // Medicine registration data
    var drugId: String
    var batchNumber: String
    var manufacturerName: String
    var drugName: String
    var composition: String
    var manufactureDate: Date
    var expiryDate: Date
    var manufacturingLocation: String
    
    // Supply chain data
    var currentLocation: String
    var currentHolder: String
    var handoverHistory: [HandoverRecord]
    var qrCodeURL: String
    var status: MedicineStatus
    
    // Convert to JSON string for hashing
    func toJson() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let jsonData = try? encoder.encode(self) else {
            return "{}"
        }
        
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    }
    
    // Status of the medicine
    enum MedicineStatus: String, Codable {
        case registered = "Registered"
        case inTransit = "In Transit"
        case delivered = "Delivered"
        case verified = "Verified"
        case suspicious = "Suspicious"
        case sold = "Sold"
    }
}

// Record of each handover in the supply chain
struct HandoverRecord: Codable, Identifiable {
    var id: String = UUID().uuidString
    var fromEntity: String
    var toEntity: String
    var timestamp: Date
    var location: String
    var notes: String
}

// The main blockchain class
class Blockchain: ObservableObject {
    @Published var blocks: [Block] = []
    
    // Genesis block - the first block in the chain
    init() {
        let genesisData = MedicineData(
            drugId: "genesis",
            batchNumber: "genesis",
            manufacturerName: "Genesis",
            drugName: "Genesis",
            composition: "Genesis",
            manufactureDate: Date(),
            expiryDate: Date().addingTimeInterval(31536000), // 1 year from now
            manufacturingLocation: "Genesis",
            currentLocation: "Genesis",
            currentHolder: "Genesis",
            handoverHistory: [],
            qrCodeURL: "",
            status: .registered
        )
        
        let genesisBlock = Block(data: genesisData, previousHash: "0")
        blocks.append(genesisBlock)
    }
    
    // Add a new block to the chain
    func addBlock(data: MedicineData) -> Block {
        let previousBlock = blocks.last!
        let newBlock = Block(data: data, previousHash: previousBlock.hash)
        blocks.append(newBlock)
        return newBlock
    }
    
    // Replace a block at a specific index
    func updateBlock(at index: Int, with updatedData: MedicineData) {
        guard index >= 0 && index < blocks.count else { return }
        let block = blocks[index]
        let updatedBlock = Block(id: block.id, timestamp: block.timestamp, previousHash: block.previousHash, hash: block.hash, data: updatedData)
        blocks[index] = updatedBlock
    }
    
    // Update last block with QR code URL
    func updateLastBlockWithQRCode(url: String) {
        guard let lastIndex = blocks.indices.last else { return }
        var updatedData = blocks[lastIndex].data
        updatedData.qrCodeURL = url
        updateBlock(at: lastIndex, with: updatedData)
    }
    
    // Set all blocks (used when loading from Firebase)
    func setBlocks(_ newBlocks: [Block]) {
        blocks = newBlocks
    }
    
    // Check if the blockchain is valid
    func isValid() -> Bool {
        for i in 1..<blocks.count {
            let currentBlock = blocks[i]
            let previousBlock = blocks[i-1]
            
            // Verify current block's hash
            if !currentBlock.isValid() {
                return false
            }
            
            // Verify current block links to previous block
            if currentBlock.previousHash != previousBlock.hash {
                return false
            }
        }
        return true
    }
    
    // Find a medicine by its drug ID
    func findMedicineByDrugId(_ drugId: String) -> Block? {
        return blocks.first(where: { $0.data.drugId == drugId })
    }
} 