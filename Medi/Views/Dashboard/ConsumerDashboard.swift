import SwiftUI
import Foundation
import FirebaseFirestore

struct ConsumerDashboard: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var blockchainService = BlockchainService()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ConsumerHomeView(selectedTab: $selectedTab)
                .environmentObject(authService)
                .environmentObject(blockchainService)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            ConsumerVerifyView(selectedTab: $selectedTab)
                .environmentObject(authService)
                .environmentObject(blockchainService)
                .tabItem {
                    Label("Verify", systemImage: "qrcode.viewfinder")
                }
                .tag(1)
            
            ConsumerHistoryView(selectedTab: $selectedTab)
                .environmentObject(authService)
                .environmentObject(blockchainService)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(2)
            
            ConsumerProfileView(selectedTab: $selectedTab)
                .environmentObject(authService)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .onAppear {
            // Ensure blockchain data is loaded when dashboard appears
            blockchainService.loadBlockchainFromFirebase()
        }
    }
}

struct ConsumerHomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var blockchainService: BlockchainService
    @State private var recentMedicines: [Block] = []
    @State private var isLoading = true
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Medi App")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            if let user = authService.user {
                                Text("Welcome, \(user.fullName)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                    .padding()
                    
                    // Quick Verify Banner
                    ZStack {
                        Rectangle()
                            .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(15)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Verify Medicine Safety")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Scan QR code to verify authenticity")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                selectedTab = 1 // Switch to verify tab
                            }) {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Circle().fill(Color.white.opacity(0.2)))
                            }
                        }
                        .padding()
                    }
                    .frame(height: 100)
                    .padding(.horizontal)
                    
                    // Recent Medicines
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Recently Verified Medicines")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if isLoading {
                            ForEach(0..<3) { _ in
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                        } else if recentMedicines.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "pill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                
                                Text("No verified medicines yet")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                Text("Scan your first medicine to see it here")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding()
                        } else {
                            ForEach(recentMedicines) { block in
                                NavigationLink(destination: ConsumerMedicineDetailView(block: block, selectedTab: $selectedTab)) {
                                    ConsumerMedicineCard(block: block)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Information Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Medicine Safety Tips")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        InfoCard(
                            title: "Always Verify",
                            description: "Always scan and verify your medicines before consuming",
                            icon: "checkmark.seal.fill",
                            color: .green
                        )
                        
                        InfoCard(
                            title: "Check Expiry",
                            description: "Ensure your medicine is not expired or damaged",
                            icon: "calendar",
                            color: .orange
                        )
                        
                        InfoCard(
                            title: "Report Suspicious",
                            description: "Report any suspicious medicine immediately",
                            icon: "exclamationmark.triangle.fill",
                            color: .red
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        fetchRecentMedicines()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                fetchRecentMedicines()
            }
        }
    }
    
    private func fetchRecentMedicines() {
        isLoading = true
        
        // Get medicines purchased by this consumer
        guard let userId = authService.user?.id else {
            isLoading = false
            return
        }
        
        // Filter blockchain for medicines currently held by this consumer
        let consumerMedicines = blockchainService.blockchain.blocks.filter { block in
            return block.data.currentHolder == userId || 
                   block.data.handoverHistory.contains(where: { $0.toEntity == userId })
        }
        
        // Sort by most recent first and take up to 5
        recentMedicines = Array(consumerMedicines.sorted { $0.timestamp > $1.timestamp }.prefix(5))
        
        isLoading = false
    }
}

struct InfoCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct ConsumerMedicineCard: View {
    let block: Block
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(block.data.drugName)
                    .font(.headline)
                
                Text("Manufacturer: \(block.data.manufacturerName)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Text(block.data.status.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: block.timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var statusColor: Color {
        switch block.data.status {
        case .registered:
            return .blue
        case .inTransit:
            return .orange
        case .delivered:
            return .blue
        case .verified:
            return .green
        case .suspicious:
            return .red
        case .sold:
            return .purple
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

struct ConsumerVerifyView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var blockchainService: BlockchainService
    @State private var isPresentingScanner = false
    @State private var scannedCode = ""
    @State private var scannedMedicine: Block?
    @State private var showingMedicineDetail = false
    @State private var error: String? = nil
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                
                Text("Verify Your Medicine")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Scan the QR code on your medicine to verify its authenticity and track its journey from manufacturer to you")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    isPresentingScanner = true
                }) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Scan QR Code")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Verify Medicine")
            .sheet(isPresented: $isPresentingScanner) {
                // In a real app, you would implement a camera QR scanner here
                // For now, just simulate scanning with a text field
                NavigationView {
                    VStack {
                        Text("Scan QR Code")
                            .font(.headline)
                        
                        // This is a simulation. In a real app, you'd use the camera
                        TextField("Enter QR Code/Block ID", text: $scannedCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        Button("Process QR Code") {
                            processScan()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    .navigationBarItems(trailing: Button("Cancel") {
                        isPresentingScanner = false
                    })
                }
            }
            .sheet(isPresented: $showingMedicineDetail) {
                if let medicine = scannedMedicine {
                    ConsumerMedicineDetailView(block: medicine, selectedTab: $selectedTab)
                        .environmentObject(authService)
                        .environmentObject(blockchainService)
                }
            }
        }
    }
    
    private func processScan() {
        guard !scannedCode.isEmpty else {
            error = "No QR code scanned"
            return
        }
        
        // Find medicine in blockchain by block ID
        if let medicine = blockchainService.getMedicineByBlockId(scannedCode) {
            scannedMedicine = medicine
            isPresentingScanner = false
            showingMedicineDetail = true
            error = nil
        } else {
            error = "Medicine not found in blockchain"
            isPresentingScanner = false
        }
    }
}

struct ConsumerMedicineDetailView: View {
    let block: Block
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var blockchainService: BlockchainService
    @State private var showingReportSheet = false
    @State private var isReporting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Binding var selectedTab: Int
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Authentication Banner
                ZStack {
                    Rectangle()
                        .fill(statusColor.opacity(0.2))
                        .cornerRadius(15)
                    
                    HStack {
                        Image(systemName: statusIcon)
                            .font(.system(size: 40))
                            .foregroundColor(statusColor)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(statusTitle)
                                .font(.headline)
                                .foregroundColor(statusColor)
                            
                            Text(statusMessage)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                .frame(height: 90)
                .padding(.horizontal)
                
                // Medicine Details
                GroupBox(label: Label("Medicine Details", systemImage: "pill.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Drug Name", value: block.data.drugName)
                        DetailRow(label: "Drug ID", value: block.data.drugId)
                        DetailRow(label: "Batch Number", value: block.data.batchNumber)
                        DetailRow(label: "Composition", value: block.data.composition)
                        DetailRow(label: "Manufacture Date", value: formatDate(block.data.manufactureDate, includeTime: false))
                        DetailRow(label: "Expiry Date", value: formatDate(block.data.expiryDate, includeTime: false))
                    }
                    .padding(.vertical)
                }
                .padding(.horizontal)
                
                // Manufacturer Details
                GroupBox(label: Label("Manufacturer Details", systemImage: "building.2.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Manufacturer", value: block.data.manufacturerName)
                        DetailRow(label: "Manufacturing Location", value: block.data.manufacturingLocation)
                    }
                    .padding(.vertical)
                }
                .padding(.horizontal)
                
                // Supply Chain Journey
                GroupBox(label: Label("Supply Chain Journey", systemImage: "arrow.triangle.swap")) {
                    if block.data.handoverHistory.isEmpty {
                        Text("No supply chain information available")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        Timeline(handoverHistory: block.data.handoverHistory)
                    }
                }
                .padding(.horizontal)
                
                // Report Button
                Button(action: {
                    showingReportSheet = true
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Report Suspicious")
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle(block.data.drugName)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingReportSheet) {
                ReportFormView(
                    block: block,
                    isReporting: $isReporting,
                    showAlert: $showAlert,
                    alertMessage: $alertMessage,
                    onReport: reportMedicine
                )
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Report Submission"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var statusColor: Color {
        switch block.data.status {
        case .registered, .delivered, .inTransit:
            return .orange
        case .verified, .sold:
            return .green
        case .suspicious:
            return .red
        }
    }
    
    private var statusIcon: String {
        switch block.data.status {
        case .registered, .delivered, .inTransit:
            return "exclamationmark.circle.fill"
        case .verified, .sold:
            return "checkmark.seal.fill"
        case .suspicious:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusTitle: String {
        switch block.data.status {
        case .registered, .delivered, .inTransit:
            return "Caution"
        case .verified, .sold:
            return "Verified Authentic"
        case .suspicious:
            return "Warning: Suspicious"
        }
    }
    
    private var statusMessage: String {
        switch block.data.status {
        case .registered, .delivered, .inTransit:
            return "This medicine is in transit and has not been verified by a pharmacy"
        case .verified, .sold:
            return "This medicine has been verified as authentic"
        case .suspicious:
            return "This medicine has been reported as suspicious"
        }
    }
    
    private func formatDate(_ date: Date, includeTime: Bool = true) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = includeTime ? .short : .none
        return formatter.string(from: date)
    }
    
    private func reportMedicine(reason: String) {
        guard let userId = authService.user?.id else {
            alertMessage = "User information not available"
            showAlert = true
            return
        }
        
        Task {
            do {
                try await blockchainService.reportSuspiciousMedicine(
                    blockId: block.id,
                    reporterId: userId,
                    reason: reason
                )
                
                DispatchQueue.main.async {
                    alertMessage = "Medicine reported successfully! Health authorities have been notified."
                    showAlert = true
                    isReporting = false
                    showingReportSheet = false
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "Failed to report medicine: \(error.localizedDescription)"
                    showAlert = true
                    isReporting = false
                }
            }
        }
    }
}

struct Timeline: View {
    let handoverHistory: [HandoverRecord]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(handoverHistory.enumerated()), id: \.element.id) { index, handover in
                VStack(spacing: 0) {
                    // Time and entities
                    HStack(alignment: .top, spacing: 15) {
                        // Timeline dot and line
                        VStack(spacing: 0) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                            
                            if index < handoverHistory.count - 1 {
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: 2)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(formatDate(handover.timestamp))
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("\(handover.fromEntity) → \(handover.toEntity)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if !handover.notes.isEmpty {
                                Text(handover.notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                            
                            Text("Location: \(handover.location)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                        }
                        .padding(.bottom, 15)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ReportFormView: View {
    let block: Block
    @Binding var isReporting: Bool
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    let onReport: (String) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var reason = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medicine Information")) {
                    Text(block.data.drugName)
                        .font(.headline)
                    Text("Batch: \(block.data.batchNumber)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("Report Details")) {
                    TextEditor(text: $reason)
                        .frame(minHeight: 100)
                    
                    Text("Please describe why you believe this medicine is suspicious")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section {
                    Button(action: {
                        if isFormValid {
                            isReporting = true
                            onReport(reason)
                        } else {
                            alertMessage = "Please provide a reason for reporting"
                            showAlert = true
                        }
                    }) {
                        if isReporting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Submit Report")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isReporting || !isFormValid)
                    .listRowBackground(isFormValid ? Color.red : Color.gray)
                }
            }
            .navigationTitle("Report Suspicious Medicine")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .disabled(isReporting)
        }
    }
    
    private var isFormValid: Bool {
        return reason.count > 10 // Require at least a brief explanation
    }
}

struct ConsumerHistoryView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var blockchainService: BlockchainService
    @State private var medicines: [Block] = []
    @State private var isLoading = true
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading history...")
                } else if medicines.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No medicine history found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Medicines you verify will appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List(medicines) { block in
                        NavigationLink(destination: ConsumerMedicineDetailView(block: block, selectedTab: $selectedTab)) {
                            ConsumerMedicineCard(block: block)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Medicine History")
            .onAppear {
                fetchMedicines()
            }
            .refreshable {
                fetchMedicines()
            }
        }
    }
    
    private func fetchMedicines() {
        isLoading = true
        
        // Get medicines verified by this consumer
        guard let userId = authService.user?.id else {
            isLoading = false
            return
        }
        
        // Filter blockchain for medicines where the consumer is involved
        let consumerMedicines = blockchainService.blockchain.blocks.filter { block in
            return block.data.currentHolder == userId || 
                   block.data.handoverHistory.contains(where: { $0.toEntity == userId })
        }
        
        // Sort by most recent first
        medicines = consumerMedicines.sorted { $0.timestamp > $1.timestamp }
        
        isLoading = false
    }
}

struct ConsumerProfileView: View {
    @EnvironmentObject var authService: AuthService
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account Information")) {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(authService.user?.fullName ?? "User")
                                .font(.headline)
                            
                            Text(authService.user?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("Consumer")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                        .padding(.leading, 10)
                    }
                    .padding(.vertical, 10)
                }
                
                Section(header: Text("Settings")) {
                    NavigationLink(destination: Text("Personal Information")) {
                        Label("Personal Information", systemImage: "person.crop.square")
                    }
                    
                    NavigationLink(destination: Text("Notifications")) {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                    
                    NavigationLink(destination: Text("Privacy & Security")) {
                        Label("Privacy & Security", systemImage: "lock.fill")
                    }
                }
                
                Section(header: Text("Support")) {
                    NavigationLink(destination: Text("Help Center")) {
                        Label("Help Center", systemImage: "questionmark.circle.fill")
                    }
                    
                    NavigationLink(destination: Text("Contact Support")) {
                        Label("Contact Support", systemImage: "envelope.fill")
                    }
                    
                    NavigationLink(destination: Text("About Medi")) {
                        Label("About Medi", systemImage: "info.circle.fill")
                    }
                }
                
                Section {
                    Button(action: {
                        do {
                            try authService.signOut()
                        } catch {
                            print("Error signing out: \(error.localizedDescription)")
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct ConsumerDashboard_Previews: PreviewProvider {
    static var previews: some View {
        ConsumerDashboard()
            .environmentObject(AuthService())
            .environmentObject(BlockchainService())
    }
}