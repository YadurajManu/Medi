import SwiftUI

struct AddMedicineView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var blockchainService = BlockchainService()
    
    @State private var drugID = ""
    @State private var manufacturerName = ""
    @State private var drugName = ""
    @State private var composition = ""
    @State private var manufacturingLocation = ""
    @State private var manufactureDate = Date()
    @State private var expiryDate = Date().addingTimeInterval(365 * 24 * 60 * 60) // Default 1 year
    
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showSuccessView = false
    @State private var registeredMedicineId = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.white.ignoresSafeArea()
                
                // Main content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Basic medicine details
                        Group {
                            // Drug ID / Batch Number
                            FormField(title: "Drug ID / Batch Number", placeholder: "Enter unique drug ID", text: $drugID, icon: "number")
                            
                            // Manufacturer Name
                            FormField(title: "Manufacturer Name", placeholder: "Enter manufacturer name", text: $manufacturerName, icon: "building.2")
                            
                            // Drug Name
                            FormField(title: "Drug Name", placeholder: "Enter drug name", text: $drugName, icon: "pill")
                            
                            // Composition
                            FormField(title: "Composition", placeholder: "Enter composition details", text: $composition, icon: "list.bullet")
                            
                            // Manufacturing Location
                            FormField(title: "Manufacturing Location", placeholder: "Enter manufacturing location", text: $manufacturingLocation, icon: "mappin.and.ellipse")
                        }
                        
                        // Dates
                        Group {
                            // Manufacture Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Manufacture Date")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                
                                DatePicker("", selection: $manufactureDate, displayedComponents: .date)
                                    .datePickerStyle(WheelDatePickerStyle())
                                    .labelsHidden()
                                    .frame(maxHeight: 100)
                                    .clipped()
                            }
                            
                            // Expiry Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Expiry Date")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                
                                DatePicker("", selection: $expiryDate, in: manufactureDate..., displayedComponents: .date)
                                    .datePickerStyle(WheelDatePickerStyle())
                                    .labelsHidden()
                                    .frame(maxHeight: 100)
                                    .clipped()
                            }
                        }
                        
                        // Register button
                        Button(action: registerMedicine) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isFormValid ? Color.blue : Color.blue.opacity(0.4))
                                
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Register Medicine")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(height: 50)
                        }
                        .disabled(!isFormValid || isLoading)
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                
                // Success view overlay
                if showSuccessView {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .overlay(
                            VStack {
                                MedicineRegisteredSuccessView(medicineId: registeredMedicineId) {
                                    // Reset form and dismiss success view
                                    resetForm()
                                    showSuccessView = false
                                }
                            }
                            .padding()
                        )
                        .transition(.opacity)
                }
            }
            .navigationTitle("Register Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.blue)
            })
            .onChange(of: blockchainService.successMessage) { message in
                if !message.isEmpty {
                    alertTitle = "Success"
                    alertMessage = message
                    showAlert = true
                    
                    // Clear message
                    DispatchQueue.main.async {
                        blockchainService.successMessage = ""
                    }
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
        }
    }
    
    private var isFormValid: Bool {
        !drugID.isEmpty &&
        !manufacturerName.isEmpty &&
        !drugName.isEmpty &&
        !composition.isEmpty &&
        !manufacturingLocation.isEmpty &&
        expiryDate > manufactureDate
    }
    
    private func registerMedicine() {
        guard let currentUser = authService.user, isFormValid else { return }
        
        withAnimation {
            isLoading = true
        }
        
        Task {
            do {
                // Create medicine object
                let medicine = Medicine(
                    drugID: drugID,
                    manufacturerName: manufacturerName,
                    drugName: drugName,
                    composition: composition,
                    manufactureDate: manufactureDate,
                    expiryDate: expiryDate,
                    manufacturingLocation: manufacturingLocation,
                    registeredBy: currentUser.id,
                    currentOwner: currentUser.id
                )
                
                // Register medicine
                let medicineId = try await blockchainService.registerMedicine(medicine: medicine)
                
                // Update UI
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.registeredMedicineId = medicineId
                    
                    withAnimation {
                        self.showSuccessView = true
                    }
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
    
    private func resetForm() {
        drugID = ""
        manufacturerName = ""
        drugName = ""
        composition = ""
        manufacturingLocation = ""
        manufactureDate = Date()
        expiryDate = Date().addingTimeInterval(365 * 24 * 60 * 60)
        registeredMedicineId = ""
    }
}

struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                TextField(placeholder, text: $text)
                    .foregroundColor(.primary)
                    .font(.body)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

struct MedicineRegisteredSuccessView: View {
    let medicineId: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            // Title
            Text("Medicine Registered")
                .font(.title2)
                .fontWeight(.bold)
            
            // Message
            Text("Medicine has been successfully registered in the blockchain with QR code generated.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            // QR Code Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Medicine ID:")
                    .font(.headline)
                
                Text(medicineId)
                    .font(.subheadline)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = medicineId
                        }) {
                            Label("Copy Medicine ID", systemImage: "doc.on.doc")
                        }
                    }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
            
            // Buttons
            Button(action: onDismiss) {
                Text("Register Another Medicine")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
} 