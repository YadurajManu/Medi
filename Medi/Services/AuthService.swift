import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class AuthService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage = ""
    @Published var isVerificationEmailSent = false
    @Published var isPasswordResetEmailSent = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handler = authStateHandler {
            auth.removeStateDidChangeListener(handler)
        }
    }
    
    private func setupAuthStateListener() {
        authStateHandler = auth.addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            if let firebaseUser = user {
                print("User is logged in with ID: \(firebaseUser.uid)")
                self.fetchUserData(userId: firebaseUser.uid)
            } else {
                print("User is logged out")
                DispatchQueue.main.async {
                    self.user = nil
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    private func fetchUserData(userId: String) {
        Task {
            do {
                let document = try await db.collection("users").document(userId).getDocument()
                
                guard let data = document.data(),
                      let userType = UserType(rawValue: data["userType"] as? String ?? "") else {
                    print("User data not found or invalid for ID: \(userId)")
                    return
                }
                
                let userData = User(
                    id: userId,
                    email: data["email"] as? String ?? "",
                    fullName: data["fullName"] as? String ?? "",
                    phoneNumber: data["phoneNumber"] as? String ?? "",
                    userType: userType,
                    isEmailVerified: Auth.auth().currentUser?.isEmailVerified ?? false
                )
                
                DispatchQueue.main.async {
                    self.user = userData
                    self.isAuthenticated = true
                    print("User authenticated: \(userData.fullName) as \(userData.userType), Email verified: \(userData.isEmailVerified)")
                }
            } catch {
                print("Error fetching user data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signUp(email: String, password: String, fullName: String, phoneNumber: String, userType: UserType) async throws {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let user = User(
                id: result.user.uid,
                email: email,
                fullName: fullName,
                phoneNumber: phoneNumber,
                userType: userType,
                isEmailVerified: false
            )
            
            try await db.collection("users").document(user.id).setData([
                "email": user.email,
                "fullName": user.fullName,
                "phoneNumber": user.phoneNumber,
                "userType": user.userType.rawValue
            ])
            
            // Send email verification
            try await sendEmailVerification()
            
            // No need to set state manually, it will be handled by the listener
            print("User signed up successfully with ID: \(user.id)")
        } catch {
            print("Sign up error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            try await auth.signIn(withEmail: email, password: password)
            // No need to set state manually, it will be handled by the listener
            print("User signed in successfully with email: \(email)")
        } catch {
            print("Sign in error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try auth.signOut()
            // No need to set state manually, it will be handled by the listener
            print("User signed out")
        } catch {
            print("Sign out error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Email Verification
    
    func sendEmailVerification() async throws {
        guard let currentUser = auth.currentUser else {
            let error = NSError(domain: "com.medi.auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in"])
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
        
        do {
            try await currentUser.sendEmailVerification()
            DispatchQueue.main.async {
                self.isVerificationEmailSent = true
            }
            print("Verification email sent successfully")
        } catch {
            print("Email verification error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to send verification email: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func checkEmailVerificationStatus() async -> Bool {
        guard let currentUser = auth.currentUser else {
            return false
        }
        
        try? await currentUser.reload()
        return currentUser.isEmailVerified
    }
    
    // MARK: - Password Reset
    
    func sendPasswordResetEmail(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
            DispatchQueue.main.async {
                self.isPasswordResetEmailSent = true
            }
            print("Password reset email sent successfully to \(email)")
        } catch {
            print("Password reset error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to send password reset email: \(error.localizedDescription)"
            }
            throw error
        }
    }
} 