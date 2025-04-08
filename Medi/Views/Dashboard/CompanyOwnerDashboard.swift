import SwiftUI
// Import shared components from Common

struct CompanyOwnerDashboard: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var blockchainService = BlockchainService()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CompanyHomeView()
                .environmentObject(authService)
                .environmentObject(blockchainService)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            RegisterMedicineView()
                .environmentObject(authService)
                .environmentObject(blockchainService)
                .tabItem {
                    Label("Register", systemImage: "plus.circle.fill")
                }
                .tag(1)
            
            MedicineHistoryView()
                .environmentObject(authService)
                .environmentObject(blockchainService)
                .tabItem {
                    Label("History", systemImage: "list.bullet.clipboard.fill")
                }
                .tag(2)
            
            ProfileView()
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

struct CompanyHomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var blockchainService: BlockchainService
    @State private var recentMedicines: [Block] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Company Dashboard")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            if let user = authService.user {
                                Text("Welcome, \(user.fullName)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                    .padding()
                    
                    // Stats Card
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Medicine Statistics")
                            .font(.headline)
                        
                        if isLoading {
                            HStack(spacing: 20) {
                                ForEach(0..<3) { _ in
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(10)
                                }
                            }
                        } else {
                            HStack(spacing: 20) {
                                CompanyStatCard(title: "Registered", value: "\(recentMedicines.count)", icon: "doc.text.fill", color: .blue)
                                CompanyStatCard(title: "In Transit", value: "\(inTransitCount)", icon: "shippingbox.fill", color: .orange)
                                CompanyStatCard(title: "Delivered", value: "\(deliveredCount)", icon: "checkmark.circle.fill", color: .green)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Recent Medicines
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Recently Registered Medicines")
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
                            Text("No registered medicines found")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(recentMedicines) { block in
                                MedicineCard(block: block)
                            }
                        }
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
    
    private var inTransitCount: Int {
        return recentMedicines.filter { $0.data.status == .inTransit }.count
    }
    
    private var deliveredCount: Int {
        return recentMedicines.filter { $0.data.status == .delivered || $0.data.status == .verified }.count
    }
    
    private func fetchRecentMedicines() {
        isLoading = true
        
        // Get medicines registered by this company
        guard let userId = authService.user?.id else {
            isLoading = false
            return
        }
        
        // Filter blockchain for medicines registered by this company
        let companyMedicines = blockchainService.blockchain.blocks.filter { block in
            return block.data.manufacturerName == authService.user?.fullName || block.data.currentHolder == userId
        }
        
        // Sort by most recent first and take up to 5
        recentMedicines = Array(companyMedicines.sorted { $0.timestamp > $1.timestamp }.prefix(5))
        
        isLoading = false
    }
}

struct CompanyStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct MedicineCard: View {
    let block: Block
    
    var body: some View {
        NavigationLink(destination: MedicineDetailView(block: block)) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(block.data.drugName)
                        .font(.headline)
                    
                    Text("Batch: \(block.data.batchNumber)")
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
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        switch block.data.status {
        case .registered:
            return .blue
        case .inTransit:
            return .orange
        case .delivered, .verified:
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

struct RegisterMedicineView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var blockchainService: BlockchainService
    
    @State private var drugId = ""
    @State private var batchNumber = ""
    @State private var manufacturerName = ""
    @State private var drugName = ""
    @State private var composition = ""
    @State private var manufactureDate = Date()
    @State private var expiryDate = Date().addingTimeInterval(31536000) // 1 year from now
    @State private var manufacturingLocation = ""
    
    @State private var isRegistering = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var generatedQRCode: UIImage?
    @State private var qrCodeURL = ""
    @State private var showQRCode = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medicine Details")) {
                    TextField("Drug ID", text: $drugId)
                    TextField("Batch Number", text: $batchNumber)
                    TextField("Drug Name", text: $drugName)
                    TextField("Composition", text: $composition)
                }
                
                Section(header: Text("Manufacturer Details")) {
                    TextField("Manufacturer Name", text: $manufacturerName)
                        .onAppear {
                            if manufacturerName.isEmpty {
                                manufacturerName = authService.user?.fullName ?? ""
                            }
                        }
                    TextField("Manufacturing Location", text: $manufacturingLocation)
                }
                
                Section(header: Text("Dates")) {
                    DatePicker("Manufacture Date", selection: $manufactureDate, displayedComponents: .date)
                    DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                }
                
                Section {
                    Button(action: registerMedicine) {
                        if isRegistering {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Register Medicine")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isRegistering || !isFormValid)
                    .listRowBackground(isFormValid ? Color.blue : Color.gray)
                }
            }
            .navigationTitle("Register Medicine")
            .disabled(isRegistering)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Medicine Registration"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showQRCode) {
                QRCodeView(qrCodeImage: generatedQRCode, qrCodeURL: qrCodeURL)
            }
        }
    }
    
    private var isFormValid: Bool {
        return !drugId.isEmpty && 
               !batchNumber.isEmpty && 
               !drugName.isEmpty && 
               !composition.isEmpty && 
               !manufacturerName.isEmpty && 
               !manufacturingLocation.isEmpty
    }
    
    private func registerMedicine() {
        guard let userId = authService.user?.id else {
            alertMessage = "User information not available"
            showAlert = true
            return
        }
        
        isRegistering = true
        
        Task {
            do {
                let qrURL = try await blockchainService.registerMedicine(
                    drugId: drugId,
                    batchNumber: batchNumber,
                    manufacturerName: manufacturerName,
                    drugName: drugName,
                    composition: composition,
                    manufactureDate: manufactureDate,
                    expiryDate: expiryDate,
                    manufacturingLocation: manufacturingLocation,
                    userId: userId
                )
                
                // Generate QR code for display
                qrCodeURL = qrURL
                let qrGenerator = QRCodeGenerator()
                let qrImage = qrGenerator.generateQRCode(from: qrURL)
                
                DispatchQueue.main.async {
                    generatedQRCode = qrImage
                    alertMessage = "Medicine registered successfully!"
                    showAlert = true
                    isRegistering = false
                    
                    // Show QR code after alert is dismissed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showQRCode = true
                    }
                    
                    // Reset form
                    resetForm()
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "Failed to register medicine: \(error.localizedDescription)"
                    showAlert = true
                    isRegistering = false
                }
            }
        }
    }
    
    private func resetForm() {
        drugId = ""
        batchNumber = ""
        drugName = ""
        composition = ""
        // Keep manufacturer name and location
        manufactureDate = Date()
        expiryDate = Date().addingTimeInterval(31536000)
    }
}

struct QRCodeView: View {
    let qrCodeImage: UIImage?
    let qrCodeURL: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = qrCodeImage {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding()
                } else {
                    Image(systemName: "qrcode")
                        .font(.system(size: 100))
                        .foregroundColor(.gray)
                }
                
                Text("QR Code Generated")
                    .font(.headline)
                
                Text("This QR code links to your registered medicine in the blockchain.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text(qrCodeURL)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding()
                
                Button(action: {
                    // In a real app, you would implement printing or saving functionality
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Print QR Code")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Medicine QR Code")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MedicineHistoryView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var blockchainService: BlockchainService
    @State private var medicines: [Block] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading medicines...")
                } else if medicines.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No registered medicines found")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List(medicines) { medicine in
                        MedicineCard(block: medicine)
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
        
        // Get medicines registered by this company
        guard let userId = authService.user?.id else {
            isLoading = false
            return
        }
        
        // Filter blockchain for medicines registered by this company
        let companyMedicines = blockchainService.blockchain.blocks.filter { block in
            return block.data.manufacturerName == authService.user?.fullName || block.data.currentHolder == userId
        }
        
        // Sort by most recent first
        medicines = companyMedicines.sorted { $0.timestamp > $1.timestamp }
        
        isLoading = false
    }
}

struct MedicineDetailView: View {
    let block: Block
    @EnvironmentObject var blockchainService: BlockchainService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // QR Code
                HStack {
                    Spacer()
                    VStack {
                        // In a real app, you would load the QR code from the URL
                        let qrGenerator = QRCodeGenerator()
                        let qrImage = qrGenerator.generateQRCode(from: block.id)
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 150, height: 150)
                            .padding()
                        
                        Text("Block ID: \(block.id.prefix(8))...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                
                // Medicine Details
                GroupBox(label: Label("Medicine Details", systemImage: "pill.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Drug Name", value: block.data.drugName)
                        DetailRow(label: "Drug ID", value: block.data.drugId)
                        DetailRow(label: "Batch Number", value: block.data.batchNumber)
                        DetailRow(label: "Composition", value: block.data.composition)
                        DetailRow(label: "Manufacture Date", value: formatDate(block.data.manufactureDate))
                        DetailRow(label: "Expiry Date", value: formatDate(block.data.expiryDate))
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
                
                // Current Status
                GroupBox(label: Label("Current Status", systemImage: "info.circle.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Status", value: block.data.status.rawValue)
                        DetailRow(label: "Current Location", value: block.data.currentLocation)
                        DetailRow(label: "Current Holder", value: block.data.currentHolder)
                        DetailRow(label: "Registered On", value: formatDate(block.timestamp))
                    }
                    .padding(.vertical)
                }
                .padding(.horizontal)
                
                // Supply Chain History
                if !block.data.handoverHistory.isEmpty {
                    GroupBox(label: Label("Supply Chain History", systemImage: "arrow.triangle.swap")) {
                        ForEach(block.data.handoverHistory) { handover in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(formatDate(handover.timestamp))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("\(handover.fromEntity) → \(handover.toEntity)")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                
                                if !handover.notes.isEmpty {
                                    Text(handover.notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if handover.id != block.data.handoverHistory.last?.id {
                                    Divider()
                                        .padding(.vertical, 5)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Blockchain Details
                GroupBox(label: Label("Blockchain Details", systemImage: "link")) {
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Previous Hash", value: block.previousHash.prefix(15) + "...")
                        DetailRow(label: "Block Hash", value: block.hash.prefix(15) + "...")
                    }
                    .padding(.vertical)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle(block.data.drugName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account Information")) {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(authService.user?.fullName ?? "Company")
                                .font(.headline)
                            
                            Text(authService.user?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("Company Owner")
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
                    NavigationLink(destination: Text("Company Information")) {
                        Label("Company Information", systemImage: "building.2")
                    }
                    
                    NavigationLink(destination: Text("Security")) {
                        Label("Security", systemImage: "lock.fill")
                    }
                    
                    NavigationLink(destination: Text("Preferences")) {
                        Label("Preferences", systemImage: "gear")
                    }
                }
                
                Section(header: Text("Support")) {
                    NavigationLink(destination: Text("Help Center")) {
                        Label("Help Center", systemImage: "questionmark.circle.fill")
                    }
                    
                    NavigationLink(destination: Text("Contact Support")) {
                        Label("Contact Support", systemImage: "envelope.fill")
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

struct CompanyOwnerDashboard_Previews: PreviewProvider {
    static var previews: some View {
        CompanyOwnerDashboard()
            .environmentObject(AuthService())
            .environmentObject(BlockchainService())
    }
} 