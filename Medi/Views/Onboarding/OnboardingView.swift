import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @StateObject private var authService = AuthService()
    @State private var animateBackground = false
    @State private var animateIcon = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Verify Medicines",
            description: "Scan and verify the authenticity of your medicines using blockchain technology",
            imageName: "checkmark.shield.fill",
            backgroundColor: Color.blue.opacity(0.8),
            gradient: [Color.blue, Color.cyan]
        ),
        OnboardingPage(
            title: "Track Supply Chain",
            description: "See the complete journey of your medicine from manufacturer to pharmacy",
            imageName: "arrow.triangle.branch",
            backgroundColor: Color.indigo.opacity(0.8),
            gradient: [Color.indigo, Color.purple]
        ),
        OnboardingPage(
            title: "100% Secure",
            description: "Your data is secure with end-to-end encryption and blockchain verification",
            imageName: "lock.shield.fill",
            backgroundColor: Color.purple.opacity(0.8),
            gradient: [Color.purple, Color.pink]
        )
    ]
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: pages[currentPage].gradient),
                startPoint: animateBackground ? .topLeading : .bottomTrailing,
                endPoint: animateBackground ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                    animateBackground.toggle()
                }
            }
            
            // Animated blurred shapes for visual interest
            ZStack {
                Circle()
                    .fill(pages[currentPage].gradient[0].opacity(0.3))
                    .frame(width: 250, height: 250)
                    .blur(radius: 20)
                    .offset(x: -80, y: -200)
                
                Circle()
                    .fill(pages[currentPage].gradient[1].opacity(0.3))
                    .frame(width: 300, height: 300)
                    .blur(radius: 20)
                    .offset(x: 100, y: 300)
            }
            
            // Content
            VStack {
                // Skip button
                if currentPage < pages.count - 1 {
                    HStack {
                        Spacer()
                        Button("Skip") {
                            hasSeenOnboarding = true
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                        .padding()
                    }
                }
                
                Spacer()
                
                // Icon with animated circle
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 180, height: 180)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 10)
                    
                    Image(systemName: pages[currentPage].imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(pages[currentPage].backgroundColor)
                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                animateIcon.toggle()
                            }
                        }
                }
                .padding(.bottom, 40)
                
                // Title with animation
                Text(pages[currentPage].title)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                    .padding(.top, 20)
                    .transition(.opacity)
                    .id("title\(currentPage)")
                
                // Description
                Text(pages[currentPage].description)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 16)
                    .transition(.opacity)
                    .id("desc\(currentPage)")
                
                Spacer()
                
                // Pagination dots with animation
                HStack(spacing: 12) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 10, height: 10)
                            .scaleEffect(currentPage == index ? 1.3 : 1.0)
                            .shadow(color: currentPage == index ? Color.black.opacity(0.2) : Color.clear, radius: 2, x: 0, y: 1)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding()
                
                // Navigation buttons
                HStack {
                    // Back button
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                currentPage -= 1
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.left")
                                    .font(.body.bold())
                                Text("Back")
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            )
                            .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    // Next/Get Started button
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                currentPage += 1
                            }
                        } else {
                            hasSeenOnboarding = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.body.bold())
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                        .foregroundColor(pages[currentPage].backgroundColor)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .animation(.easeInOut, value: currentPage)
        .fullScreenCover(isPresented: $hasSeenOnboarding) {
            ContentView()
                .environmentObject(authService)
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let backgroundColor: Color
    let gradient: [Color]
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
} 