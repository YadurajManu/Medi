import Foundation
import FirebaseAuth

enum UserType: String, Codable {
    case consumer
    case companyOwner
    case shopOwner
    case transportation
}

struct User: Identifiable, Codable {
    var id: String
    var email: String
    var fullName: String
    var phoneNumber: String
    var userType: UserType
    var isEmailVerified: Bool
    
    init(id: String = UUID().uuidString, email: String, fullName: String, phoneNumber: String, userType: UserType, isEmailVerified: Bool = false) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.phoneNumber = phoneNumber
        self.userType = userType
        self.isEmailVerified = isEmailVerified
    }
} 