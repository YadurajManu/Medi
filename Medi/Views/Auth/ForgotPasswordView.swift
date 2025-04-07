import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Animation states
    @State private var headerOpacity: Double = 0
    @State private var formOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            // Clean white background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.3)) {
                            dismiss() 
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .opacity(headerOpacity)
                
                // Logo and title
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue)
                    
                    Text("Reset Password")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Enter your email address and we'll send you a link to reset your password")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }
                .padding(.top, 40)
                .opacity(headerOpacity)
                
                // Form
                VStack(spacing: 24) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        MinimalTextField(
                            text: $email,
                            placeholder: "Enter your email",
                            systemImage: "envelope.fill"
                        )
                    }
                    
                    // Reset button
                    Button(action: resetPassword) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isValidEmail(email) ? Color.blue : Color.blue.opacity(0.4))
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Send Reset Link")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(height: 50)
                    }
                    .disabled(isLoading || !isValidEmail(email))
                    .scaleEffect(buttonScale)
                    
                    // Back to login
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.3)) {
                            dismiss() 
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("Remember your password?")
                                .foregroundColor(.gray)
                            
                            Text("Back to Login")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        .font(.subheadline)
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .opacity(formOpacity)
                
                Spacer()
            }
        }
        .onAppear {
            // Set email field if we have stored it from LoginView
            if let storedEmail = UserDefaults.standard.string(forKey: "lastLoggedInEmail") {
                email = storedEmail
            }
            
            // Animations
            withAnimation(.easeOut(duration: 0.5)) {
                headerOpacity = 1
            }
            
            withAnimation(.easeInOut(duration: 0.6).delay(0.3)) {
                formOpacity = 1
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
                buttonScale = 1
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if authService.isPasswordResetEmailSent {
                        dismiss()
                    }
                }
            )
        }
        .onChange(of: authService.isPasswordResetEmailSent) { isSent in
            if isSent {
                alertTitle = "Success"
                alertMessage = "Password reset instructions have been sent to your email address."
                showAlert = true
            }
        }
    }
    
    private func resetPassword() {
        guard isValidEmail(email) else {
            alertTitle = "Invalid Email"
            alertMessage = "Please enter a valid email address."
            showAlert = true
            return
        }
        
        withAnimation {
            isLoading = true
        }
        
        Task {
            do {
                try await authService.sendPasswordResetEmail(email: email)
                // Success is handled by onChange handler for isPasswordResetEmailSent
            } catch {
                // Show error alert
                DispatchQueue.main.async {
                    self.alertTitle = "Error"
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    withAnimation {
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
} 