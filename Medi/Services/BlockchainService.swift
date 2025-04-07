import Foundation
import FirebaseFirestore
import FirebaseStorage
import CoreImage.CIFilterBuiltins
import UIKit

class BlockchainService: ObservableObject {
    @Published var medicines: [Medicine] = []
    @Published var blockchainEntries: [BlockchainEntry] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    // MARK: - Medicine Management
    
    func registerMedicine(medicine: Medicine) async throws -> String {
        isLoading = true
        
        do {
            // Generate QR code image first
            let qrCodeImage = generateQRCode(for: medicine.id)
            
            // Upload QR code to Firebase Storage
            let qrCodeURL = try await uploadQRCode(medicineId: medicine.id, qrImage: qrCodeImage)
            
            // Update medicine with QR code URL
            var updatedMedicine = medicine
            updatedMedicine.qrCodeURL = qrCodeURL
            
            // Save medicine to Firestore
            try await db.collection("medicines").document(medicine.id).setData([
                "id": updatedMedicine.id,
                "drugID": updatedMedicine.drugID,
                "manufacturerName": updatedMedicine.manufacturerName,
                "drugName": updatedMedicine.drugName,
                "composition": updatedMedicine.composition,
                "manufactureDate": updatedMedicine.manufactureDate,
                "expiryDate": updatedMedicine.expiryDate,
                "manufacturingLocation": updatedMedicine.manufacturingLocation,
                "qrCodeURL": updatedMedicine.qrCodeURL ?? "",
                "registeredBy": updatedMedicine.registeredBy,
                "registrationDate": updatedMedicine.registrationDate,
                "isVerified": updatedMedicine.isVerified,
                "currentOwner": updatedMedicine.currentOwner,
                "status": updatedMedicine.status.rawValue
            ])
            
            // Create the first blockchain entry for registration
            let blockchainEntry = BlockchainEntry(
                medicineId: updatedMedicine.id,
                eventType: .registration,
                fromOwner: updatedMedicine.registeredBy,
                location: updatedMedicine.manufacturingLocation,
                additionalInfo: [
                    "drugID": updatedMedicine.drugID,
                    "manufacturerName": updatedMedicine.manufacturerName,
                    "drugName": updatedMedicine.drugName
                ]
            )
            
            try await addBlockchainEntry(blockchainEntry)
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.successMessage = "Medicine registered successfully!"
            }
            
            return updatedMedicine.id
            
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Failed to register medicine: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func getMedicine(by id: String) async throws -> Medicine {
        do {
            let document = try await db.collection("medicines").document(id).getDocument()
            
            guard let data = document.data(),
                  let status = MedicineStatus(rawValue: data["status"] as? String ?? "") else {
                throw NSError(domain: "com.medi.blockchain", code: 404, userInfo: [NSLocalizedDescriptionKey: "Medicine not found or invalid data"])
            }
            
            // Convert Firestore timestamp to Date
            let manufactureDate = (data["manufactureDate"] as? Timestamp)?.dateValue() ?? Date()
            let expiryDate = (data["expiryDate"] as? Timestamp)?.dateValue() ?? Date()
            let registrationDate = (data["registrationDate"] as? Timestamp)?.dateValue() ?? Date()
            
            let medicine = Medicine(
                id: data["id"] as? String ?? "",
                drugID: data["drugID"] as? String ?? "",
                manufacturerName: data["manufacturerName"] as? String ?? "",
                drugName: data["drugName"] as? String ?? "",
                composition: data["composition"] as? String ?? "",
                manufactureDate: manufactureDate,
                expiryDate: expiryDate,
                manufacturingLocation: data["manufacturingLocation"] as? String ?? "",
                qrCodeURL: data["qrCodeURL"] as? String,
                registeredBy: data["registeredBy"] as? String ?? "",
                registrationDate: registrationDate,
                isVerified: data["isVerified"] as? Bool ?? true,
                currentOwner: data["currentOwner"] as? String ?? "",
                status: status
            )
            
            return medicine
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to fetch medicine: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func updateMedicineStatus(medicineId: String, newStatus: MedicineStatus, newOwner: String? = nil) async throws {
        do {
            var updateData: [String: Any] = ["status": newStatus.rawValue]
            
            if let newOwner = newOwner {
                updateData["currentOwner"] = newOwner
            }
            
            try await db.collection("medicines").document(medicineId).updateData(updateData)
            
            DispatchQueue.main.async {
                self.successMessage = "Medicine status updated successfully!"
            }
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to update medicine status: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func getMedicinesByOwner(ownerId: String) async throws -> [Medicine] {
        do {
            let snapshot = try await db.collection("medicines")
                .whereField("currentOwner", isEqualTo: ownerId)
                .getDocuments()
            
            var medicines: [Medicine] = []
            
            for document in snapshot.documents {
                let data = document.data()
                
                guard let status = MedicineStatus(rawValue: data["status"] as? String ?? "") else {
                    continue
                }
                
                let manufactureDate = (data["manufactureDate"] as? Timestamp)?.dateValue() ?? Date()
                let expiryDate = (data["expiryDate"] as? Timestamp)?.dateValue() ?? Date()
                let registrationDate = (data["registrationDate"] as? Timestamp)?.dateValue() ?? Date()
                
                let medicine = Medicine(
                    id: data["id"] as? String ?? "",
                    drugID: data["drugID"] as? String ?? "",
                    manufacturerName: data["manufacturerName"] as? String ?? "",
                    drugName: data["drugName"] as? String ?? "",
                    composition: data["composition"] as? String ?? "",
                    manufactureDate: manufactureDate,
                    expiryDate: expiryDate,
                    manufacturingLocation: data["manufacturingLocation"] as? String ?? "",
                    qrCodeURL: data["qrCodeURL"] as? String,
                    registeredBy: data["registeredBy"] as? String ?? "",
                    registrationDate: registrationDate,
                    isVerified: data["isVerified"] as? Bool ?? true,
                    currentOwner: data["currentOwner"] as? String ?? "",
                    status: status
                )
                
                medicines.append(medicine)
            }
            
            DispatchQueue.main.async {
                self.medicines = medicines
            }
            
            return medicines
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to fetch medicines: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Blockchain Management
    
    func addBlockchainEntry(_ entry: BlockchainEntry) async throws {
        do {
            // First, get the latest entry for this medicine to get the previous hash
            var updatedEntry = entry
            
            if entry.previousEntryHash == nil {
                // If no previous hash provided, try to find the latest entry
                do {
                    let latestEntry = try await getLatestBlockchainEntry(for: entry.medicineId)
                    updatedEntry = BlockchainEntry(
                        id: entry.id,
                        medicineId: entry.medicineId,
                        timestamp: entry.timestamp,
                        eventType: entry.eventType,
                        fromOwner: entry.fromOwner,
                        toOwner: entry.toOwner,
                        location: entry.location,
                        additionalInfo: entry.additionalInfo,
                        previousEntryHash: latestEntry?.entryHash
                    )
                } catch {
                    // If no latest entry found, this is the first entry
                    print("No previous blockchain entry found, creating the first one")
                }
            }
            
            // Save to Firestore
            try await db.collection("blockchain").document(updatedEntry.id).setData([
                "id": updatedEntry.id,
                "medicineId": updatedEntry.medicineId,
                "timestamp": updatedEntry.timestamp,
                "eventType": updatedEntry.eventType.rawValue,
                "fromOwner": updatedEntry.fromOwner,
                "toOwner": updatedEntry.toOwner as Any,
                "location": updatedEntry.location as Any,
                "additionalInfo": updatedEntry.additionalInfo as Any,
                "previousEntryHash": updatedEntry.previousEntryHash as Any,
                "entryHash": updatedEntry.entryHash
            ])
            
            DispatchQueue.main.async {
                self.successMessage = "Blockchain entry added successfully!"
            }
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to add blockchain entry: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func getBlockchainHistory(for medicineId: String) async throws -> [BlockchainEntry] {
        do {
            let snapshot = try await db.collection("blockchain")
                .whereField("medicineId", isEqualTo: medicineId)
                .order(by: "timestamp", descending: false)
                .getDocuments()
            
            var entries: [BlockchainEntry] = []
            
            for document in snapshot.documents {
                let data = document.data()
                
                guard let eventTypeString = data["eventType"] as? String,
                      let eventType = EventType(rawValue: eventTypeString) else {
                    continue
                }
                
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                
                let entry = BlockchainEntry(
                    id: data["id"] as? String ?? "",
                    medicineId: data["medicineId"] as? String ?? "",
                    timestamp: timestamp,
                    eventType: eventType,
                    fromOwner: data["fromOwner"] as? String ?? "",
                    toOwner: data["toOwner"] as? String,
                    location: data["location"] as? String,
                    additionalInfo: data["additionalInfo"] as? [String: String],
                    previousEntryHash: data["previousEntryHash"] as? String
                )
                
                entries.append(entry)
            }
            
            DispatchQueue.main.async {
                self.blockchainEntries = entries
            }
            
            return entries
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to fetch blockchain history: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func getLatestBlockchainEntry(for medicineId: String) async throws -> BlockchainEntry? {
        do {
            let snapshot = try await db.collection("blockchain")
                .whereField("medicineId", isEqualTo: medicineId)
                .order(by: "timestamp", descending: true)
                .limit(to: 1)
                .getDocuments()
            
            if let document = snapshot.documents.first {
                let data = document.data()
                
                guard let eventTypeString = data["eventType"] as? String,
                      let eventType = EventType(rawValue: eventTypeString) else {
                    return nil
                }
                
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                
                let entry = BlockchainEntry(
                    id: data["id"] as? String ?? "",
                    medicineId: data["medicineId"] as? String ?? "",
                    timestamp: timestamp,
                    eventType: eventType,
                    fromOwner: data["fromOwner"] as? String ?? "",
                    toOwner: data["toOwner"] as? String,
                    location: data["location"] as? String,
                    additionalInfo: data["additionalInfo"] as? [String: String],
                    previousEntryHash: data["previousEntryHash"] as? String
                )
                
                return entry
            }
            
            return nil
            
        } catch {
            throw error
        }
    }
    
    func validateBlockchainIntegrity(for medicineId: String) async throws -> Bool {
        do {
            let entries = try await getBlockchainHistory(for: medicineId)
            
            // If there's only one entry or no entries, the chain is valid
            if entries.count <= 1 {
                return true
            }
            
            // Check each entry's hash against the previous hash reference
            for i in 1..<entries.count {
                let currentEntry = entries[i]
                let previousEntry = entries[i-1]
                
                // Verify that the current entry's previousEntryHash matches the previous entry's actual hash
                if currentEntry.previousEntryHash != previousEntry.entryHash {
                    return false
                }
            }
            
            return true
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to validate blockchain: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - QR Code Generation and Scanning
    
    private func generateQRCode(for medicineId: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        let data = medicineId.data(using: .utf8)
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction
        
        if let outputImage = filter.outputImage {
            // Scale the QR code image
            let scale = 10.0
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        // Return a placeholder image if QR code generation fails
        return UIImage(systemName: "qrcode") ?? UIImage()
    }
    
    private func uploadQRCode(medicineId: String, qrImage: UIImage) async throws -> String {
        guard let imageData = qrImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "com.medi.blockchain", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to convert QR code to data"])
        }
        
        let qrCodeRef = storage.child("qrcodes/\(medicineId).jpg")
        
        _ = try await qrCodeRef.putDataAsync(imageData)
        let downloadURL = try await qrCodeRef.downloadURL()
        
        return downloadURL.absoluteString
    }
} 