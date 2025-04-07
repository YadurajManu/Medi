import SwiftUI

struct ConsumerDashboard: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            VStack {
                // Email verification banner
                EmailVerificationBanner()
                
                Text("Welcome, \(authService.user?.fullName ?? "Consumer")")
                    .font(.title)
                    .padding()
                
                // Placeholder for future features
                List {
                    Section(header: Text("Quick Actions")) {
                        NavigationLink(destination: Text("Scan Medicine")) {
                            Label("Scan Medicine", systemImage: "barcode.viewfinder")
                        }
                        
                        NavigationLink(destination: Text("My History")) {
                            Label("Verification History", systemImage: "clock")
                        }
                    }
                    
                    Section(header: Text("Account")) {
                        Button(action: {
                            try? authService.signOut()
                        }) {
                            Label("Sign Out", systemImage: "arrow.right.square")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Consumer Dashboard")
            .onAppear {
                // Check email verification status when dashboard appears
                Task {
                    let _ = await authService.checkEmailVerificationStatus()
                }
            }
        }
    }
} 