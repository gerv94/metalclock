import Metal
import MetalKit
import QuartzCore

final class MetalRenderer: NSObject, MTKViewDelegate {
    private struct Uniforms {
        var resolution: SIMD2<Float>
        var secondAngle: Float
        var minuteAngle: Float
        var hourAngle: Float
        var padding: Float
    }

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer
    private let uniformBuffer: MTLBuffer
    private let timeSource = ClockTimeSource()

    init(view: MTKView) {
        guard let device = view.device else {
            fatalError("Metal device not available")
        }
        self.device = device
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Unable to create command queue")
        }
        self.commandQueue = commandQueue

        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "fullscreen_vertex")
        let fragmentFunction = library?.makeFunction(name: "clock_fragment")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.rasterSampleCount = view.sampleCount
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Unable to create pipeline state: \(error)")
        }

        let quadVertices: [SIMD2<Float>] = [
            SIMD2(-1, -1),
            SIMD2(3, -1),
            SIMD2(-1, 3)
        ]
        guard let vertexBuffer = device.makeBuffer(
            bytes: quadVertices,
            length: MemoryLayout<SIMD2<Float>>.stride * quadVertices.count,
            options: .storageModeShared
        ) else {
            fatalError("Unable to create vertex buffer")
        }
        self.vertexBuffer = vertexBuffer

        guard let uniformBuffer = device.makeBuffer(
            length: MemoryLayout<Uniforms>.stride,
            options: .storageModeShared
        ) else {
            fatalError("Unable to create uniform buffer")
        }
        self.uniformBuffer = uniformBuffer

        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // No-op.
    }

    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else {
            return
        }

        let seconds = timeSource.secondsSinceMidnight()
        let sec = seconds.truncatingRemainder(dividingBy: 60)
        let min = (seconds / 60).truncatingRemainder(dividingBy: 60)
        let hour = (seconds / 3600).truncatingRemainder(dividingBy: 12)

        let uniforms = Uniforms(
            resolution: SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            secondAngle: Float(sec / 60.0 * Double.pi * 2.0),
            minuteAngle: Float(min / 60.0 * Double.pi * 2.0),
            hourAngle: Float(hour / 12.0 * Double.pi * 2.0),
            padding: 0
        )

        uniformBuffer.contents().assumingMemoryBound(to: Uniforms.self).pointee = uniforms

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

final class ClockTimeSource {
    private let calendar = Calendar.current
    private let startDate = Date()
    private let startUptime = CACurrentMediaTime()

    func secondsSinceMidnight() -> Double {
        let elapsed = CACurrentMediaTime() - startUptime
        let now = startDate.addingTimeInterval(elapsed)
        let midnight = calendar.startOfDay(for: now)
        return now.timeIntervalSince(midnight)
    }
}
