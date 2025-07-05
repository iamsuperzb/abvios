import SwiftUI

// MARK: - Card Unlock View
struct CardUnlockView: View {
    let card: Card
    let isVisible: Bool
    let onClose: () -> Void
    
    @State private var animateCard = false
    @State private var showParticles = false
    @State private var starRotation: Double = 0
    @State private var imageError = false
    
    var body: some View {
        if isVisible {
            ZStack {
                // Background overlay
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .onTapGesture {
                        HapticManager.impact(style: .light)
                        onClose()
                    }
                
                // Animation container
                VStack(spacing: 0) {
                    // Particles
                    if showParticles {
                        ParticleEffectView()
                            .allowsHitTesting(false)
                    }
                    
                    // Main content
                    VStack(spacing: 24) {
                        // Close button
                        HStack {
                            Spacer()
                            Button(action: {
                                HapticManager.impact(style: .light)
                                onClose()
                            }) {
                                Image(systemName: Constants.Icons.close)
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(Color.white.opacity(0.1)))
                            }
                        }
                        
                        // Title
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: Constants.Icons.sparkles)
                                    .font(.title2)
                                    .foregroundColor(card.rarity.color)
                                    .rotationEffect(.degrees(starRotation))
                                
                                Text("New Card Unlocked!")
                                    .font(Constants.Fonts.title)
                                    .foregroundColor(.white)
                                
                                Image(systemName: Constants.Icons.sparkles)
                                    .font(.title2)
                                    .foregroundColor(card.rarity.color)
                                    .rotationEffect(.degrees(-starRotation))
                            }
                            
                            Text("Congratulations! You unlocked a new card!")
                                .font(Constants.Fonts.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .opacity(animateCard ? 1 : 0)
                        .offset(y: animateCard ? 0 : -20)
                        
                        // Card display
                        CardDisplayView(card: card, imageError: $imageError)
                            .scaleEffect(animateCard ? 1 : 0.8)
                            .opacity(animateCard ? 1 : 0)
                            .rotationEffect(.degrees(animateCard ? 0 : 180))
                        
                        // Card details
                        VStack(spacing: 16) {
                            // Name and rarity
                            VStack(spacing: 4) {
                                Text(card.name)
                                    .font(Constants.Fonts.title2)
                                    .foregroundColor(.white)
                                
                                if !card.title.isEmpty {
                                    Text(card.title)
                                        .font(Constants.Fonts.callout)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                RarityBadge(rarity: card.rarity)
                            }
                            
                            // Description
                            if let description = card.description {
                                Text(description)
                                    .font(Constants.Fonts.body)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            // Bible reference
                            if let keyVerse = card.keyVerse {
                                Text(keyVerse)
                                    .font(Constants.Fonts.caption.italic())
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .opacity(animateCard ? 1 : 0)
                        .offset(y: animateCard ? 0 : 20)
                        
                        // Continue button
                        Button(action: {
                            HapticManager.impact(style: .light)
                            onClose()
                        }) {
                            Text("Continue Learning")
                                .font(Constants.Fonts.headline)
                                .foregroundColor(card.rarity.color)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white)
                                )
                        }
                        .padding(.horizontal, 40)
                        .opacity(animateCard ? 1 : 0)
                        .offset(y: animateCard ? 0 : 30)
                    }
                    .padding()
                }
            }
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.9)),
                removal: .opacity
            ))
            .onAppear {
                // Trigger haptic based on rarity
                switch card.rarity {
                case .UR, .SSR:
                    HapticManager.impact(style: .heavy)
                case .SR:
                    HapticManager.impact(style: .medium)
                default:
                    HapticManager.impact(style: .light)
                }
                
                // Start animations
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    animateCard = true
                }
                
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    starRotation = 360
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showParticles = true
                }
            }
        }
    }
}

// MARK: - Card Display View
struct CardDisplayView: View {
    let card: Card
    @Binding var imageError: Bool
    
    var body: some View {
        ZStack {
            // Card frame
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            card.rarity.color.opacity(0.3),
                            card.rarity.color.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 200, height: 280)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(card.rarity.color, lineWidth: 3)
                )
                .shadow(color: card.rarity.glowColor, radius: 20, x: 0, y: 0)
            
            // Card background pattern
            GeometryReader { geometry in
                ForEach(0..<20) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(
                            width: CGFloat.random(in: 20...60),
                            height: CGFloat.random(in: 20...60)
                        )
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
            .frame(width: 200, height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Card image
            if let imageUrl = card.imageUrl, !imageError {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 160, height: 200)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.3))
                            .onAppear { imageError = true }
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                // Fallback icon
                Image(systemName: getCardTypeIcon())
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
    
    private func getCardTypeIcon() -> String {
        switch card.cardType {
        case .character:
            return "person.fill"
        case .location:
            return "map.fill"
        case .event:
            return "calendar.circle.fill"
        case .artifact:
            return "archivebox.fill"
        }
    }
}

// MARK: - Rarity Badge
struct RarityBadge: View {
    let rarity: Card.Rarity
    
    var body: some View {
        Text(rarity.displayName.uppercased())
            .font(Constants.Fonts.caption.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(rarity.color)
            )
            .shadow(color: rarity.glowColor, radius: 10, x: 0, y: 0)
    }
}

// MARK: - Particle Effect View
struct ParticleEffectView: View {
    @State private var particles: [ParticleData] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ParticleView(particle: particle)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        for i in 0..<30 {
            let particle = ParticleData(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: Double.random(in: 0.3...1.0),
                duration: Double.random(in: 2...4),
                delay: Double(i) * 0.1
            )
            particles.append(particle)
        }
    }
}

// MARK: - Particle Data
struct ParticleData: Identifiable {
    let id = UUID()
    let position: CGPoint
    let scale: CGFloat
    let opacity: Double
    let duration: Double
    let delay: Double
}

// MARK: - Particle View
struct ParticleView: View {
    let particle: ParticleData
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(particle.position)
            .offset(offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: particle.duration)
                        .repeatForever()
                        .delay(particle.delay)
                ) {
                    offset = CGSize(
                        width: CGFloat.random(in: -50...50),
                        height: CGFloat.random(in: -100...100)
                    )
                }
                
                withAnimation(
                    .easeInOut(duration: particle.duration * 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(particle.delay)
                ) {
                    opacity = particle.opacity
                    scale = particle.scale
                }
            }
    }
}

// MARK: - Preview
struct CardUnlockView_Previews: PreviewProvider {
    static var previews: some View {
        CardUnlockView(
            card: Card(
                id: "1",
                cardId: "1",
                name: "Moses",
                title: "The Deliverer",
                rarity: .SSR,
                description: "Led the Israelites out of Egypt and received the Ten Commandments.",
                imageUrl: nil,
                keyVerse: "Exodus 3:14",
                bookName: "Exodus",
                cardType: .character,
                unlockChapter: 1,
                evolutionChainId: nil,
                evolutionStage: nil
            ),
            isVisible: true,
            onClose: {}
        )
    }
}