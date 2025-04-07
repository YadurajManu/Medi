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
    @State private var showEmailVerification = false
    
    // Animation states
    @State private var headerOpacity: Double = 0
    @State private var userTypeOffset: CGFloat = 50
    @State private var formOffset: CGFloat = 50
    @State private var buttonScale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            // Clean white background
            Color.white.ignoresSafeArea()
            
            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header with back button
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
                    .opacity(headerOpacity)
                    
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
                    .offset(y: userTypeOffset)
                    .opacity(userTypeOffset == 0 ? 1 : 0)
                    
                    // Registration form
                    VStack(spacing: 20) {
                        // Full Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            ValidatedTextField(
                                text: $fullName,
                                placeholder: "Enter your full name",
                                systemImage: "person.fill",
                                isValid: { !$0.isEmpty && $0.count >= 3 }
                            )
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            ValidatedTextField(
                                text: $email,
                                placeholder: "Enter your email",
                                systemImage: "envelope.fill",
                                isValid: isValidEmail(_:)
                            )
                        }
                        
                        // Phone Number
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            ValidatedTextField(
                                text: $phoneNumber,
                                placeholder: "Enter your phone number",
                                systemImage: "phone.fill",
                                isValid: isValidPhoneNumber(_:)
                            )
                        }
                        
                        // Password with strength meter
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            PasswordField(
                                text: $password,
                                placeholder: "Enter your password",
                                systemImage: "lock.fill"
                            )
                            
                            if !password.isEmpty {
                                // Password strength indicator
                                PasswordStrengthView(password: password)
                                    .transition(.opacity)
                            }
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            ValidatedPasswordField(
                                text: $confirmPassword,
                                placeholder: "Confirm your password",
                                systemImage: "lock.fill",
                                isValid: { $0 == password && !$0.isEmpty }
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
                                .transition(.opacity)
                        }
                    }
                    .offset(y: formOffset)
                    .opacity(formOffset == 0 ? 1 : 0)
                    
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
                    .scaleEffect(buttonScale)
                    
                    // Login link
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.3)) {
                            dismiss() 
                        }
                    }) {
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
                    .opacity(headerOpacity)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            // Reset state
            authService.isVerificationEmailSent = false
            
            // Staggered animations when the view appears
            withAnimation(.easeOut(duration: 0.5)) {
                headerOpacity = 1
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                userTypeOffset = 0
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4)) {
                formOffset = 0
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6)) {
                buttonScale = 1
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showEmailVerification) {
            EmailVerificationView(userEmail: email)
                .environmentObject(authService)
        }
        .onChange(of: authService.isVerificationEmailSent) { isSent in
            if isSent {
                // Show email verification screen
                showEmailVerification = true
            }
        }
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty && fullName.count >= 3 &&
        isValidEmail(email) && 
        isValidPhoneNumber(phoneNumber) && 
        !password.isEmpty && 
        password.count >= 6 &&
        password == confirmPassword && 
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
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        // Simple validation - at least 10 digits
        let digitsOnly = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return digitsOnly.count >= 10
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
                errorMessage = "Please fill in all fields correctly"
            }
            
            withAnimation {
                showError = true
            }
            return
        }
        
        withAnimation {
            isLoading = true
        }
        
        Task {
            do {
                try await authService.signUp(
                    email: email,
                    password: password,
                    fullName: fullName,
                    phoneNumber: phoneNumber,
                    userType: selectedUserType
                )
                
                // Save first name for welcome back message
                let firstName = fullName.components(separatedBy: " ").first ?? fullName
                UserDefaults.standard.set(firstName, forKey: "userFirstName")
                
                // Email verification will trigger the onChange handler which shows the verification screen
                
            } catch {
                errorMessage = error.localizedDescription
                withAnimation {
                    showError = true
                }
            }
            
            DispatchQueue.main.async {
                withAnimation {
                    self.isLoading = false
                }
            }
        }
    }
}

struct ValidatedTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    let isValid: (String) -> Bool
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .font(.body)
            
            // Show validation indicator
            if !text.isEmpty {
                Image(systemName: isValid(text) ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(isValid(text) ? .green : .orange)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .animation(.easeInOut(duration: 0.2), value: text)
        .animation(.easeInOut(duration: 0.2), value: isValid(text))
    }
}

struct PasswordField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    @State private var isVisible: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
                .frame(width: 24)
            
            if isVisible {
                TextField(placeholder, text: $text)
                    .foregroundColor(.primary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .font(.body)
            } else {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.primary)
                    .font(.body)
            }
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isVisible.toggle()
                }
            }) {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct ValidatedPasswordField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    let isValid: (String) -> Bool
    @State private var isVisible: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
                .frame(width: 24)
            
            if isVisible {
                TextField(placeholder, text: $text)
                    .foregroundColor(.primary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .font(.body)
            } else {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.primary)
                    .font(.body)
            }
            
            // Show eye button and validation indicator
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isVisible.toggle()
                    }
                }) {
                    Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
                
                if !text.isEmpty {
                    Image(systemName: isValid(text) ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(isValid(text) ? .green : .orange)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .animation(.easeInOut(duration: 0.2), value: text)
        .animation(.easeInOut(duration: 0.2), value: isValid(text))
    }
}

struct PasswordStrengthView: View {
    let password: String
    
    private var strength: PasswordStrength {
        return getPasswordStrength(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    Rectangle()
                        .fill(index < strength.rawValue ? strength.color : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
            
            Text(strength.description)
                .font(.caption)
                .foregroundColor(strength.color)
        }
        .animation(.easeInOut(duration: 0.3), value: strength.rawValue)
    }
    
    private func getPasswordStrength(_ password: String) -> PasswordStrength {
        if password.isEmpty {
            return .empty
        }
        
        var score = 0
        
        // Length check
        if password.count >= 8 {
            score += 1
        }
        
        // Contains uppercase
        if password.range(of: "(?=.*[A-Z])", options: .regularExpression) != nil {
            score += 1
        }
        
        // Contains number
        if password.range(of: "(?=.*[0-9])", options: .regularExpression) != nil {
            score += 1
        }
        
        // Contains special character
        if password.range(of: "(?=.*[!@#$%^&*(),.?\":{}|<>])", options: .regularExpression) != nil {
            score += 1
        }
        
        // Return appropriate strength based on score
        if score == 4 {
            return .strong
        } else if score >= 2 {
            return .medium
        } else {
            return .weak
        }
    }
}

enum PasswordStrength: Int, CaseIterable {
    case empty = 0
    case weak = 1
    case medium = 2
    case strong = 4
    
    var description: String {
        switch self {
        case .empty:
            return "Enter password"
        case .weak:
            return "Weak password"
        case .medium:
            return "Medium strength"
        case .strong:
            return "Strong password"
        }
    }
    
    var color: Color {
        switch self {
        case .empty:
            return .gray
        case .weak:
            return .red
        case .medium:
            return .orange
        case .strong:
            return .green
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
        .transition(.scale.combined(with: .opacity))
    }
} 