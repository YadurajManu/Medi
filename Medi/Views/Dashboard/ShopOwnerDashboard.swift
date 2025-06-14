import SwiftUI

struct ShopOwnerDashboard: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var blockchainService = BlockchainService()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ShopHomeView()
                .environmentObject(authService)
                .environmentObject(blockchainService)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            ShopInventoryView()
                .environmentObject(authService)
                .environmentObject(blockchainService)
                .tabItem {
                    Label("Inventory", systemImage: "list.bullet.clipboard.fill")
                }
                .tag(1)
            
            ShopScannerView()
                .environmentObject(authService)
                .environmentObject(blockchainService)
                .tabItem {
                    Label("Verify", systemImage: "qrcode.viewfinder")
                }
                .tag(2)
            
            ShopProfileView()
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

struct ShopHomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var blockchainService: BlockchainService
    @State private var medicines: [Block] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Shop Dashboard")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            if let user = authService.user {
                                Text("Welcome, \(user.fullName)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "bag.fill")
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
                                ShopStatCard(title: "Verified", value: "\(verifiedCount)", icon: "checkmark.circle.fill", color: .green)
                                ShopStatCard(title: "Pending", value: "\(pendingCount)", icon: "clock.fill", color: .orange)
                                ShopStatCard(title: "Suspicious", value: "\(suspiciousCount)", icon: "exclamationmark.triangle.fill", color: .red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
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
                        } else if medicines.isEmpty {
                            Text("No verified medicines found")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(medicines) { block in
                                NavigationLink(destination: ShopMedicineDetailView(block: block)) {
                                    ShopMedicineCard(block: block)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        fetchMedicines()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                fetchMedicines()
            }
        }
    }
    
    private var verifiedCount: Int {
        return medicines.filter { $0.data.status == .verified }.count
    }
    
    private var pendingCount: Int {
        return medicines.filter { $0.data.status == .inTransit || $0.data.status == .delivered }.count
    }
    
    private var suspiciousCount: Int {
        return medicines.filter { $0.data.status == .suspicious }.count
    }
    
    private func fetchMedicines() {
        isLoading = true
        
        // Get medicines held by this shop
        guard let userId = authService.user?.id else {
            isLoading = false
            return
        }
        
        // Filter blockchain for medicines currently held by this shop
        let shopMedicines = blockchainService.blockchain.blocks.filter { block in
            return block.data.currentHolder == userId || 
                   block.data.handoverHistory.contains(where: { $0.toEntity == userId })
        }
        
        // Sort by most recent first
        medicines = shopMedicines.sorted { $0.timestamp > $1.timestamp }
        
        isLoading = false
    }
}

struct ShopStatCard: View {
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

struct ShopMedicineCard: View {
    let block: Block
    
    var body: some View {
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

struct ShopInventoryView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var blockchainService: BlockchainService
    @State private var medicines: [Block] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading inventory...")
                } else if medicines.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bag")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No medicines in inventory")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List(medicines) { block in
                        NavigationLink(destination: ShopMedicineDetailView(block: block)) {
                            ShopMedicineCard(block: block)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Inventory")
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
        
        // Get medicines held by this shop
        guard let userId = authService.user?.id else {
            isLoading = false
            return
        }
        
        // Filter blockchain for medicines currently held by this shop
        let shopMedicines = blockchainService.blockchain.blocks.filter { block in
            return block.data.currentHolder == userId
        }
        
        // Sort by most recent first
        medicines = shopMedicines.sorted { $0.timestamp > $1.timestamp }
        
        isLoading = false
    }
}

struct ShopMedicineDetailView: View {
    let block: Block
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var blockchainService: BlockchainService
    @State private var showingVerificationSheet = false
    @State private var showingSellSheet = false
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // QR Code
                HStack {
                    Spacer()
                    VStack {
                        // Generate QR code
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
                
                // Current Status
                GroupBox(label: Label("Current Status", systemImage: "info.circle.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Status", value: block.data.status.rawValue)
                        DetailRow(label: "Current Location", value: block.data.currentLocation)
                        DetailRow(label: "Current Holder", value: block.data.currentHolder == authService.user?.id ?? "" ? "You" : block.data.currentHolder)
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
                
                // Actions
                if block.data.currentHolder == authService.user?.id {
                    GroupBox {
                        VStack(spacing: 15) {
                            if block.data.status == .inTransit || block.data.status == .delivered {
                                Button(action: {
                                    showingVerificationSheet = true
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("Verify Medicine")
                                            .fontWeight(.semibold)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                            
                            if block.data.status == .verified {
                                Button(action: {
                                    showingSellSheet = true
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("Sell to Customer")
                                            .fontWeight(.semibold)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                            
                            Button(action: {
                                reportSuspicious()
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Report Suspicious")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    GroupBox {
                        Text("This medicine is not currently in your inventory.")
                            .font(.callout)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle(block.data.drugName)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingVerificationSheet) {
                VerificationFormView(
                    block: block,
                    isUpdating: $isUpdating,
                    showAlert: $showAlert,
                    alertMessage: $alertMessage,
                    onVerify: verifyMedicine
                )
            }
            .sheet(isPresented: $showingSellSheet) {
                SellFormView(
                    block: block,
                    isUpdating: $isUpdating,
                    showAlert: $showAlert,
                    alertMessage: $alertMessage,
                    onSell: sellMedicine
                )
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Medicine Update"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func formatDate(_ date: Date, includeTime: Bool = true) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = includeTime ? .short : .none
        return formatter.string(from: date)
    }
    
    private func verifyMedicine(location: String, notes: String) {
        guard let userId = authService.user?.id else {
            alertMessage = "User information not available"
            showAlert = true
            return
        }
        
        Task {
            do {
                try await blockchainService.verifyMedicine(
                    blockId: block.id,
                    shopId: userId,
                    location: location
                )
                
                DispatchQueue.main.async {
                    alertMessage = "Medicine verified successfully!"
                    showAlert = true
                    isUpdating = false
                    showingVerificationSheet = false
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "Failed to verify medicine: \(error.localizedDescription)"
                    showAlert = true
                    isUpdating = false
                }
            }
        }
    }
    
    private func sellMedicine(customerId: String) {
        guard let userId = authService.user?.id else {
            alertMessage = "User information not available"
            showAlert = true
            return
        }
        
        Task {
            do {
                try await blockchainService.markMedicineAsSold(
                    blockId: block.id,
                    shopId: userId,
                    customerId: customerId
                )
                
                DispatchQueue.main.async {
                    alertMessage = "Medicine marked as sold successfully!"
                    showAlert = true
                    isUpdating = false
                    showingSellSheet = false
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "Failed to update medicine: \(error.localizedDescription)"
                    showAlert = true
                    isUpdating = false
                }
            }
        }
    }
    
    private func reportSuspicious() {
        guard let userId = authService.user?.id else {
            alertMessage = "User information not available"
            showAlert = true
            return
        }
        
        // Show an alert to confirm before reporting
        alertMessage = "Are you sure you want to report this medicine as suspicious? This action cannot be undone."
        showAlert = true
        
        // In a real app, you would implement a confirmation dialog
        // For now, just simulate reporting after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            Task {
                do {
                    try await blockchainService.reportSuspiciousMedicine(
                        blockId: block.id,
                        reporterId: userId,
                        reason: "Reported by shop owner"
                    )
                    
                    DispatchQueue.main.async {
                        alertMessage = "Medicine reported as suspicious!"
                        showAlert = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        alertMessage = "Failed to report medicine: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            }
        }
    }
}

struct VerificationFormView: View {
    let block: Block
    @Binding var isUpdating: Bool
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    let onVerify: (String, String) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var location = ""
    @State private var notes = ""
    
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
                
                Section(header: Text("Verification Details")) {
                    TextField("Current Location", text: $location)
                    TextField("Notes (Optional)", text: $notes)
                }
                
                Section {
                    Button(action: {
                        if isFormValid {
                            isUpdating = true
                            onVerify(location, notes)
                        } else {
                            alertMessage = "Please fill in all required fields"
                            showAlert = true
                        }
                    }) {
                        if isUpdating {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Verify Medicine")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isUpdating || !isFormValid)
                    .listRowBackground(isFormValid ? Color.blue : Color.gray)
                }
            }
            .navigationTitle("Verify Medicine")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .disabled(isUpdating)
        }
    }
    
    private var isFormValid: Bool {
        return !location.isEmpty
    }
}

struct SellFormView: View {
    let block: Block
    @Binding var isUpdating: Bool
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    let onSell: (String) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var customerId = "consumer-" // Prefill with consumer prefix
    
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
                
                Section(header: Text("Customer Information")) {
                    TextField("Customer ID", text: $customerId)
                    Text("Enter customer ID or scan customer's QR code")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section {
                    Button(action: {
                        if isFormValid {
                            isUpdating = true
                            onSell(customerId)
                        } else {
                            alertMessage = "Please enter a valid customer ID"
                            showAlert = true
                        }
                    }) {
                        if isUpdating {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sell to Customer")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isUpdating || !isFormValid)
                    .listRowBackground(isFormValid ? Color.green : Color.gray)
                }
            }
            .navigationTitle("Sell Medicine")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .disabled(isUpdating)
        }
    }
    
    private var isFormValid: Bool {
        return customerId.count > 8 // Basic validation
    }
}

struct ShopScannerView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var blockchainService: BlockchainService
    @State private var isPresentingScanner = false
    @State private var scannedCode = ""
    @State private var scannedMedicine: Block?
    @State private var showingMedicineDetail = false
    @State private var error: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                
                Text("Verify Medicine")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Scan a QR code to verify medicine authenticity and add it to your inventory")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    isPresentingScanner = true
                }) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Start Scanning")
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
            .navigationTitle("QR Scanner")
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
                    ShopMedicineDetailView(block: medicine)
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

struct ShopProfileView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account Information")) {
                    HStack {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(authService.user?.fullName ?? "Shop")
                                .font(.headline)
                            
                            Text(authService.user?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("Shop Owner")
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
                    NavigationLink(destination: Text("Shop Information")) {
                        Label("Shop Information", systemImage: "building")
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

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ShopOwnerDashboard_Previews: PreviewProvider {
    static var previews: some View {
        ShopOwnerDashboard()
            .environmentObject(AuthService())
            .environmentObject(BlockchainService())
    }
} 