import SwiftUI

// MARK: - Chat View
struct ChatView: View {
    @EnvironmentObject var scrollContext: ScrollContext
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(0..<10) { _ in
                        MessageBubble()
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Chat")
            .background(Constants.Colors.background)
        }
    }
}

struct MessageBubble: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ask me anything about the Bible!")
                    .font(Constants.Fonts.body)
                    .foregroundColor(Constants.Colors.primaryText)
                
                Text("Tap to start a conversation")
                    .font(Constants.Fonts.caption)
                    .foregroundColor(Constants.Colors.secondaryText)
            }
            .padding()
            .background(Constants.Colors.secondaryBackground)
            .cornerRadius(Constants.Layout.cornerRadius)
            
            Spacer()
        }
    }
}

// MARK: - Bible View
struct BibleView: View {
    @EnvironmentObject var scrollContext: ScrollContext
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(["Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy"], id: \.self) { book in
                        BookRow(name: book)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Bible")
            .background(Constants.Colors.background)
        }
    }
}

struct BookRow: View {
    let name: String
    
    var body: some View {
        HStack {
            Image(systemName: Constants.Icons.bible)
                .font(.title2)
                .foregroundColor(Constants.Colors.primary)
            
            Text(name)
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.primaryText)
            
            Spacer()
            
            Image(systemName: Constants.Icons.chevronRight)
                .font(.caption)
                .foregroundColor(Constants.Colors.tertiaryText)
        }
        .padding()
        .background(Constants.Colors.secondaryBackground)
        .cornerRadius(Constants.Layout.cornerRadius)
    }
}

// MARK: - Cards View
struct CardsView: View {
    @EnvironmentObject var scrollContext: ScrollContext
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(0..<6) { index in
                        CardPlaceholder(isLocked: index > 2)
                    }
                }
                .padding()
            }
            .navigationTitle("Cards")
            .background(Constants.Colors.background)
        }
    }
}

struct CardPlaceholder: View {
    let isLocked: Bool
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius)
                .fill(isLocked ? Color.gray.opacity(0.3) : Constants.Colors.primary.opacity(0.1))
                .aspectRatio(0.7, contentMode: .fit)
                .overlay(
                    Image(systemName: isLocked ? Constants.Icons.lock : Constants.Icons.cards)
                        .font(.largeTitle)
                        .foregroundColor(isLocked ? Color.gray : Constants.Colors.primary)
                )
            
            Text(isLocked ? "Locked" : "Card \(1)")
                .font(Constants.Fonts.caption)
                .foregroundColor(Constants.Colors.secondaryText)
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var scrollContext: ScrollContext
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationStack {
            List {
                // User Info Section
                Section {
                    HStack {
                        Image(systemName: Constants.Icons.profile)
                            .font(.system(size: 60))
                            .foregroundColor(Constants.Colors.primary)
                            .frame(width: 80, height: 80)
                            .background(Constants.Colors.primary.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.user?.name ?? "Guest User")
                                .font(Constants.Fonts.headline)
                                .foregroundColor(Constants.Colors.primaryText)
                            
                            Text(authService.user?.email ?? "Not signed in")
                                .font(Constants.Fonts.caption)
                                .foregroundColor(Constants.Colors.secondaryText)
                        }
                        .padding(.leading, 8)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Stats Section
                Section("Statistics") {
                    StatRow(icon: Constants.Icons.star, label: "Total Score", value: "1,234")
                    StatRow(icon: Constants.Icons.checkmark, label: "Correct Answers", value: "456")
                    StatRow(icon: Constants.Icons.cards, label: "Cards Collected", value: "12/50")
                }
                
                // Settings Section
                Section("Settings") {
                    SettingRow(icon: "bell", label: "Notifications")
                    SettingRow(icon: "moon", label: "Dark Mode")
                    SettingRow(icon: "globe", label: "Language")
                }
                
                // Account Section
                Section {
                    if authService.isAnonymous {
                        Button(action: {
                            // Show sign in
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Sign In")
                                Spacer()
                            }
                            .foregroundColor(Constants.Colors.primary)
                        }
                    } else {
                        Button(action: {
                            Task {
                                await authService.signOut()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                Text("Sign Out")
                                Spacer()
                            }
                            .foregroundColor(Constants.Colors.error)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Constants.Colors.primary)
                .frame(width: 30)
            
            Text(label)
                .font(Constants.Fonts.body)
            
            Spacer()
            
            Text(value)
                .font(Constants.Fonts.callout)
                .foregroundColor(Constants.Colors.secondaryText)
        }
    }
}

struct SettingRow: View {
    let icon: String
    let label: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Constants.Colors.primary)
                .frame(width: 30)
            
            Text(label)
                .font(Constants.Fonts.body)
            
            Spacer()
            
            Image(systemName: Constants.Icons.chevronRight)
                .font(.caption)
                .foregroundColor(Constants.Colors.tertiaryText)
        }
    }
}