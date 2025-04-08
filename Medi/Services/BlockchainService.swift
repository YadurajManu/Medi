import Foundation
import FirebaseFirestore
import CoreImage
import SwiftUI

class BlockchainService: ObservableObject {
    @Published var blockchain = Blockchain()
    @Published var isLoading = false
    @Published var error: String? = nil
    
    private let db = Firestore.firestore()
    
    init() {
        loadBlockchainFromFirebase()
    }
    
    // MARK: - Blockchain Operations
    
    // Register a new medicine to the blockchain
    func registerMedicine(drugId: String, batchNumber: String, manufacturerName: String, 
                         drugName: String, composition: String, manufactureDate: Date,
                         expiryDate: Date, manufacturingLocation: String, userId: String) async throws -> String {
        
        let medicineData = MedicineData(
            drugId: drugId,
            batchNumber: batchNumber,
            manufacturerName: manufacturerName,
            drugName: drugName,
            composition: composition,
            manufactureDate: manufactureDate,
            expiryDate: expiryDate,
            manufacturingLocation: manufacturingLocation,
            currentLocation: manufacturingLocation,
            currentHolder: userId,
            handoverHistory: [],
            qrCodeURL: "",
            status: .registered
        )
        
        // Add to blockchain
        let newBlock = blockchain.addBlock(data: medicineData)
        
        // Generate QR code
        let qrCodeURL = try await generateAndStoreQRCode(for: newBlock.id)
        
        // Update the block with QR code URL
        blockchain.updateLastBlockWithQRCode(url: qrCodeURL)
        
        // Save to Firebase
        try await saveBlockchainToFirebase()
        
        return qrCodeURL
    }
    
    // Update medicine location and handover information
    func updateMedicineHandover(blockId: String, fromEntity: String, toEntity: String, 
                               location: String, notes: String) async throws {
        guard let index = blockchain.blocks.firstIndex(where: { $0.id == blockId }) else {
            throw NSError(domain: "com.medi.blockchain", code: 404, 
                         userInfo: [NSLocalizedDescriptionKey: "Block not found"])
        }
        
        let block = blockchain.blocks[index]
        var updatedData = block.data
        
        // Create handover record
        let handover = HandoverRecord(
            fromEntity: fromEntity,
            toEntity: toEntity,
            timestamp: Date(),
            location: location,
            notes: notes
        )
        
        // Update data
        updatedData.handoverHistory.append(handover)
        updatedData.currentLocation = location
        updatedData.currentHolder = toEntity
        updatedData.status = .inTransit
        
        // Update the block with new data
        blockchain.updateBlock(at: index, with: updatedData)
        
        // Save to Firebase
        try await saveBlockchainToFirebase()
    }
    
    // Verify medicine by shop owner
    func verifyMedicine(blockId: String, shopId: String, location: String) async throws {
        guard let index = blockchain.blocks.firstIndex(where: { $0.id == blockId }) else {
            throw NSError(domain: "com.medi.blockchain", code: 404, 
                         userInfo: [NSLocalizedDescriptionKey: "Block not found"])
        }
        
        let block = blockchain.blocks[index]
        var updatedData = block.data
        
        // Update status
        updatedData.status = .verified
        updatedData.currentHolder = shopId
        updatedData.currentLocation = location
        
        // Update the block with new data
        blockchain.updateBlock(at: index, with: updatedData)
        
        // Save to Firebase
        try await saveBlockchainToFirebase()
    }
    
    // Report suspicious medicine
    func reportSuspiciousMedicine(blockId: String, reporterId: String, reason: String) async throws {
        guard let index = blockchain.blocks.firstIndex(where: { $0.id == blockId }) else {
            throw NSError(domain: "com.medi.blockchain", code: 404, 
                         userInfo: [NSLocalizedDescriptionKey: "Block not found"])
        }
        
        let block = blockchain.blocks[index]
        var updatedData = block.data
        
        // Update status
        updatedData.status = .suspicious
        
        // Add handover record with suspicious report
        let handover = HandoverRecord(
            fromEntity: updatedData.currentHolder,
            toEntity: reporterId,
            timestamp: Date(),
            location: updatedData.currentLocation,
            notes: "SUSPICIOUS: \(reason)"
        )
        
        updatedData.handoverHistory.append(handover)
        
        // Update the block with new data
        blockchain.updateBlock(at: index, with: updatedData)
        
        // Save to Firebase
        try await saveBlockchainToFirebase()
    }
    
    // Mark medicine as sold to customer
    func markMedicineAsSold(blockId: String, shopId: String, customerId: String) async throws {
        guard let index = blockchain.blocks.firstIndex(where: { $0.id == blockId }) else {
            throw NSError(domain: "com.medi.blockchain", code: 404, 
                         userInfo: [NSLocalizedDescriptionKey: "Block not found"])
        }
        
        let block = blockchain.blocks[index]
        var updatedData = block.data
        
        // Update status
        updatedData.status = .sold
        
        // Add handover record for sale
        let handover = HandoverRecord(
            fromEntity: shopId,
            toEntity: customerId,
            timestamp: Date(),
            location: updatedData.currentLocation,
            notes: "Sold to customer"
        )
        
        updatedData.handoverHistory.append(handover)
        updatedData.currentHolder = customerId
        
        // Update the block with new data
        blockchain.updateBlock(at: index, with: updatedData)
        
        // Save to Firebase
        try await saveBlockchainToFirebase()
    }
    
    // Get medicine details by scanning QR code
    func getMedicineByBlockId(_ blockId: String) -> Block? {
        return blockchain.blocks.first(where: { $0.id == blockId })
    }
    
    // MARK: - Firebase Operations
    
    // Load blockchain from Firebase
    func loadBlockchainFromFirebase() {
        if isLoading { return } // Prevent multiple concurrent loads
        
        isLoading = true
        print("Loading blockchain from Firebase...")
        
        db.collection("blockchain").order(by: "timestamp").getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.error = "Failed to load blockchain: \(error.localizedDescription)"
                    self.isLoading = false
                    print("Failed to load blockchain: \(error.localizedDescription)")
                }
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("No blockchain data found, using genesis block")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            // Create new blockchain with blocks from Firebase
            let newChain = Blockchain()
            newChain.blocks.removeAll() // Remove genesis block
            
            do {
                for document in documents {
                    let data = document.data()
                    
                    // Parse block data
                    guard 
                        let id = data["id"] as? String,
                        let timestampDouble = data["timestamp"] as? Double,
                        let previousHash = data["previousHash"] as? String,
                        let hash = data["hash"] as? String,
                        let medicineDataMap = data["data"] as? [String: Any]
                    else {
                        continue
                    }
                    
                    // Convert medicine data
                    let jsonData = try JSONSerialization.data(withJSONObject: medicineDataMap)
                    let medicineData = try JSONDecoder().decode(MedicineData.self, from: jsonData)
                    
                    // Create block
                    let timestamp = Date(timeIntervalSince1970: timestampDouble)
                    let block = Block(id: id, timestamp: timestamp, previousHash: previousHash, hash: hash, data: medicineData)
                    
                    newChain.blocks.append(block)
                }
                
                // Validate the loaded blockchain
                if newChain.blocks.isEmpty {
                    print("No valid blocks found in Firebase")
                } else if !newChain.isValid() {
                    print("Loaded blockchain is invalid, using genesis block")
                } else {
                    print("Successfully loaded \(newChain.blocks.count) blocks from Firebase")
                    DispatchQueue.main.async {
                        self.blockchain.setBlocks(newChain.blocks)
                    }
                }
            } catch {
                print("Error parsing blockchain data: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    // Save blockchain to Firebase
    func saveBlockchainToFirebase() async throws {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            // Add each block to Firebase
            for block in blockchain.blocks {
                let blockRef = db.collection("blockchain").document(block.id)
                
                var data: [String: Any] = [
                    "id": block.id,
                    "timestamp": block.timestamp.timeIntervalSince1970,
                    "previousHash": block.previousHash,
                    "hash": block.hash
                ]
                
                // Convert medicine data to dictionary
                let encoder = JSONEncoder()
                let jsonData = try encoder.encode(block.data)
                if let medicineDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    data["data"] = medicineDict
                }
                
                try await blockRef.setData(data)
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to save blockchain: \(error.localizedDescription)"
                self.isLoading = false
            }
            throw error
        }
    }
    
    // MARK: - QR Code Generation
    
    // Generate QR code and store in Firebase Storage
    func generateAndStoreQRCode(for blockId: String) async throws -> String {
        let qrGenerator = QRCodeGenerator()
        let qrImage = qrGenerator.generateQRCode(from: blockId)
        
        // In a real app, you would upload the QR image to Firebase Storage
        // For now, we'll just return a placeholder URL
        return "https://medi-app.com/qr/\(blockId)"
    }
}

// Helper class for QR code generation
class QRCodeGenerator {
    func generateQRCode(from string: String) -> UIImage {
        let data = string.data(using: .ascii)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let ciImage = filter?.outputImage else {
            return UIImage(systemName: "xmark.circle") ?? UIImage()
        }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else {
            return UIImage(systemName: "xmark.circle") ?? UIImage()
        }
        
        return UIImage(cgImage: cgImage)
    }
} 