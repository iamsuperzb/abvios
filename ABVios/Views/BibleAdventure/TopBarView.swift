import SwiftUI

// MARK: - Top Bar View
struct TopBarView: View {
    let totalCrosses: Int
    let totalCorrectCount: Int
    let isCached: Bool
    
    @State private var showCrossAnimation = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Crosses count
            HStack(spacing: 8) {
                Image(systemName: Constants.Icons.cross)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Constants.Colors.primary)
                    .rotationEffect(.degrees(showCrossAnimation ? 360 : 0))
                
                Text("\(totalCrosses)")
                    .font(Constants.Fonts.headline)
                    .foregroundColor(Constants.Colors.primaryText)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Constants.Colors.primary.opacity(0.1))
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showCrossAnimation.toggle()
                }
                HapticManager.impact(style: .light)
            }
            
            Spacer()
            
            // Cache indicator
            if isCached {
                Image(systemName: "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 16))
                    .foregroundColor(Constants.Colors.warning)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Correct count
            HStack(spacing: 8) {
                Image(systemName: Constants.Icons.checkmark)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Constants.Colors.success)
                
                Text("\(totalCorrectCount)")
                    .font(Constants.Fonts.headline)
                    .foregroundColor(Constants.Colors.primaryText)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Constants.Colors.success.opacity(0.1))
            )
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white,
                    Color.white.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Preview
struct TopBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TopBarView(
                totalCrosses: 42,
                totalCorrectCount: 156,
                isCached: true
            )
            
            Spacer()
        }
        .background(Color.gray.opacity(0.1))
    }
}