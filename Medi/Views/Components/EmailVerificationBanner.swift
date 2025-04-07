import SwiftUI

struct EmailVerificationBanner: View {
    @EnvironmentObject var authService: AuthService
    @State private var isLoading = false
    @State private var showEmailVerification = false
    
    var body: some View {
        if let user = authService.user, !user.isEmailVerified {
            VStack {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email Not Verified")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Please verify your email address to access all features")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        sendVerificationEmail()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(width: 20, height: 20)
                        } else {
                            Text("Verify")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .disabled(isLoading)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange)
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .fullScreenCover(isPresented: $showEmailVerification) {
                if let user = authService.user {
                    EmailVerificationView(userEmail: user.email)
                        .environmentObject(authService)
                }
            }
        }
    }
    
    private func sendVerificationEmail() {
        isLoading = true
        
        Task {
            do {
                try await authService.sendEmailVerification()
                DispatchQueue.main.async {
                    isLoading = false
                    showEmailVerification = true
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    // You could add an alert here to show the error
                }
            }
        }
    }
} 