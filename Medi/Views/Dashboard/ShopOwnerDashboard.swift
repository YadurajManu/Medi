import SwiftUI

struct ShopOwnerDashboard: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome, \(authService.user?.fullName ?? "Shop Owner")")
                    .font(.title)
                    .padding()
                
                // Placeholder for future features
                List {
                    Section(header: Text("Inventory")) {
                        NavigationLink(destination: Text("Add Stock")) {
                            Label("Add Stock", systemImage: "plus.circle")
                        }
                        
                        NavigationLink(destination: Text("Current Stock")) {
                            Label("Current Stock", systemImage: "list.bullet")
                        }
                        
                        NavigationLink(destination: Text("Verify Medicine")) {
                            Label("Verify Medicine", systemImage: "checkmark.circle")
                        }
                    }
                    
                    Section(header: Text("Sales")) {
                        NavigationLink(destination: Text("Sales History")) {
                            Label("Sales History", systemImage: "chart.line.uptrend.xyaxis")
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
            .navigationTitle("Shop Dashboard")
        }
    }
} 