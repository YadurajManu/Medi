import SwiftUI

struct CompanyOwnerDashboard: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome, \(authService.user?.fullName ?? "Company Owner")")
                    .font(.title)
                    .padding()
                
                // Placeholder for future features
                List {
                    Section(header: Text("Management")) {
                        NavigationLink(destination: Text("Add Medicine")) {
                            Label("Add Medicine", systemImage: "plus.circle")
                        }
                        
                        NavigationLink(destination: Text("Medicine List")) {
                            Label("Medicine Inventory", systemImage: "list.bullet")
                        }
                        
                        NavigationLink(destination: Text("Analytics")) {
                            Label("Analytics", systemImage: "chart.bar")
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
            .navigationTitle("Company Dashboard")
        }
    }
} 