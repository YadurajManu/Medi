import SwiftUI

struct CompanyOwnerDashboard: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var blockchainService = BlockchainService()
    
    @State private var showAddMedicine = false
    @State private var showMedicineList = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Email verification banner
                EmailVerificationBanner()
                
                Text("Welcome, \(authService.user?.fullName ?? "Company Owner")")
                    .font(.title)
                    .padding()
                
                // Dashboard cards
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        // Add Medicine Card
                        DashboardCard(
                            title: "Register Medicine",
                            subtitle: "Add new medicine to blockchain",
                            iconName: "pill.fill",
                            color: .blue
                        ) {
                            showAddMedicine = true
                        }
                        
                        // View Medicines Card
                        DashboardCard(
                            title: "Medicine Inventory",
                            subtitle: "View registered medicines",
                            iconName: "list.bullet.clipboard",
                            color: .green
                        ) {
                            showMedicineList = true
                        }
                        
                        // Dispatch Medicine Card
                        DashboardCard(
                            title: "Dispatch Medicine",
                            subtitle: "Transfer to logistics",
                            iconName: "shippingbox.fill",
                            color: .orange
                        ) {
                            // Will implement later
                        }
                        
                        // Analytics Card
                        DashboardCard(
                            title: "Analytics",
                            subtitle: "Track medicine statistics",
                            iconName: "chart.bar.fill",
                            color: .purple
                        ) {
                            // Will implement later
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent activity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.leading)
                        
                        // Placeholder for activity feed
                        ForEach(1...3, id: \.self) { _ in
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(.blue)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Medicine Registered")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text("A few moments ago")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 24)
                }
                
                Spacer()
                
                // Sign out button
                Button(action: {
                    try? authService.signOut()
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                        Text("Sign Out")
                    }
                    .foregroundColor(.red)
                    .padding()
                }
            }
            .navigationTitle("Company Dashboard")
            .fullScreenCover(isPresented: $showAddMedicine) {
                AddMedicineView()
                    .environmentObject(authService)
            }
            .navigationDestination(isPresented: $showMedicineList) {
                MedicineListView()
                    .environmentObject(authService)
            }
            .onAppear {
                // Check email verification status when dashboard appears
                Task {
                    let _ = await authService.checkEmailVerificationStatus()
                }
            }
        }
    }
}

struct DashboardCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 24))
                            .foregroundColor(color)
                    )
                
                // Title
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Subtitle
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .frame(height: 160)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 