import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showSignUp = false
    @State private var showAlert = false
    @State private var rememberMe = false
    
    // Animation states
    @State private var logoOffset: CGFloat = -100
    @State private var formOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 100
    
    // User defaults for remembering email
    @AppStorage("lastLoggedInEmail") private var lastLoggedInEmail: String = ""
    @AppStorage("userFirstName") private var userFirstName: String = ""
    
    var body: some View {
        ZStack {
            // Clean white background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with logo
                VStack(spacing: 16) {
                    Image(systemName: "pill.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                        .offset(y: logoOffset)
                    
                    Text("Medi")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .offset(y: logoOffset)
                    
                    Text("Secure Drug Authentication")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .offset(y: logoOffset)
                    
                    // Welcome back message - shows only if we have user's name stored
                    if !userFirstName.isEmpty {
                        Text("Welcome back, \(userFirstName)!")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.blue.opacity(0.8))
                            .padding(.top, 8)
                            .offset(y: logoOffset)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Login form
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
                    .opacity(formOpacity)
                    
                    // Password field
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
                    .opacity(formOpacity)
                    
                    // Remember me and forgot password
                    HStack {
                        Toggle("Remember me", isOn: $rememberMe)
                            .toggleStyle(MinimalCheckboxStyle())
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Button("Forgot Password?") {
                            // Implement forgot password functionality
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                    .opacity(formOpacity)
                    
                    // Error message
                    if !authService.errorMessage.isEmpty {
                        Text(authService.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                            .opacity(formOpacity)
                    }
                    
                    // Login button
                    Button(action: signIn) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(height: 50)
                    }
                    .disabled(isLoading)
                    .padding(.top, 8)
                    .offset(y: buttonOffset)
                    
                    // Or divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("OR")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 16)
                    .opacity(formOpacity)
                    
                    // Sign up link
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            showSignUp = true
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(.gray)
                            
                            Text("Create new account")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        .font(.subheadline)
                    }
                    .opacity(formOpacity)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .onAppear {
            // Set email field if we have stored it
            if !lastLoggedInEmail.isEmpty && email.isEmpty {
                email = lastLoggedInEmail
            }
            
            // Run animations when the view appears
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                logoOffset = 0
            }
            
            withAnimation(.easeInOut(duration: 0.6).delay(0.4)) {
                formOpacity = 1
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7)) {
                buttonOffset = 0
            }
        }
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(authService)
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authService.errorMessage)
        }
        .onChange(of: authService.errorMessage) { newValue in
            showAlert = !newValue.isEmpty
        }
    }
    
    private func signIn() {
        guard !email.isEmpty && !password.isEmpty else {
            authService.errorMessage = "Please enter both email and password"
            return
        }
        
        // Save email if remember me is enabled
        if rememberMe {
            lastLoggedInEmail = email
        }
        
        withAnimation {
            isLoading = true
        }
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                // If login successful, store the user's first name
                if let user = authService.user, !user.fullName.isEmpty {
                    let firstName = user.fullName.components(separatedBy: " ").first ?? user.fullName
                    userFirstName = firstName
                }
            } catch {
                // Error is already handled in AuthService
                print("Login failed: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                withAnimation {
                    self.isLoading = false
                }
            }
        }
    }
}

struct MinimalTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .disableAutocorrection(true)
                .font(.body)
            
            // Show checkmark for valid email
            if isValidEmail(text) && !text.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .animation(.easeInOut(duration: 0.2), value: text)
    }
    
    // Email validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

struct MinimalSecureField: View {
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

struct MinimalCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 18, height: 18)
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        configuration.isOn.toggle()
                    }
                }
            
            configuration.label
                .font(.footnote)
        }
    }
} 