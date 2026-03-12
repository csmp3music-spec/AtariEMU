import Foundation

public protocol EmulatedMachine: AnyObject {
    var descriptor: MachineDescriptor { get }
    var runtimeState: MachineRuntimeState { get }

    func start()
    func stop()
    func reset()
    func runFrame()
}
