import Foundation

public struct CaptureSupport: Equatable, Sendable {
    public let videoFormats: [String]
    public let audioFormats: [String]
    public let notes: String

    public init(videoFormats: [String], audioFormats: [String], notes: String) {
        self.videoFormats = videoFormats
        self.audioFormats = audioFormats
        self.notes = notes
    }
}
