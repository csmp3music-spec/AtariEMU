import Foundation

public struct OperatingProfile: Equatable, Sendable {
    public let name: String
    public let availability: String
    public let notes: String

    public init(name: String, availability: String, notes: String) {
        self.name = name
        self.availability = availability
        self.notes = notes
    }
}
