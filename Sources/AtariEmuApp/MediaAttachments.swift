import AtariEmuCore
import Foundation

enum MediaAttachmentSlot: String, CaseIterable, Identifiable, Sendable {
    case driveA
    case driveB
    case hardDisk1
    case hardDisk2

    var id: String {
        rawValue
    }

    func title(for model: MachineModel) -> String {
        switch self {
        case .driveA:
            return BackendLauncher.backendKind(for: model) == .atari800 ? "Drive A / D1" : "Drive A"
        case .driveB:
            return BackendLauncher.backendKind(for: model) == .atari800 ? "Drive B / D2" : "Drive B"
        case .hardDisk1:
            return "Hard Disk 1"
        case .hardDisk2:
            return "Hard Disk 2"
        }
    }

    func notes(for model: MachineModel) -> String {
        switch (BackendLauncher.backendKind(for: model), self) {
        case (.atari800, .driveA):
            return "Attach an 8-bit disk image as D1:."
        case (.atari800, .driveB):
            return "Attach an 8-bit disk image as D2:."
        case (.hatari, .driveA):
            return "Attach a floppy image for the primary ST/TT/Falcon drive."
        case (.hatari, .driveB):
            return "Attach a floppy image for the secondary ST/TT/Falcon drive."
        case (.hatari, .hardDisk1):
            return "Attach the primary ACSI or IDE hard disk image."
        case (.hatari, .hardDisk2):
            return "Attach the secondary ACSI, SCSI, or IDE hard disk image."
        case (.atari800, .hardDisk1), (.atari800, .hardDisk2):
            return "Hard disk image slots are unavailable for this machine family."
        }
    }

    func isAvailable(for model: MachineModel) -> Bool {
        switch self {
        case .driveA, .driveB:
            return true
        case .hardDisk1, .hardDisk2:
            return BackendLauncher.backendKind(for: model) == .hatari
        }
    }
}

struct MediaAttachments: Equatable, Sendable {
    var driveA: URL?
    var driveB: URL?
    var hardDisk1: URL?
    var hardDisk2: URL?

    static let empty = MediaAttachments()

    var isEmpty: Bool {
        driveA == nil && driveB == nil && hardDisk1 == nil && hardDisk2 == nil
    }

    subscript(slot: MediaAttachmentSlot) -> URL? {
        get {
            switch slot {
            case .driveA:
                return driveA
            case .driveB:
                return driveB
            case .hardDisk1:
                return hardDisk1
            case .hardDisk2:
                return hardDisk2
            }
        }
        set {
            switch slot {
            case .driveA:
                driveA = newValue
            case .driveB:
                driveB = newValue
            case .hardDisk1:
                hardDisk1 = newValue
            case .hardDisk2:
                hardDisk2 = newValue
            }
        }
    }

    func summaryLines(for model: MachineModel) -> [String] {
        MediaAttachmentSlot.allCases.compactMap { slot in
            guard slot.isAvailable(for: model), let url = self[slot] else {
                return nil
            }
            return "\(slot.title(for: model)): \(url.lastPathComponent)"
        }
    }
}
