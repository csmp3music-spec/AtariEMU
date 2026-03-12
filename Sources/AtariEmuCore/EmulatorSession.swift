import Foundation

public final class EmulatorSession {
    private(set) public var machine: EmulatedMachine

    public init(model: MachineModel) {
        self.machine = MachineFactory.makeMachine(for: model)
    }

    public var descriptor: MachineDescriptor {
        machine.descriptor
    }

    public var runtimeState: MachineRuntimeState {
        machine.runtimeState
    }

    public func switchModel(to model: MachineModel) {
        machine = MachineFactory.makeMachine(for: model)
    }

    public func start() {
        machine.start()
    }

    public func stop() {
        machine.stop()
    }

    public func reset() {
        machine.reset()
    }

    public func runFrame() {
        machine.runFrame()
    }
}
