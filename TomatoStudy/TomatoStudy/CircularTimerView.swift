import SwiftUI

struct CircularTimerView: View {
    let progress: Double
    let remaining: String
    let phase: TimerPhase

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(red: 0.91, green: 0.91, blue: 0.88), lineWidth: 24)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color(red: 0.71, green: 0.17, blue: 0.18), style: StrokeStyle(lineWidth: 24, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            VStack(spacing: 8) {
                Text(remaining)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                Label(phase.title, systemImage: phase.systemImageName)
                    .font(.headline)
                    .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))
            }
        }
    }
}

#Preview {
    CircularTimerView(progress: 0.4, remaining: "12:34", phase: .work)
}
