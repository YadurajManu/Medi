import SwiftUI
import FirebaseFirestore

// Delivery Model
struct Delivery: Identifiable {
    var id: String
    var orderNumber: String
    var origin: String
    var destination: String
    var status: DeliveryStatus
    var timestamp: Date
    
    enum DeliveryStatus: String, Codable {
        case pending = "Pending"
        case inTransit = "In Transit"
        case delivered = "Delivered"
        case cancelled = "Cancelled"
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .inTransit: return .blue
            case .delivered: return .green
            case .cancelled: return .red
            }
        }
    }
}

struct TransportationDashboard: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var blockchainService = BlockchainService()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TransportationHomeView()
                .environmentObject(authService)
                .environmentObject(blockchainService)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            TransportationOrdersView()
                .environmentObject(authService)
                .environmentObject(blockchainService)
                .tabItem {
                    Label("Orders", systemImage: "list.bullet.clipboard.fill")
                }
                .tag(1)
            
            TransportationScannerView()
                .environmentObject(authService)
                .environmentObject(blockchainService)
                .tabItem {
                    Label("Scan", systemImage: "qrcode.viewfinder")
                }
                .tag(2)
            
            TransportationProfileView()
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

struct TransportationHomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var blockchainService: BlockchainService
    @State private var deliveries: [Block] = []
    @State private var isLoading = true
    @State private var error: String? = nil
    
    // Stats
    @State private var pendingCount = 0
    @State private var completedCount = 0
    @State private var totalCount = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Transportation Dashboard")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Manage your deliveries")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "truck.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                    .padding()
                    
                    // Stats Card
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Today's Stats")
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
                                StatCard(title: "Pending", value: "\(pendingCount)", icon: "clock.fill", color: .orange)
                                StatCard(title: "Completed", value: "\(completedCount)", icon: "checkmark.circle.fill", color: .green)
                                StatCard(title: "Total", value: "\(totalCount)", icon: "chart.bar.fill", color: .blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Recent Deliveries
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Recent Deliveries")
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
                        } else if deliveries.isEmpty {
                            Text("No deliveries found")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(deliveries) { block in
                                NavigationLink(destination: TransportationDeliveryDetailView(block: block)) {
                                    TransportationDeliveryCard(block: block)
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
                        fetchDeliveries()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                fetchDeliveries()
            }
        }
    }
    
    private func fetchDeliveries() {
        isLoading = true
        
        // Get deliveries assigned to this transporter
        guard let userId = authService.user?.id else {
            isLoading = false
            return
        }
        
        // Filter blockchain for medicines currently held by this transporter
        // or where the transporter is in the handover history
        let transporterMedicines = blockchainService.blockchain.blocks.filter { block in
            return block.data.currentHolder == userId || 
                   block.data.handoverHistory.contains(where: { $0.fromEntity == userId || $0.toEntity == userId })
        }
        
        // Sort by most recent first
        deliveries = transporterMedicines.sorted { $0.timestamp > $1.timestamp }
        
        // Update stats
        pendingCount = deliveries.filter { $0.data.status == .inTransit || $0.data.status == .registered }.count
        completedCount = deliveries.filter { $0.data.status == .delivered || $0.data.status == .verified }.count
        totalCount = deliveries.count
        
        isLoading = false
    }
}

struct TransportationDeliveryCard: View {
    let block: Block
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(block.data.drugName)
                    .font(.headline)
                
                Text("From: \(block.data.manufacturingLocation) • To: \(block.data.currentLocation)")
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

struct TransportationOrdersView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var blockchainService: BlockchainService
    @State private var deliveries: [Block] = []
    @State private var isLoading = true
    @State private var error: String? = nil
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading orders...")
                } else if deliveries.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No deliveries found")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List(deliveries) { block in
                        NavigationLink(destination: TransportationDeliveryDetailView(block: block)) {
                            TransportationDeliveryCard(block: block)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Orders")
            .onAppear {
                fetchDeliveries()
            }
            .refreshable {
                fetchDeliveries()
            }
        }
    }
    
    private func fetchDeliveries() {
        isLoading = true
        
        // Get deliveries assigned to this transporter
        guard let userId = authService.user?.id else {
            isLoading = false
            return
        }
        
        // Filter blockchain for medicines currently held by this transporter
        let transporterMedicines = blockchainService.blockchain.blocks.filter { block in
            return block.data.currentHolder == userId || 
                   block.data.handoverHistory.contains(where: { $0.fromEntity == userId || $0.toEntity == userId })
        }
        
        // Sort by most recent first
        deliveries = transporterMedicines.sorted { $0.timestamp > $1.timestamp }
        
        isLoading = false
    }
}

struct TransportationDeliveryDetailView: View {
    let block: Block
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var blockchainService: BlockchainService
    @State private var showingHandoverSheet = false
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
                        DetailRow(label: "Manufacturer", value: block.data.manufacturerName)
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
                GroupBox {
                    if block.data.currentHolder == authService.user?.id {
                        Button(action: {
                            showingHandoverSheet = true
                        }) {
                            HStack {
                                Spacer()
                                Text("Update Delivery Status")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    } else {
                        Text("This medicine is not currently in your possession.")
                            .font(.callout)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle(block.data.drugName)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingHandoverSheet) {
                HandoverFormView(
                    block: block,
                    isUpdating: $isUpdating,
                    showAlert: $showAlert,
                    alertMessage: $alertMessage,
                    onHandover: updateHandover
                )
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Delivery Update"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func updateHandover(toEntity: String, location: String, notes: String) {
        guard let userId = authService.user?.id else {
            alertMessage = "User information not available"
            showAlert = true
            return
        }
        
        Task {
            do {
                try await blockchainService.updateMedicineHandover(
                    blockId: block.id,
                    fromEntity: userId,
                    toEntity: toEntity,
                    location: location,
                    notes: notes
                )
                
                DispatchQueue.main.async {
                    alertMessage = "Delivery status updated successfully!"
                    showAlert = true
                    isUpdating = false
                    showingHandoverSheet = false
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "Failed to update delivery: \(error.localizedDescription)"
                    showAlert = true
                    isUpdating = false
                }
            }
        }
    }
}

struct HandoverFormView: View {
    let block: Block
    @Binding var isUpdating: Bool
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    let onHandover: (String, String, String) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var toEntity = ""
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
                
                Section(header: Text("Handover Details")) {
                    TextField("Recipient ID or Name", text: $toEntity)
                    TextField("Current Location", text: $location)
                    TextField("Notes", text: $notes)
                }
                
                Section {
                    Button(action: {
                        if isFormValid {
                            isUpdating = true
                            onHandover(toEntity, location, notes)
                        } else {
                            alertMessage = "Please fill in all required fields"
                            showAlert = true
                        }
                    }) {
                        if isUpdating {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Update Delivery Status")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isUpdating || !isFormValid)
                    .listRowBackground(isFormValid ? Color.blue : Color.gray)
                }
            }
            .navigationTitle("Update Delivery")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .disabled(isUpdating)
        }
    }
    
    private var isFormValid: Bool {
        return !toEntity.isEmpty && !location.isEmpty
    }
}

struct TransportationScannerView: View {
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
                
                Text("Scan Medicine QR Code")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Scan a QR code to view medicine details and update delivery status")
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
                    TransportationDeliveryDetailView(block: medicine)
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

struct StatCard: View {
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

struct TransportationProfileView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(authService.user?.fullName ?? "User")
                                .font(.headline)
                            
                            Text(authService.user?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 10)
                    }
                    .padding(.vertical, 10)
                }
                
                Section(header: Text("Settings")) {
                    NavigationLink(destination: VehicleInformationView()) {
                        Label("Vehicle Information", systemImage: "car.fill")
                    }
                    
                    NavigationLink(destination: Text("Delivery Preferences")) {
                        Label("Delivery Preferences", systemImage: "gear")
                    }
                    
                    NavigationLink(destination: Text("Payment Methods")) {
                        Label("Payment Methods", systemImage: "creditcard.fill")
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
                            // You could add an alert here to show the error to the user
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

struct VehicleInformationView: View {
    @State private var vehicleType = ""
    @State private var licensePlate = ""
    @State private var vehicleModel = ""
    @State private var vehicleYear = ""
    
    var body: some View {
        Form {
            Section(header: Text("Vehicle Details")) {
                TextField("Vehicle Type", text: $vehicleType)
                TextField("License Plate", text: $licensePlate)
                TextField("Model", text: $vehicleModel)
                TextField("Year", text: $vehicleYear)
            }
            
            Section {
                Button(action: {
                    // Save vehicle information to database
                }) {
                    Text("Save Information")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.blue)
            }
        }
        .navigationTitle("Vehicle Information")
    }
}

struct TransportationDashboard_Previews: PreviewProvider {
    static var previews: some View {
        TransportationDashboard()
            .environmentObject(AuthService())
    }
} 