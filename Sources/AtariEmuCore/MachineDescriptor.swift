import Foundation

public struct MachineDescriptor: Equatable, Sendable {
    public let model: MachineModel
    public let familyName: String
    public let cpuDescription: String
    public let defaultClockHz: Int
    public let summary: String
    public let ramDescription: String
    public let storageDescription: String
    public let isVirtualPreset: Bool
    public let subsystemNames: [String]
    public let hardwareTargets: [String]
    public let firmwareSlots: [FirmwareSlot]
    public let mediaSlots: [MediaSlot]
    public let operatingProfiles: [OperatingProfile]
    public let captureSupport: CaptureSupport
    public let targetVideoRateHz: Double

    public init(
        model: MachineModel,
        familyName: String,
        cpuDescription: String,
        defaultClockHz: Int,
        summary: String,
        ramDescription: String,
        storageDescription: String,
        isVirtualPreset: Bool,
        subsystemNames: [String],
        hardwareTargets: [String],
        firmwareSlots: [FirmwareSlot],
        mediaSlots: [MediaSlot],
        operatingProfiles: [OperatingProfile],
        captureSupport: CaptureSupport,
        targetVideoRateHz: Double
    ) {
        self.model = model
        self.familyName = familyName
        self.cpuDescription = cpuDescription
        self.defaultClockHz = defaultClockHz
        self.summary = summary
        self.ramDescription = ramDescription
        self.storageDescription = storageDescription
        self.isVirtualPreset = isVirtualPreset
        self.subsystemNames = subsystemNames
        self.hardwareTargets = hardwareTargets
        self.firmwareSlots = firmwareSlots
        self.mediaSlots = mediaSlots
        self.operatingProfiles = operatingProfiles
        self.captureSupport = captureSupport
        self.targetVideoRateHz = targetVideoRateHz
    }
}
