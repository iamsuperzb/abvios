import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var scrollContext = ScrollContext()
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var bibleAdventureViewModel: BibleAdventureViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            TabView(selection: $selectedTab) {
                // Chat/Home Tab
                ChatView()
                    .tag(0)
                    .environmentObject(scrollContext)
                
                // Bible Tab
                BibleView()
                    .tag(1)
                    .environmentObject(scrollContext)
                
                // Cards Tab
                CardsView()
                    .tag(2)
                    .environmentObject(scrollContext)
                
                // Study Tab (Bible Adventure)
                StudyView()
                    .tag(3)
                    .environmentObject(scrollContext)
                
                // Profile Tab
                ProfileView()
                    .tag(4)
                    .environmentObject(scrollContext)
            }
            
            // Custom Tab Bar
            CustomTabBar(
                selectedTab: $selectedTab,
                showLabels: scrollContext.showNavLabels,
                isHidden: scrollContext.isFullscreen
            )
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        // Hide default tab bar
        UITabBar.appearance().isHidden = true
    }
}

// MARK: - Scroll Context
class ScrollContext: ObservableObject {
    @Published var showNavLabels = true
    @Published var isFullscreen = false
    @Published var scrollOffset: CGFloat = 0
    
    func updateVisibility(offset: CGFloat) {
        scrollOffset = offset
        
        // Hide labels when scrolling down
        if offset > 50 {
            showNavLabels = false
        } else if offset < -20 {
            showNavLabels = true
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let showLabels: Bool
    let isHidden: Bool
    
    @State private var animateSelection = false
    
    private let tabs: [(icon: String, label: String)] = [
        (Constants.Icons.home, "Chat"),
        (Constants.Icons.bible, "Bible"),
        (Constants.Icons.cards, "Cards"),
        (Constants.Icons.study, "Study"),
        (Constants.Icons.profile, "Profile")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(isHidden ? 0 : 1)
            
            HStack(spacing: 0) {
                ForEach(tabs.indices, id: \.self) { index in
                    TabBarButton(
                        icon: tabs[index].icon,
                        label: tabs[index].label,
                        isSelected: selectedTab == index,
                        showLabel: showLabels
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                            animateSelection = true
                        }
                        
                        // Haptic feedback
                        HapticManager.impact(style: .light)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: showLabels ? 72 : 52)
            .padding(.bottom, DeviceInfo.hasNotch ? 20 : 8)
        }
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
        .offset(y: isHidden ? 150 : 0)
        .opacity(isHidden ? 0 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isHidden)
        .animation(.easeInOut(duration: 0.2), value: showLabels)
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let showLabel: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: showLabel ? 4 : 0) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .symbolVariant(isSelected ? .fill : .none)
                    .scaleEffect(isPressed ? 0.85 : (isSelected ? 1.1 : 1.0))
                    .foregroundColor(isSelected ? Constants.Colors.primary : Color(UIColor.systemGray))
                
                if showLabel {
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(isSelected ? Constants.Colors.primary : Color(UIColor.systemGray))
                        .opacity(showLabel ? 1 : 0)
                        .scaleEffect(showLabel ? 1 : 0.8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(TabBarButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Tab Bar Button Style
struct TabBarButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .onChange(of: configuration.isPressed) { _, newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = newValue
                }
            }
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthService())
            .environmentObject(BibleAdventureViewModel())
    }
}