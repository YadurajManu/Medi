import SwiftUI

struct MedicineListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var blockchainService = BlockchainService()
    
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var selectedMedicine: Medicine? = nil
    @State private var showMedicineDetails = false
    
    var body: some View {
        ZStack {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack {
                if isLoading && blockchainService.medicines.isEmpty {
                    // Loading indicator
                    ProgressView("Loading medicines...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if blockchainService.medicines.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "pill.circle")
                            .font(.system(size: 70))
                            .foregroundColor(.gray.opacity(0.7))
                        
                        Text("No Medicines Registered")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Register medicines to see them listed here")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    // List of medicines
                    List {
                        ForEach(blockchainService.medicines) { medicine in
                            MedicineListItemView(medicine: medicine)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedMedicine = medicine
                                    showMedicineDetails = true
                                }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .refreshable {
                        await loadMedicines()
                    }
                }
            }
            .navigationTitle("Medicine Inventory")
            .onAppear {
                Task {
                    await loadMedicines()
                }
            }
            .onChange(of: blockchainService.errorMessage) { message in
                if !message.isEmpty {
                    alertTitle = "Error"
                    alertMessage = message
                    showAlert = true
                    
                    // Clear message
                    DispatchQueue.main.async {
                        blockchainService.errorMessage = ""
                    }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showMedicineDetails) {
                if let medicine = selectedMedicine {
                    MedicineDetailView(medicine: medicine)
                        .environmentObject(blockchainService)
                }
            }
        }
    }
    
    private func loadMedicines() async {
        guard let currentUser = authService.user else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            _ = try await blockchainService.getMedicinesByOwner(ownerId: currentUser.id)
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.alertTitle = "Error"
                self.alertMessage = error.localizedDescription
                self.showAlert = true
            }
        }
    }
}

struct MedicineListItemView: View {
    let medicine: Medicine
    
    var body: some View {
        HStack(spacing: 16) {
            // Medicine icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "pill.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            
            // Medicine info
            VStack(alignment: .leading, spacing: 4) {
                Text(medicine.drugName)
                    .font(.headline)
                
                Text(medicine.drugID)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Text("Status:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(medicine.status.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor(medicine.status).opacity(0.2))
                        .foregroundColor(statusColor(medicine.status))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Expiry indicator
            VStack(alignment: .center, spacing: 2) {
                Text("Expires")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(formattedDate(medicine.expiryDate))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isExpiringSoon(medicine.expiryDate) ? .orange : .green)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func isExpiringSoon(_ date: Date) -> Bool {
        let threshold = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        return date < threshold
    }
    
    private func statusColor(_ status: MedicineStatus) -> Color {
        switch status {
        case .registered:
            return .blue
        case .inTransit:
            return .orange
        case .delivered:
            return .green
        case .verified:
            return .green
        case .sold:
            return .purple
        case .flagged:
            return .red
        }
    }
}

struct MedicineDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var blockchainService: BlockchainService
    
    let medicine: Medicine
    
    @State private var isLoading = false
    @State private var blockchainEntries: [BlockchainEntry] = []
    @State private var isBlockchainValid = true
    @State private var showQRCode = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // QR Code section
                    VStack {
                        if let qrCodeURL = medicine.qrCodeURL, let url = URL(string: qrCodeURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 200, height: 200)
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 200, height: 200)
                            }
                            .onTapGesture {
                                showQRCode = true
                            }
                        } else {
                            Image(systemName: "qrcode")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 200)
                                .foregroundColor(.gray)
                        }
                        
                        Text("Drug ID: \(medicine.drugID)")
                            .font(.headline)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    
                    // Medicine information
                    Group {
                        SectionTitle(title: "Medicine Details")
                        
                        DetailItem(label: "Drug Name", value: medicine.drugName)
                        DetailItem(label: "Manufacturer", value: medicine.manufacturerName)
                        DetailItem(label: "Composition", value: medicine.composition)
                        DetailItem(label: "Manufacturing Location", value: medicine.manufacturingLocation)
                        DetailItem(label: "Status", value: medicine.status.rawValue.capitalized)
                        
                        HStack {
                            DetailItem(label: "Manufacture Date", value: formattedDate(medicine.manufactureDate))
                            Spacer()
                            DetailItem(label: "Expiry Date", value: formattedDate(medicine.expiryDate))
                        }
                    }
                    
                    // Blockchain verification
                    Group {
                        SectionTitle(title: "Blockchain Verification")
                        
                        HStack {
                            Image(systemName: isBlockchainValid ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                                .foregroundColor(isBlockchainValid ? .green : .red)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(isBlockchainValid ? "Blockchain Valid" : "Blockchain Invalid")
                                    .font(.headline)
                                    .foregroundColor(isBlockchainValid ? .green : .red)
                                
                                Text(isBlockchainValid ? "This medicine's blockchain is valid and has not been tampered with." : "Warning: This medicine's blockchain may have been tampered with.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if isLoading {
                                ProgressView()
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(isBlockchainValid ? .systemGreen : .systemRed).opacity(0.1))
                        )
                    }
                    
                    // Blockchain history
                    Group {
                        SectionTitle(title: "Blockchain History")
                        
                        if blockchainEntries.isEmpty {
                            Text("No blockchain history available")
                                .foregroundColor(.gray)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(blockchainEntries) { entry in
                                BlockchainEntryView(entry: entry)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Medicine Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: { dismiss() }) {
                Text("Close")
                    .foregroundColor(.blue)
            })
            .onAppear {
                loadBlockchainData()
            }
            .sheet(isPresented: $showQRCode) {
                if let qrCodeURL = medicine.qrCodeURL, let url = URL(string: qrCodeURL) {
                    VStack {
                        Text("QR Code for Medicine")
                            .font(.headline)
                            .padding()
                        
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } placeholder: {
                            ProgressView()
                                .frame(width: 300, height: 300)
                        }
                        
                        Text("Medicine ID: \(medicine.id)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("Drug ID: \(medicine.drugID)")
                            .font(.subheadline)
                            .padding(.bottom)
                        
                        Button("Close") {
                            showQRCode = false
                        }
                        .padding()
                    }
                    .presentationDetents([.medium, .large])
                }
            }
        }
    }
    
    private func loadBlockchainData() {
        isLoading = true
        
        Task {
            do {
                // Load blockchain entries
                let entries = try await blockchainService.getBlockchainHistory(for: medicine.id)
                
                // Validate blockchain integrity
                let isValid = try await blockchainService.validateBlockchainIntegrity(for: medicine.id)
                
                DispatchQueue.main.async {
                    self.blockchainEntries = entries
                    self.isBlockchainValid = isValid
                    self.isLoading = false
                }
            } catch {
                print("Failed to load blockchain data: \(error)")
                
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct SectionTitle: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.vertical, 8)
    }
}

struct DetailItem: View {
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
    }
}

struct BlockchainEntryView: View {
    let entry: BlockchainEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Event type indicator
                ZStack {
                    Circle()
                        .fill(eventColor(entry.eventType))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: eventIcon(entry.eventType))
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(eventTitle(entry.eventType))
                        .font(.headline)
                    
                    Text(formattedDate(entry.timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Event details
            VStack(alignment: .leading, spacing: 8) {
                if let location = entry.location {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.gray)
                        
                        Text("Location: \(location)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                if entry.toOwner != nil {
                    HStack {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.gray)
                        
                        Text("Transferred ownership")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Additional info (if any)
                if let additionalInfo = entry.additionalInfo, !additionalInfo.isEmpty {
                    ForEach(additionalInfo.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        if !value.isEmpty {
                            HStack {
                                Text("\(key.capitalized):")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text(value)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            .padding(.leading, 38)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func eventTitle(_ eventType: EventType) -> String {
        switch eventType {
        case .registration:
            return "Medicine Registered"
        case .dispatch:
            return "Dispatched from Manufacturer"
        case .receive:
            return "Received by Retailer"
        case .verification:
            return "Verified Authenticity"
        case .rejection:
            return "Rejected as Invalid"
        case .sale:
            return "Sold to Consumer"
        case .flag:
            return "Flagged as Suspicious"
        }
    }
    
    private func eventIcon(_ eventType: EventType) -> String {
        switch eventType {
        case .registration:
            return "doc.badge.plus"
        case .dispatch:
            return "shippingbox.fill"
        case .receive:
            return "hand.thumbsup.fill"
        case .verification:
            return "checkmark.seal.fill"
        case .rejection:
            return "xmark.octagon.fill"
        case .sale:
            return "bag.fill"
        case .flag:
            return "flag.fill"
        }
    }
    
    private func eventColor(_ eventType: EventType) -> Color {
        switch eventType {
        case .registration:
            return .blue
        case .dispatch:
            return .orange
        case .receive:
            return .purple
        case .verification:
            return .green
        case .rejection:
            return .red
        case .sale:
            return .indigo
        case .flag:
            return .red
        }
    }
} 