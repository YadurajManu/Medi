//
//  MediApp.swift
//  Medi
//
//  Created by Yaduraj Singh on 07/04/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure App Check with debug provider for development
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        return true
    }
}

@main
struct MediApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if !hasSeenOnboarding {
                OnboardingView()
            } else {
                ContentView()
                    .environmentObject(authService)
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        if authService.isAuthenticated {
            switch authService.user?.userType {
            case .consumer:
                ConsumerDashboard()
                    .environmentObject(authService)
            case .companyOwner:
                CompanyOwnerDashboard()
                    .environmentObject(authService)
            case .shopOwner:
                ShopOwnerDashboard()
                    .environmentObject(authService)
            case .none:
                LoginView()
                    .environmentObject(authService)
            }
        } else {
            LoginView()
                .environmentObject(authService)
        }
    }
}
