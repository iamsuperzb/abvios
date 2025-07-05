import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isLoading {
                LoadingView()
            } else if authService.user == nil && !authService.isAnonymous {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthService())
    }
}