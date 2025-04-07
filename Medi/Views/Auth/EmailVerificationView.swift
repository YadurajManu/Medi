import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var isCheckingStatus = false
    @State private var showResendAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var timer: Timer?
    @State private var countdown = 60
    
    // Animation states
    @State private var imageScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0
    
    var userEmail: String
    
    var body: some View {
        ZStack {
            // Clean white background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Close button
                HStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                
                // Illustration and title
                VStack(spacing: 20) {
                    Image(systemName: "envelope.badge.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .scaleEffect(imageScale)
                    
                    Text("Verify Your Email")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    VStack(spacing: 12) {
                        Text("We've sent a verification email to:")
                            .foregroundColor(.gray)
                        
                        Text(userEmail)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text("Please check your inbox and click the verification link to confirm your email address.")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                }
                .padding(.top, 20)
                
                // Action buttons
                VStack(spacing: 15) {
                    // Check status button
                    Button(action: checkVerificationStatus) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                            
                            if isCheckingStatus {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("I've Verified My Email")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(height: 50)
                    }
                    .padding(.horizontal, 20)
                    .disabled(isCheckingStatus)
                    
                    // Resend email button
                    Button(action: resendVerificationEmail) {
                        HStack {
                            Text(countdown > 0 ? "Resend Email (\(countdown)s)" : "Resend Email")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(countdown > 0 ? .gray : .blue)
                    }
                    .disabled(countdown > 0)
                    .padding(.top, 5)
                    
                    // Or use different email
                    Button(action: {
                        // Log out and return to sign up
                        try? authService.signOut()
                        dismiss()
                    }) {
                        Text("Use a Different Email")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 10)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .opacity(contentOpacity)
        }
        .onAppear {
            // Start animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                imageScale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                contentOpacity = 1
            }
            
            // Start countdown timer for resend
            startResendTimer()
        }
        .onDisappear {
            // Clean up timer
            timer?.invalidate()
        }
        // Alert for resend confirmation
        .alert("Email Sent", isPresented: $showResendAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A new verification email has been sent to your email address.")
        }
        // Alert for error messages
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // Check if email is verified
    private func checkVerificationStatus() {
        withAnimation {
            isCheckingStatus = true
        }
        
        Task {
            do {
                let isVerified = try await authService.checkEmailVerificationStatus()
                
                if isVerified {
                    // Email is verified, dismiss and proceed
                    DispatchQueue.main.async {
                        dismiss()
                    }
                } else {
                    // Email is not verified yet
                    DispatchQueue.main.async {
                        withAnimation {
                            isCheckingStatus = false
                        }
                        errorMessage = "Your email is not verified yet. Please check your inbox and click the verification link."
                        showErrorAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    withAnimation {
                        isCheckingStatus = false
                    }
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    // Resend verification email
    private func resendVerificationEmail() {
        Task {
            do {
                try await authService.sendEmailVerification()
                
                DispatchQueue.main.async {
                    showResendAlert = true
                    startResendTimer() // Restart the countdown timer
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    // Handle countdown timer for resend button
    private func startResendTimer() {
        countdown = 60
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
} 