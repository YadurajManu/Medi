import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var phoneNumber = ""
    @State private var selectedUserType: UserType = .consumer
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var acceptedTerms = false
    
    var body: some View {
        ZStack {
            // Clean white background
            Color.white.ignoresSafeArea()
            
            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header with back button
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text("Create Account")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Invisible spacer for centering
                        Image(systemName: "arrow.left")
                            .font(.title3)
                            .foregroundColor(.clear)
                    }
                    .padding(.top, 16)
                    
                    // User Type Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("I am a:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 12) {
                            ForEach([UserType.consumer, UserType.companyOwner, UserType.shopOwner], id: \.self) { type in
                                MinimalUserTypeButton(
                                    title: userTypeName(type),
                                    iconName: userTypeIcon(type),
                                    isSelected: selectedUserType == type,
                                    action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedUserType = type
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.top, 8)
                    
                    // Registration form
                    VStack(spacing: 20) {
                        // Full Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            MinimalTextField(
                                text: $fullName,
                                placeholder: "Enter your full name",
                                systemImage: "person.fill"
                            )
                        }
                        
                        // Email
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
                        
                        // Phone Number
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            MinimalTextField(
                                text: $phoneNumber,
                                placeholder: "Enter your phone number",
                                systemImage: "phone.fill"
                            )
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            MinimalSecureField(
                                text: $password,
                                placeholder: "Enter your password",
                                systemImage: "lock.fill"
                            )
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            MinimalSecureField(
                                text: $confirmPassword,
                                placeholder: "Confirm your password",
                                systemImage: "lock.fill"
                            )
                        }
                        
                        // Terms and conditions
                        Toggle(isOn: $acceptedTerms) {
                            HStack {
                                Text("I agree to the ")
                                    .foregroundColor(.gray)
                                
                                Button(action: {
                                    // Show terms and conditions
                                }) {
                                    Text("Terms & Conditions")
                                        .foregroundColor(.blue)
                                        .underline()
                                }
                            }
                            .font(.footnote)
                        }
                        .toggleStyle(MinimalCheckboxStyle())
                        .padding(.top, 4)
                        
                        // Error message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                        }
                    }
                    
                    // Sign Up Button
                    Button(action: signUp) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isFormValid ? Color.blue : Color.blue.opacity(0.4))
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Account")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(height: 50)
                    }
                    .disabled(isLoading || !isFormValid)
                    .padding(.top, 8)
                    
                    // Login link
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundColor(.gray)
                            
                            Text("Sign In")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        .font(.subheadline)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty && 
        !email.isEmpty && 
        !phoneNumber.isEmpty && 
        !password.isEmpty && 
        password == confirmPassword && 
        password.count >= 6 &&
        acceptedTerms
    }
    
    private func userTypeName(_ type: UserType) -> String {
        switch type {
        case .consumer:
            return "Consumer"
        case .companyOwner:
            return "Company"
        case .shopOwner:
            return "Shop"
        }
    }
    
    private func userTypeIcon(_ type: UserType) -> String {
        switch type {
        case .consumer:
            return "person.fill"
        case .companyOwner:
            return "building.2.fill"
        case .shopOwner:
            return "bag.fill"
        }
    }
    
    private func signUp() {
        // Validate inputs
        guard isFormValid else {
            if !acceptedTerms {
                errorMessage = "Please accept the terms and conditions"
            } else if password != confirmPassword {
                errorMessage = "Passwords do not match"
            } else if password.count < 6 {
                errorMessage = "Password must be at least 6 characters"
            } else {
                errorMessage = "Please fill in all fields"
            }
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await authService.signUp(
                    email: email,
                    password: password,
                    fullName: fullName,
                    phoneNumber: phoneNumber,
                    userType: selectedUserType
                )
                // Navigation will happen through the onChange handler
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}

struct MinimalUserTypeButton: View {
    let title: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 22))
                
                Text(title)
                    .font(.footnote)
            }
            .foregroundColor(isSelected ? .white : .blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
    }
} 