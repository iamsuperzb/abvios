import SwiftUI

// MARK: - Study View (Bible Adventure)
struct StudyView: View {
    @EnvironmentObject var viewModel: BibleAdventureViewModel
    @EnvironmentObject var scrollContext: ScrollContext
    @State private var showQuiz = false
    @State private var selectedChapter: ChapterData?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.98, blue: 1.0),
                        Color(red: 0.98, green: 0.99, blue: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.chapters.isEmpty {
                    // Loading state
                    LoadingView()
                } else if let error = viewModel.error {
                    // Error state
                    ErrorView(error: error) {
                        Task {
                            await viewModel.loadData(forceRefresh: true)
                        }
                    }
                } else {
                    // Main content
                    VStack(spacing: 0) {
                        // Top bar
                        TopBarView(
                            totalCrosses: viewModel.totalCrosses,
                            totalCorrectCount: viewModel.totalCorrectCount,
                            isCached: viewModel.isCached
                        )
                        .frame(height: Constants.Layout.topBarHeight)
                        
                        // Adventure map
                        AdventureMapView(
                            chapters: viewModel.chapters,
                            userProgress: viewModel.progressMap,
                            onStartQuiz: { chapter in
                                selectedChapter = chapter
                                showQuiz = true
                            }
                        )
                    }
                }
                
                // Anonymous user banner
                if viewModel.authService.isAnonymous {
                    VStack {
                        Spacer()
                        UserStatusBanner()
                            .padding(.bottom, Constants.Layout.tabBarHeight)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showQuiz) {
                if let chapter = selectedChapter {
                    QuizView(chapter: chapter)
                        .environmentObject(viewModel)
                }
            }
        }
        .task {
            if viewModel.chapters.isEmpty {
                await viewModel.loadData()
            }
        }
        .refreshable {
            await viewModel.loadData(forceRefresh: true)
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: Constants.Icons.sparkles)
                .font(.system(size: 50))
                .foregroundColor(Constants.Colors.primary)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
            
            Text("Loading your adventure...")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.secondaryText)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let error: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: Constants.Icons.error)
                .font(.system(size: 50))
                .foregroundColor(Constants.Colors.error)
            
            Text("Oops! Something went wrong")
                .font(Constants.Fonts.title3)
                .foregroundColor(Constants.Colors.primaryText)
            
            Text(error)
                .font(Constants.Fonts.body)
                .foregroundColor(Constants.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: retry) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(Constants.Fonts.headline)
                    .foregroundColor(.white)
                    .frame(width: 150, height: 44)
                    .background(Constants.Colors.primary)
                    .cornerRadius(22)
            }
            .hapticFeedback()
        }
        .padding()
    }
}

// MARK: - User Status Banner
struct UserStatusBanner: View {
    @EnvironmentObject var authService: AuthService
    @State private var showUpgrade = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Playing as Guest")
                    .font(Constants.Fonts.headline)
                    .foregroundColor(.white)
                
                Text("First 3 chapters free • Sign in to unlock all")
                    .font(Constants.Fonts.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: {
                showUpgrade = true
            }) {
                Text("Upgrade")
                    .font(Constants.Fonts.callout.weight(.semibold))
                    .foregroundColor(Constants.Colors.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
            }
            .hapticFeedback()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Constants.Colors.primary,
                    Constants.Colors.secondary
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(Constants.Layout.cornerRadius)
        .padding(.horizontal)
        .shadow(color: Constants.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $showUpgrade) {
            LoginView(isUpgrading: true)
                .environmentObject(authService)
        }
    }
}

// MARK: - Preview
struct StudyView_Previews: PreviewProvider {
    static var previews: some View {
        StudyView()
            .environmentObject(BibleAdventureViewModel())
            .environmentObject(ScrollContext())
            .environmentObject(AuthService())
    }
}