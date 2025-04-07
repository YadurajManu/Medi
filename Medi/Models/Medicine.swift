import Foundation
import FirebaseFirestore

struct Medicine: Identifiable, Codable {
    var id: String
    var drugID: String // Unique Drug ID / Batch Number
    var manufacturerName: String
    var drugName: String
    var composition: String
    var manufactureDate: Date
    var expiryDate: Date
    var manufacturingLocation: String
    var qrCodeURL: String?
    var registeredBy: String // User ID of the company owner who registered the medicine
    var registrationDate: Date
    var isVerified: Bool = true
    
    // Additional fields for blockchain
    var currentOwner: String // UserID of current owner (company, logistics, shop)
    var status: MedicineStatus
    
    init(id: String = UUID().uuidString,
         drugID: String,
         manufacturerName: String,
         drugName: String,
         composition: String,
         manufactureDate: Date,
         expiryDate: Date,
         manufacturingLocation: String,
         qrCodeURL: String? = nil,
         registeredBy: String,
         registrationDate: Date = Date(),
         isVerified: Bool = true,
         currentOwner: String,
         status: MedicineStatus = .registered) {
        
        self.id = id
        self.drugID = drugID
        self.manufacturerName = manufacturerName
        self.drugName = drugName
        self.composition = composition
        self.manufactureDate = manufactureDate
        self.expiryDate = expiryDate
        self.manufacturingLocation = manufacturingLocation
        self.qrCodeURL = qrCodeURL
        self.registeredBy = registeredBy
        self.registrationDate = registrationDate
        self.isVerified = isVerified
        self.currentOwner = currentOwner
        self.status = status
    }
}

enum MedicineStatus: String, Codable {
    case registered = "registered"
    case inTransit = "inTransit"
    case delivered = "delivered"
    case verified = "verified"
    case sold = "sold"
    case flagged = "flagged" // Suspicious or problematic
} 