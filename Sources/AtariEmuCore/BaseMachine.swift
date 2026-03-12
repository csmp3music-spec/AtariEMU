import Foundation

open class BaseMachine: EmulatedMachine {
    public let descriptor: MachineDescriptor
    public private(set) var runtimeState = MachineRuntimeState()

    public init(descriptor: MachineDescriptor) {
        self.descriptor = descriptor
    }

    open func start() {
        runtimeState.isRunning = true
        runtimeState.statusLine = "\(descriptor.model.displayName) running"
    }

    open func stop() {
        runtimeState.isRunning = false
        runtimeState.statusLine = "\(descriptor.model.displayName) paused"
    }

    open func reset() {
        runtimeState = MachineRuntimeState(
            isRunning: false,
            executedFrames: 0,
            accumulatedCycles: 0,
            statusLine: "\(descriptor.model.displayName) reset"
        )
    }

    open func runFrame() {
        let cyclesPerFrame = max(
            Int(Double(descriptor.defaultClockHz) / descriptor.targetVideoRateHz),
            1
        )
        runtimeState.executedFrames += 1
        runtimeState.accumulatedCycles += cyclesPerFrame
        runtimeState.statusLine = "\(descriptor.model.displayName) frame \(runtimeState.executedFrames)"
    }
}
