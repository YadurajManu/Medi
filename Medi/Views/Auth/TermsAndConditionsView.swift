import SwiftUI

struct TermsAndConditionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var agreedToTerms = false
    var onAccept: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header section
                    VStack(alignment: .center, spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.08)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                                .blur(radius: 1)
                            
                            Image("Logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.blue.opacity(0.2), radius: 5, x: 0, y: 3)
                        }
                        
                        Text("Terms and Conditions")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Last Updated: \(formattedDate())")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        Rectangle()
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                    )
                    
                    // Introduction
                    sectionTitle("1. Introduction")
                    
                    sectionText("Welcome to MediChain Verify (\"we\", \"our\", or \"us\"). By accessing or using our application, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you disagree with any part of these terms, you may not access or use our services.")
                    
                    // Definitions
                    sectionTitle("2. Definitions")
                    
                    sectionText("• **Application**: The MediChain Verify mobile application designed for medicine authentication and supply chain verification.\n\n• **User**: Any individual who accesses or uses our Application, including Consumers, Company Owners, Shop Owners, and Transportation providers.\n\n• **Content**: All information, text, data, and materials available through our Application.\n\n• **Blockchain**: The distributed ledger technology used to record medicine information and transactions.")
                    
                    // User Accounts
                    sectionTitle("3. User Accounts")
                    
                    sectionText("When you create an account with us, you must provide accurate, complete, and current information. You are responsible for safeguarding your account credentials and for any activities or actions under your account. We reserve the right to disable any user account if, in our opinion, you have violated any provision of these Terms.")
                    
                    // User Types and Responsibilities
                    sectionTitle("4. User Types and Responsibilities")
                    
                    sectionText("**4.1 Consumer**: End users who verify medicine authenticity.\n• May scan QR codes to verify medicines\n• Must report suspicious medicines\n• May view medicine details and history\n\n**4.2 Company Owner**: Pharmaceutical companies and manufacturers.\n• Responsible for registering authentic medicines in the system\n• Must provide accurate medicine information\n• Accountable for medicine quality and safety\n\n**4.3 Shop Owner**: Pharmacies and medicine retailers.\n• Must verify medicines before selling to consumers\n• Responsible for ensuring medicine legitimacy\n• Required to maintain proper records of transactions\n\n**4.4 Transportation**: Logistics providers in the medicine supply chain.\n• Responsible for secure transportation of medicines\n• Must record handovers and location updates\n• Required to maintain proper handling conditions")
                    
                    // Service Usage
                    sectionTitle("5. Service Usage")
                    
                    sectionText("Our services are provided for medicine verification and supply chain tracking. You agree to use our Application only for its intended purposes and in compliance with all applicable laws and regulations. You shall not use our Application to:")
                    
                    bulletPoint("Engage in any fraudulent or deceptive practices")
                    bulletPoint("Upload false or misleading medicine information")
                    bulletPoint("Attempt to access data not intended for you")
                    bulletPoint("Interfere with the functioning of the service")
                    bulletPoint("Distribute malware or other harmful code")
                    bulletPoint("Violate any applicable laws or regulations")
                    
                    // Intellectual Property
                    sectionTitle("6. Intellectual Property")
                    
                    sectionText("The Application and its original content, features, and functionality are owned by MediChain Verify and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws. You may not modify, reproduce, distribute, create derivative works, publicly display or perform, or in any way exploit any of our intellectual property without our prior written consent.")
                    
                    // Data Privacy
                    sectionTitle("7. Data Privacy")
                    
                    sectionText("We collect and process personal information as described in our Privacy Policy. By using our Application, you consent to such processing and you warrant that all data provided by you is accurate. The blockchain technology used in our application ensures data integrity while following privacy regulations.")
                    
                    // Limitations of Liability
                    sectionTitle("8. Limitations of Liability")
                    
                    sectionText("In no event shall MediChain Verify, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from:\n\n• Your access to or use of or inability to access or use the Service;\n• Any conduct or content of any third party on the Service;\n• Any content obtained from the Service; and\n• Unauthorized access, use or alteration of your transmissions or content.")
                    
                    // Disclaimer
                    sectionTitle("9. Disclaimer")
                    
                    sectionText("Your use of the Service is at your sole risk. The Service is provided on an \"AS IS\" and \"AS AVAILABLE\" basis. The Service is provided without warranties of any kind, whether express or implied, including, but not limited to, implied warranties of merchantability, fitness for a particular purpose, non-infringement or course of performance.")
                    
                    // Governing Law
                    sectionTitle("10. Governing Law")
                    
                    sectionText("These Terms shall be governed and construed in accordance with the laws applicable in your jurisdiction, without regard to its conflict of law provisions.")
                    
                    // Changes to Terms
                    sectionTitle("11. Changes to Terms")
                    
                    sectionText("We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material, we will try to provide at least 30 days' notice prior to any new terms taking effect. What constitutes a material change will be determined at our sole discretion.")
                    
                    // Contact Us
                    sectionTitle("12. Contact Us")
                    
                    sectionText("If you have any questions about these Terms, please contact us at:\n\nsupport@medichain-verify.com\n+1 (555) 123-4567")
                    
                    // Agreement checkbox
                    HStack(alignment: .center, spacing: 10) {
                        Toggle(isOn: $agreedToTerms) {
                            EmptyView()
                        }
                        .toggleStyle(MinimalCheckboxStyle())
                        .frame(width: 25, height: 25)
                        
                        Text("I have read and agree to these Terms and Conditions")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 25)
                    .padding(.bottom, 10)
                    
                    // Action buttons
                    HStack(spacing: 15) {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                        }
                        
                        Button(action: {
                            if agreedToTerms {
                                onAccept()
                                dismiss()
                            }
                        }) {
                            Text("Accept")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(agreedToTerms ? Color.blue : Color.blue.opacity(0.4))
                                )
                        }
                        .disabled(!agreedToTerms)
                    }
                    .padding(.bottom, 30)
                }
                .padding()
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(
                leading: 
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
            )
        }
    }
    
    // Helper function to format current date
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
    
    // Helper views for consistent styling
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .padding(.top, 5)
    }
    
    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.blue)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .padding(.leading, 8)
    }
} 