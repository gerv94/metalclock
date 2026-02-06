import SwiftUI
import MetalKit

struct MetalClockView: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> ClockMetalView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return ClockMetalView(frame: .zero, device: nil)
        }

        let view = ClockMetalView(frame: .zero, device: device)
        let renderer = MetalRenderer(view: view)
        context.coordinator.renderer = renderer
        view.delegate = renderer
        return view
    }

    func updateNSView(_ nsView: ClockMetalView, context: Context) {
        // No-op.
    }

    final class Coordinator {
        var renderer: MetalRenderer?
    }
}
