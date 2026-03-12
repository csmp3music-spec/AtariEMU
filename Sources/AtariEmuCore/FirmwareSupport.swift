import Foundation

public enum FirmwareDistributionPolicy: String, CaseIterable, Equatable, Sendable {
    case userSuppliedOnly = "User-supplied only"
    case bundleableOpenSource = "Bundleable open-source"
}

public struct FirmwareOption: Equatable, Sendable {
    public let name: String
    public let distributionPolicy: FirmwareDistributionPolicy
    public let notes: String

    public init(name: String, distributionPolicy: FirmwareDistributionPolicy, notes: String) {
        self.name = name
        self.distributionPolicy = distributionPolicy
        self.notes = notes
    }
}

public struct FirmwareSlot: Equatable, Sendable {
    public let name: String
    public let isRequired: Bool
    public let options: [FirmwareOption]

    public init(name: String, isRequired: Bool, options: [FirmwareOption]) {
        self.name = name
        self.isRequired = isRequired
        self.options = options
    }
}

public struct MediaSlot: Equatable, Sendable {
    public let name: String
    public let isRequired: Bool
    public let notes: String

    public init(name: String, isRequired: Bool, notes: String) {
        self.name = name
        self.isRequired = isRequired
        self.notes = notes
    }
}
