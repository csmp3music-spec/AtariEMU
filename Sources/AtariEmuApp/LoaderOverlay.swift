import SwiftUI

struct LoaderOverlay: View {
    let phase: LoaderPhase
    let title: String
    let subtitle: String

    @State private var animate = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 18) {
                wordmark
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(32)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 1.25).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        switch phase {
        case .idle:
            Color.clear
        case .bootSplash:
            Color(red: 0.03, green: 0.31, blue: 0.10)
        case .rainbow:
            ZStack {
                Color.black.opacity(0.92)
                LinearGradient(
                    colors: [.red, .orange, .yellow, .green, .cyan, .blue, .pink],
                    startPoint: animate ? .leading : .trailing,
                    endPoint: animate ? .trailing : .leading
                )
                .blur(radius: 30)
                .opacity(0.85)
            }
        }
    }

    @ViewBuilder
    private var wordmark: some View {
        switch phase {
        case .idle:
            EmptyView()
        case .bootSplash:
            Text("ATARI")
                .font(.system(size: 92, weight: .black, design: .rounded))
                .tracking(14)
                .foregroundStyle(.white)
        case .rainbow:
            ZStack {
                Text("ATARI")
                    .font(.system(size: 92, weight: .black, design: .rounded))
                    .tracking(14)
                    .foregroundStyle(.white.opacity(0.12))
                LinearGradient(
                    colors: [.red, .orange, .yellow, .green, .cyan, .blue, .pink, .red],
                    startPoint: animate ? .leading : .trailing,
                    endPoint: animate ? .trailing : .leading
                )
                .frame(height: 110)
                .mask(
                    Text("ATARI")
                        .font(.system(size: 92, weight: .black, design: .rounded))
                        .tracking(14)
                )
            }
        }
    }
}
