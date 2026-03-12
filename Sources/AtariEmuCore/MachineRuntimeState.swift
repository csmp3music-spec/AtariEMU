import Foundation

public struct MachineRuntimeState: Equatable, Sendable {
    public var isRunning: Bool
    public var executedFrames: Int
    public var accumulatedCycles: Int
    public var statusLine: String

    public init(
        isRunning: Bool = false,
        executedFrames: Int = 0,
        accumulatedCycles: Int = 0,
        statusLine: String = "Idle"
    ) {
        self.isRunning = isRunning
        self.executedFrames = executedFrames
        self.accumulatedCycles = accumulatedCycles
        self.statusLine = statusLine
    }
}
