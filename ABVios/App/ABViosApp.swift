import SwiftUI
import AuthenticationServices

@main
struct ABViosApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var bibleAdventureViewModel = BibleAdventureViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(bibleAdventureViewModel)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // 配置应用启动逻辑
        Task {
            await authService.checkAuthenticationState()
        }
    }
}