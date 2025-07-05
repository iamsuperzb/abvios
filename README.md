# ABVios - Bible Adventure iOS App

A native Swift iOS application converted from the ABVExpo React Native project, providing an engaging Bible learning experience through an adventure-style quiz game.

## 🎯 Project Overview

ABVios is a complete Swift/SwiftUI reimplementation of the ABVExpo mobile application, featuring:

- **Bible Adventure Game**: Interactive chapter-based learning with progress tracking
- **Quiz System**: 4 question types (Multiple Choice, Fill in Blank, Ordering, Matching)
- **Card Collection**: Unlock and collect Bible character cards
- **User Authentication**: Apple Sign In with anonymous user support
- **Progress Sync**: Real-time progress tracking with backend synchronization

## 🏗 Architecture

### Technology Stack
- **UI Framework**: SwiftUI (iOS 15+)
- **Authentication**: AuthenticationServices (Apple Sign In)
- **Networking**: URLSession with async/await
- **Data Storage**: UserDefaults + Keychain Services
- **Image Loading**: SDWebImageSwiftUI
- **Animations**: SwiftUI Animations + Core Animation

### Project Structure
```
ABVios/
├── App/                          # App entry point
│   ├── ABViosApp.swift          # Main app file
│   └── ContentView.swift        # Root view controller
├── Core/
│   ├── Models/                   # Data models
│   │   ├── Chapter.swift        # Chapter/lesson models
│   │   ├── Quiz.swift           # Quiz and question models
│   │   ├── User.swift           # User and progress models
│   │   └── Card.swift           # Card collection models
│   ├── Services/                 # Business services
│   │   ├── APIService.swift     # Network API service
│   │   ├── AuthService.swift    # Authentication service
│   │   ├── CacheService.swift   # Local caching
│   │   ├── UserIdentityManager.swift # User identity management
│   │   └── QuizStreamParser.swift    # Streaming JSON parser
│   ├── ViewModels/              # MVVM view models
│   │   ├── BibleAdventureViewModel.swift
│   │   ├── QuizViewModel.swift
│   │   └── ScoringSystem.swift
│   └── Utils/                   # Utilities and helpers
│       ├── Constants.swift      # App constants
│       ├── Extensions.swift     # Swift extensions
│       └── Helpers.swift        # Helper functions
├── Views/                       # SwiftUI views
│   ├── Main/                    # Main navigation
│   │   ├── TabView.swift        # Custom tab bar
│   │   ├── StudyView.swift      # Bible adventure main view
│   │   └── PlaceholderViews.swift # Other tab placeholders
│   ├── BibleAdventure/          # Adventure game components
│   │   ├── AdventureMapView.swift    # Interactive map
│   │   ├── TopBarView.swift          # Progress display
│   │   └── CardUnlockView.swift      # Card unlock animation
│   ├── Quiz/                    # Quiz system
│   │   ├── QuizView.swift       # Main quiz interface
│   │   ├── QuestionView.swift   # Question container
│   │   ├── QuestionViews/       # Question type implementations
│   │   └── QuizResultView.swift # Results and scoring
│   ├── Auth/                    # Authentication
│   │   └── LoginView.swift      # Sign in interface
│   └── Common/                  # Shared components
└── Resources/                   # App resources
    ├── Info.plist              # App configuration
    └── ABVios.entitlements     # App capabilities
```

## 🔧 Key Features

### Bible Adventure System
- **Interactive Map**: S-curve chapter layout with visual progress indicators
- **Chapter Unlocking**: Sequential progression with unlock logic
- **Progress Tracking**: Real-time sync with visual feedback
- **Star Rating**: 3-star system based on quiz performance

### Quiz System
- **Multiple Question Types**:
  - Multiple Choice with visual feedback
  - Fill in the Blank with auto-checking
  - Ordering with drag-and-drop
  - Matching with pair selection
- **Scoring Algorithm**:
  - Base: 1 point per correct answer
  - Streak bonus: Additional points for consecutive correct answers
  - Perfect run bonus: +10 points for 100% accuracy
- **Real-time Feedback**: Immediate answer validation with explanations

### Authentication & User Management
- **Apple Sign In**: Primary authentication method
- **Anonymous Mode**: Guest access to first 3 chapters
- **Data Migration**: Seamless upgrade from anonymous to authenticated
- **Progress Sync**: Cross-device synchronization

### Performance Optimizations
- **Async/Await**: Modern Swift concurrency
- **Image Caching**: SDWebImage integration
- **Local Caching**: 5-minute cache with background refresh
- **Streaming Support**: Progressive JSON parsing for quiz data

## 🎨 UI/UX Design

### Visual Design
- **iOS Human Interface Guidelines**: Native iOS design patterns
- **Dynamic Type**: Accessibility support for text scaling
- **Dark Mode**: Automatic system appearance support
- **Haptic Feedback**: Contextual tactile responses

### Animations
- **SwiftUI Animations**: Smooth transitions and micro-interactions
- **Flying Cross**: Parabolic animation for correct answers
- **Card Unlock**: Celebration animation with particle effects
- **Progress Indicators**: Animated rings and counters

## 🔌 Backend Integration

### API Compatibility
- **Full Compatibility**: Uses same backend as ABVExpo
- **Base URL**: `https://www.askbibleverse.com/api/quiz`
- **Shared Data**: Progress, cards, and user data sync

### Data Models
All Swift models maintain compatibility with existing JSON schemas:
- User progress tracking
- Quiz question formats
- Card collection data
- Error analytics

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 15.0+ deployment target
- Swift 5.9+
- Apple Developer Account (for Apple Sign In)

### Installation
1. Clone the repository
2. Open `ABVios.xcodeproj` in Xcode
3. Configure Apple Sign In capability
4. Set up provisioning profiles
5. Build and run

### Configuration
1. **Apple Sign In**: Configure Services ID in Apple Developer Console
2. **Bundle ID**: Set unique bundle identifier
3. **Entitlements**: Enable required capabilities
4. **Info.plist**: Configure app metadata and permissions

## 🧪 Testing

### Unit Tests
- Model validation
- Service layer testing
- View model logic verification

### UI Tests
- Navigation flow testing
- Quiz interaction testing
- Authentication flow testing

## 📱 Deployment

### App Store Preparation
1. **Metadata**: App description and keywords
2. **Screenshots**: All required device sizes
3. **Privacy Policy**: Data usage disclosure
4. **App Review**: Compliance with guidelines

### Performance Monitoring
- **Crash Reporting**: Built-in crash analytics
- **Performance Metrics**: Launch time and responsiveness
- **User Analytics**: Engagement and completion rates

## 🔄 Migration from ABVExpo

### Feature Parity
- ✅ Complete Bible Adventure game
- ✅ All 4 quiz question types
- ✅ Card collection system
- ✅ Progress tracking and sync
- ✅ Authentication with Apple Sign In
- ✅ Anonymous user support

### Performance Improvements
- **Native Performance**: 60fps animations and smooth scrolling
- **Memory Efficiency**: Native iOS memory management
- **Battery Life**: Optimized for iOS power management
- **App Size**: Smaller binary size without JavaScript runtime

### iOS-Specific Enhancements
- **Haptic Feedback**: Rich tactile responses
- **Dynamic Type**: Accessibility improvements
- **Background Refresh**: Automatic progress sync
- **Spotlight Integration**: Search and deep linking

## 📊 Analytics & Monitoring

### Key Metrics
- User engagement and retention
- Quiz completion rates
- Chapter progression analytics
- Card collection statistics

### Performance Monitoring
- App launch time tracking
- Memory usage optimization
- Network request performance
- Crash and error reporting

## 🛠 Development Notes

### Code Style
- SwiftUI best practices
- MVVM architecture pattern
- Async/await for concurrency
- Protocol-oriented programming

### Dependencies
- Minimal external dependencies
- SDWebImageSwiftUI for image handling
- Native iOS frameworks preferred

### Accessibility
- VoiceOver support
- Dynamic Type scaling
- High contrast mode support
- Reduced motion preferences

---

**ABVios** represents a complete native iOS implementation of the Bible Adventure learning platform, optimized for performance, accessibility, and user experience while maintaining full compatibility with the existing backend infrastructure.