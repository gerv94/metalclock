import SwiftUI

struct ContentView: View {
    private let clockSize: CGFloat = 240

    var body: some View {
        MetalClockView()
            .frame(width: clockSize, height: clockSize)
            .background(Color.clear)
    }
}
