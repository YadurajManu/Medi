import Foundation
import FirebaseAuth

enum UserType: String, Codable {
    case consumer
    case companyOwner
    case shopOwner
}

struct User: Identifiable, Codable {
    var id: String
    var email: String
    var fullName: String
    var phoneNumber: String
    var userType: UserType
    
    init(id: String = UUID().uuidString, email: String, fullName: String, phoneNumber: String, userType: UserType) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.phoneNumber = phoneNumber
        self.userType = userType
    }
} 