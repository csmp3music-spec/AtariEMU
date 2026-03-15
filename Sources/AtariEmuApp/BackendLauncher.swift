import AtariEmuCore
import AppKit
import Foundation

enum BackendLaunchError: LocalizedError {
    case missingBackendBinary(String)
    case missingFirmware(String)
    case invalidWorkspace(String)
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingBackendBinary(let message),
             .missingFirmware(let message),
             .invalidWorkspace(let message),
             .launchFailed(let message):
            return message
        }
    }
}

enum EmulatorBackendKind: String, Sendable {
    case atari800 = "Atari800"
    case hatari = "Hatari"

    var displayName: String {
        rawValue
    }
}

struct BackendLaunchPlan: Sendable {
    let backend: EmulatorBackendKind
    let executableURL: URL
    let arguments: [String]
    let workingDirectoryURL: URL
    let logURL: URL
    let firmwareSummary: String
    let mediaSummary: String
}

struct BackendFirmwareAvailability: Sendable {
    let isReady: Bool
    let summary: String
}

final class ActiveBackendProcess {
    let plan: BackendLaunchPlan
    let process: Process

    private let logHandle: FileHandle

    init(plan: BackendLaunchPlan, process: Process, logHandle: FileHandle) {
        self.plan = plan
        self.process = process
        self.logHandle = logHandle
    }

    func terminate() {
        if process.isRunning {
            process.terminate()
        }
        try? logHandle.close()
    }
}

enum BackendLauncher {
    static func backendKind(for model: MachineModel) -> EmulatorBackendKind {
        switch model {
        case .atariXL, .atariXE, .atari65XE, .atari130XE, .superXL, .superMaxXL:
            return .atari800
        case .atariSTF, .atariMegaST, .atariStacy, .atariSTE, .atariMegaSTE,
             .superST, .superMegaST, .superMaxST, .atariTT030, .superTT,
             .superMaxTT, .atariFalcon030, .superMaxFalcon, .superFalconX1200:
            return .hatari
        }
    }

    static func defaultBackendDisplayName(for model: MachineModel) -> String {
        backendKind(for: model).displayName
    }

    static func binarySummary(for model: MachineModel) -> String {
        do {
            return try resolveExecutable(for: model).lastPathComponent
        } catch {
            return error.localizedDescription
        }
    }

    static func firmwareSummary(for descriptor: MachineDescriptor, mediaLibrary: LocalMediaLibrary) -> String {
        firmwareAvailability(for: descriptor.model, mediaLibrary: mediaLibrary).summary
    }

    static func firmwareAvailability(for model: MachineModel, mediaLibrary: LocalMediaLibrary) -> BackendFirmwareAvailability {
        do {
            switch backendKind(for: model) {
            case .atari800:
                let firmware = try resolveEightBitFirmware(for: model, mediaLibrary: mediaLibrary)
                return BackendFirmwareAvailability(
                    isReady: true,
                    summary: basicFirmwareSummary(
                        primaryURL: firmware.primaryURL,
                        basicURL: firmware.basicURL,
                        usesAltirraBIOS: firmware.usesBuiltinAltirraBIOS,
                        usesAltirraBasic: firmware.usesBuiltinAltirraBASIC
                    )
                )
            case .hatari:
                return BackendFirmwareAvailability(
                    isReady: true,
                    summary: try resolveTOSFirmware(for: model, mediaLibrary: mediaLibrary).summary
                )
            }
        } catch {
            return BackendFirmwareAvailability(isReady: false, summary: error.localizedDescription)
        }
    }

    static func isLaunchableMedia(_ url: URL, for model: MachineModel) -> Bool {
        switch backendKind(for: model) {
        case .atari800:
            return classifyAtari800Media(url) != nil
        case .hatari:
            return classifyHatariMedia(url) != nil
        }
    }

    static func isAttachableMedia(_ url: URL, to slot: MediaAttachmentSlot, for model: MachineModel) -> Bool {
        switch backendKind(for: model) {
        case .atari800:
            switch slot {
            case .driveA, .driveB:
                return classifyAtari800Media(url) == .disk
            case .hardDisk1, .hardDisk2:
                return false
            }
        case .hatari:
            switch slot {
            case .driveA, .driveB:
                return classifyHatariMedia(url) == .floppy
            case .hardDisk1, .hardDisk2:
                return classifyHatariMedia(url) == .hardDisk
            }
        }
    }

    static func supportedAttachmentExtensions(for slot: MediaAttachmentSlot, model: MachineModel) -> [String] {
        switch backendKind(for: model) {
        case .atari800:
            switch slot {
            case .driveA, .driveB:
                return ["atr", "atx", "atz", "dcm", "pro", "xfd", "xfz", "atr.gz", "xfd.gz"]
            case .hardDisk1, .hardDisk2:
                return []
            }
        case .hatari:
            switch slot {
            case .driveA, .driveB:
                return ["st", "msa", "stx", "ipf", "dim", "raw", "ctr", "mfm", "fdi", "flp", "stt", "img", "st.gz", "msa.gz", "dim.gz", "ipf.gz", "ctr.gz", "st.zip", "msa.zip"]
            case .hardDisk1, .hardDisk2:
                return ["hda", "hdf", "hdv", "vdi", "vhd", "img"]
            }
        }
    }

    static func launchFailureSummary(from logURL: URL) -> String? {
        guard
            let logContents = try? String(contentsOf: logURL, encoding: .utf8)
        else {
            return nil
        }

        for line in logContents.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        return nil
    }

    static func prepareLaunch(
        model: MachineModel,
        preset: SoftwarePreset?,
        matchedMediaURL: URL?,
        attachments: MediaAttachments,
        mediaLibrary: LocalMediaLibrary
    ) throws -> BackendLaunchPlan {
        let executableURL = try resolveExecutable(for: model)
        let runtimeRoot = WorkspacePaths.runtimeRoot()
        let launchDirectory = runtimeRoot
            .appendingPathComponent("Launches", isDirectory: true)
            .appendingPathComponent(launchDirectoryName(model: model, preset: preset), isDirectory: true)
        let fileManager = FileManager.default

        try fileManager.createDirectory(at: launchDirectory, withIntermediateDirectories: true)

        let logURL = launchDirectory.appendingPathComponent("backend.log")
        fileManager.createFile(atPath: logURL.path, contents: Data())

        switch backendKind(for: model) {
        case .atari800:
            return try prepareAtari800Launch(
                model: model,
                preset: preset,
                matchedMediaURL: matchedMediaURL,
                attachments: attachments,
                mediaLibrary: mediaLibrary,
                executableURL: executableURL,
                launchDirectory: launchDirectory,
                logURL: logURL
            )
        case .hatari:
            return try prepareHatariLaunch(
                model: model,
                preset: preset,
                matchedMediaURL: matchedMediaURL,
                attachments: attachments,
                mediaLibrary: mediaLibrary,
                executableURL: executableURL,
                launchDirectory: launchDirectory,
                logURL: logURL
            )
        }
    }

    static func launch(
        plan: BackendLaunchPlan,
        onExit: @escaping @Sendable (Int32, Process.TerminationReason) -> Void
    ) throws -> ActiveBackendProcess {
        let process = Process()
        process.executableURL = plan.executableURL
        process.arguments = plan.arguments
        process.currentDirectoryURL = plan.workingDirectoryURL

        let logHandle = try FileHandle(forWritingTo: plan.logURL)
        logHandle.truncateFile(atOffset: 0)
        process.standardOutput = logHandle
        process.standardError = logHandle

        process.terminationHandler = { process in
            onExit(process.terminationStatus, process.terminationReason)
            try? logHandle.close()
        }

        do {
            try process.run()
        } catch {
            try? logHandle.close()
            throw BackendLaunchError.launchFailed("Failed to start \(plan.backend.displayName): \(error.localizedDescription)")
        }

        let pid = process.processIdentifier

        Task.detached {
            try? await Task.sleep(nanoseconds: 600_000_000)
            if let app = NSRunningApplication(processIdentifier: pid) {
                app.activate(options: [.activateAllWindows])
            }
        }

        return ActiveBackendProcess(plan: plan, process: process, logHandle: logHandle)
    }

    private static func prepareAtari800Launch(
        model: MachineModel,
        preset: SoftwarePreset?,
        matchedMediaURL: URL?,
        attachments: MediaAttachments,
        mediaLibrary: LocalMediaLibrary,
        executableURL: URL,
        launchDirectory: URL,
        logURL: URL
    ) throws -> BackendLaunchPlan {
        let firmware = try resolveEightBitFirmware(for: model, mediaLibrary: mediaLibrary)
        let hostDriveDirectory = launchDirectory.appendingPathComponent("HDrive", isDirectory: true)
        try FileManager.default.createDirectory(at: hostDriveDirectory, withIntermediateDirectories: true)
        let validatedAttachments = try validateAttachments(attachments, for: model)

        var arguments: [String] = [
            machineArgument(for: model),
            "-ntsc",
            "-no-autosave-config",
            "-H1", hostDriveDirectory.path,
            "-H2", hostDriveDirectory.path,
            "-H3", hostDriveDirectory.path,
            "-H4", hostDriveDirectory.path,
            "-hreadwrite"
        ]

        if let primaryURL = firmware.primaryURL {
            arguments += ["-xlxe_rom", primaryURL.path]
        } else {
            arguments += ["-xl-rev", "altirra"]
        }

        if let basicURL = firmware.basicURL {
            arguments += ["-basic_rom", basicURL.path, "-basic"]
        } else {
            arguments += ["-basic-rev", "altirra", "-basic"]
        }

        var mediaSummaryParts: [String] = []
        var ignoredSummaryParts: [String] = []
        var driveOneOccupiedByBootDisk = false

        if let matchedMediaURL {
            guard let mediaKind = classifyAtari800Media(matchedMediaURL) else {
                throw BackendLaunchError.launchFailed("The selected file is not directly bootable in Atari800: \(matchedMediaURL.lastPathComponent)")
            }

            switch mediaKind {
            case .disk:
                arguments.append(matchedMediaURL.path)
                mediaSummaryParts.append("D1: \(matchedMediaURL.lastPathComponent)")
                driveOneOccupiedByBootDisk = true
            case .program:
                arguments += ["-run", matchedMediaURL.path]
                mediaSummaryParts.append("Program: \(matchedMediaURL.lastPathComponent)")
            case .cartridge:
                arguments += ["-cart", matchedMediaURL.path]
                mediaSummaryParts.append("Cartridge: \(matchedMediaURL.lastPathComponent)")
            case .tape:
                arguments += ["-boottape", matchedMediaURL.path]
                mediaSummaryParts.append("Tape: \(matchedMediaURL.lastPathComponent)")
            }
        }

        if driveOneOccupiedByBootDisk {
            if validatedAttachments.driveA != nil {
                ignoredSummaryParts.append("Drive A ignored because D1 is occupied by boot media")
            }
        } else if let driveA = validatedAttachments.driveA {
            arguments.append(driveA.path)
            mediaSummaryParts.append("D1: \(driveA.lastPathComponent)")
        }

        if let driveB = validatedAttachments.driveB {
            if driveOneOccupiedByBootDisk || validatedAttachments.driveA != nil {
                arguments.append(driveB.path)
                mediaSummaryParts.append("D2: \(driveB.lastPathComponent)")
            } else {
                let placeholderURL = try createBlankATRPlaceholder(at: launchDirectory)
                arguments.append(placeholderURL.path)
                arguments.append(driveB.path)
                mediaSummaryParts.append("D1: Empty placeholder")
                mediaSummaryParts.append("D2: \(driveB.lastPathComponent)")
            }
        }

        let mediaSummary = formattedMediaSummary(
            primary: mediaSummaryParts,
            ignored: ignoredSummaryParts,
            fallback: preset?.name ?? "No boot media attached"
        ) ?? (preset?.name ?? "No boot media attached")

        return BackendLaunchPlan(
            backend: .atari800,
            executableURL: executableURL,
            arguments: arguments,
            workingDirectoryURL: launchDirectory,
            logURL: logURL,
            firmwareSummary: basicFirmwareSummary(
                primaryURL: firmware.primaryURL,
                basicURL: firmware.basicURL,
                usesAltirraBIOS: firmware.usesBuiltinAltirraBIOS,
                usesAltirraBasic: firmware.usesBuiltinAltirraBASIC
            ),
            mediaSummary: mediaSummary
        )
    }

    private static func prepareHatariLaunch(
        model: MachineModel,
        preset: SoftwarePreset?,
        matchedMediaURL: URL?,
        attachments: MediaAttachments,
        mediaLibrary: LocalMediaLibrary,
        executableURL: URL,
        launchDirectory: URL,
        logURL: URL
    ) throws -> BackendLaunchPlan {
        let firmware = try resolveTOSFirmware(for: model, mediaLibrary: mediaLibrary)
        let validatedAttachments = try validateAttachments(attachments, for: model)

        var arguments: [String] = [
            "--machine", hatariMachineType(for: model),
            "--tos", firmware.url.path,
            "--confirm-quit", "false",
            "--statusbar", "true",
            "--window",
            "--sound", "44100"
        ]

        let hardwareProfile = hatariHardwareProfile(for: model)
        arguments += hardwareProfile.arguments

        if needsFalconDSP(for: model) {
            arguments += ["--dsp", "emu"]
        }

        if let preset, preset.name.localizedCaseInsensitiveContains("Linux") {
            arguments += ["--natfeats", "true"]
        }

        let mediaSummary = try appendHatariMediaArguments(
            for: matchedMediaURL,
            attachments: validatedAttachments,
            model: model,
            launchDirectory: launchDirectory,
            arguments: &arguments
        )

        return BackendLaunchPlan(
            backend: .hatari,
            executableURL: executableURL,
            arguments: arguments,
            workingDirectoryURL: launchDirectory,
            logURL: logURL,
            firmwareSummary: firmware.summary,
            mediaSummary: mediaSummary ?? (preset?.name ?? "No boot media attached")
        )
    }

    private static func appendHatariMediaArguments(
        for mediaURL: URL?,
        attachments: MediaAttachments,
        model: MachineModel,
        launchDirectory: URL,
        arguments: inout [String]
    ) throws -> String? {
        var mediaSummaryParts: [String] = []
        var ignoredSummaryParts: [String] = []

        guard let mediaURL else {
            if let driveA = attachments.driveA {
                arguments += ["--disk-a", driveA.path]
                mediaSummaryParts.append("Drive A: \(driveA.lastPathComponent)")
            }

            if let driveB = attachments.driveB {
                arguments += ["--disk-b", driveB.path]
                mediaSummaryParts.append("Drive B: \(driveB.lastPathComponent)")
            }

            if let hardDisk1 = attachments.hardDisk1 {
                appendHatariHardDiskArgument(for: hardDisk1, slot: .hardDisk1, model: model, arguments: &arguments)
                mediaSummaryParts.append("Hard Disk 1: \(hardDisk1.lastPathComponent)")
            }

            if let hardDisk2 = attachments.hardDisk2 {
                appendHatariHardDiskArgument(for: hardDisk2, slot: .hardDisk2, model: model, arguments: &arguments)
                mediaSummaryParts.append("Hard Disk 2: \(hardDisk2.lastPathComponent)")
            }

            if isVirtualStoragePreset(model) {
                let gemdosDirectory = launchDirectory.appendingPathComponent("GemDOS", isDirectory: true)
                try FileManager.default.createDirectory(at: gemdosDirectory, withIntermediateDirectories: true)
                arguments += ["--harddrive", gemdosDirectory.path]
                mediaSummaryParts.append("Host GEMDOS drive (\(gemdosDirectory.lastPathComponent))")
            }

            return formattedMediaSummary(primary: mediaSummaryParts, ignored: ignoredSummaryParts)
        }

        guard let mediaKind = classifyHatariMedia(mediaURL) else {
            throw BackendLaunchError.launchFailed("The selected file is not directly bootable in Hatari: \(mediaURL.lastPathComponent)")
        }

        switch mediaKind {
        case .floppy:
            arguments += ["--disk-a", mediaURL.path]
            mediaSummaryParts.append("Drive A: \(mediaURL.lastPathComponent)")
            if attachments.driveA != nil {
                ignoredSummaryParts.append("Drive A ignored because boot media already uses it")
            }
        case .hardDisk:
            appendHatariHardDiskArgument(for: mediaURL, slot: .hardDisk1, model: model, arguments: &arguments)
            mediaSummaryParts.append("Hard Disk 1: \(mediaURL.lastPathComponent)")
            if attachments.hardDisk1 != nil {
                ignoredSummaryParts.append("Hard Disk 1 ignored because boot media already uses it")
            }
        case .gemDOSProgram:
            let parentDirectory = mediaURL.deletingLastPathComponent()
            arguments += [
                "--harddrive", parentDirectory.path,
                "--auto", "C:\\\(mediaURL.lastPathComponent)"
            ]
            mediaSummaryParts.append("Autostart: \(mediaURL.lastPathComponent)")
        }

        if let driveB = attachments.driveB {
            arguments += ["--disk-b", driveB.path]
            mediaSummaryParts.append("Drive B: \(driveB.lastPathComponent)")
        }

        if mediaKind != .floppy, let driveA = attachments.driveA {
            arguments += ["--disk-a", driveA.path]
            mediaSummaryParts.append("Drive A: \(driveA.lastPathComponent)")
        }

        if mediaKind != .hardDisk, let hardDisk1 = attachments.hardDisk1 {
            appendHatariHardDiskArgument(for: hardDisk1, slot: .hardDisk1, model: model, arguments: &arguments)
            mediaSummaryParts.append("Hard Disk 1: \(hardDisk1.lastPathComponent)")
        }

        if let hardDisk2 = attachments.hardDisk2 {
            appendHatariHardDiskArgument(for: hardDisk2, slot: .hardDisk2, model: model, arguments: &arguments)
            mediaSummaryParts.append("Hard Disk 2: \(hardDisk2.lastPathComponent)")
        }

        return formattedMediaSummary(primary: mediaSummaryParts, ignored: ignoredSummaryParts)
    }

    private static func validateAttachments(_ attachments: MediaAttachments, for model: MachineModel) throws -> MediaAttachments {
        let validated = attachments

        for slot in MediaAttachmentSlot.allCases {
            guard let url = validated[slot] else {
                continue
            }

            guard slot.isAvailable(for: model) else {
                throw BackendLaunchError.launchFailed("\(slot.title(for: model)) is not available on \(model.displayName)")
            }

            guard isAttachableMedia(url, to: slot, for: model) else {
                throw BackendLaunchError.launchFailed("\(url.lastPathComponent) is not valid for \(slot.title(for: model)) on \(model.displayName)")
            }
        }

        return validated
    }

    private static func createBlankATRPlaceholder(at launchDirectory: URL) throws -> URL {
        let placeholderURL = launchDirectory.appendingPathComponent("placeholder-d1.atr")
        guard !FileManager.default.fileExists(atPath: placeholderURL.path) else {
            return placeholderURL
        }

        var data = Data([
            0x96, 0x02,
            0x80, 0x16,
            0x00, 0x00,
            0x80, 0x00,
            0x00, 0x00,
            0x00, 0x00,
            0x00, 0x00,
            0x00, 0x00
        ])
        data.append(Data(repeating: 0, count: 720 * 128))
        try data.write(to: placeholderURL, options: .atomic)
        return placeholderURL
    }

    private static func appendHatariHardDiskArgument(
        for mediaURL: URL,
        slot: MediaAttachmentSlot,
        model: MachineModel,
        arguments: inout [String]
    ) {
        if usesIDEStorage(for: model) {
            arguments += slot == .hardDisk1
                ? ["--ide-master", mediaURL.path]
                : ["--ide-slave", mediaURL.path]
        } else {
            let busID = slot == .hardDisk1 ? "0" : "1"
            arguments += ["--acsi", "\(busID)=\(mediaURL.path)"]
        }
    }

    private static func formattedMediaSummary(primary: [String], ignored: [String], fallback: String? = nil) -> String? {
        var parts = primary
        parts.append(contentsOf: ignored)

        if parts.isEmpty {
            return fallback
        }

        return parts.joined(separator: " • ")
    }

    private static func resolveExecutable(for model: MachineModel) throws -> URL {
        let fileManager = FileManager.default
        let environment = ProcessInfo.processInfo.environment
        let backend = backendKind(for: model)
        var candidates: [URL] = []

        switch backend {
        case .atari800:
            if let override = environment["ATARIEMU_ATARI800_BIN"], !override.isEmpty {
                candidates.append(URL(fileURLWithPath: override))
            }
            if let resourceURL = Bundle.main.resourceURL {
                candidates.append(resourceURL.appendingPathComponent("Cores/atari800/atari800"))
            }
            if let repositoryRoot = WorkspacePaths.repositoryRoot(fileManager: fileManager) {
                candidates.append(repositoryRoot.appendingPathComponent("third_party/atari800/src/atari800"))
                candidates.append(repositoryRoot.appendingPathComponent("third_party/atari800/build/src/atari800"))
                candidates.append(repositoryRoot.appendingPathComponent("third_party/atari800/build/atari800"))
            }
            candidates.append(contentsOf: which("atari800", fileManager: fileManager))
        case .hatari:
            if let override = environment["ATARIEMU_HATARI_BIN"], !override.isEmpty {
                candidates.append(URL(fileURLWithPath: override))
            }
            if let resourceURL = Bundle.main.resourceURL {
                candidates.append(resourceURL.appendingPathComponent("Cores/hatari/Hatari.app/Contents/MacOS/Hatari"))
                candidates.append(resourceURL.appendingPathComponent("Cores/hatari/hatari"))
            }
            if let repositoryRoot = WorkspacePaths.repositoryRoot(fileManager: fileManager) {
                candidates.append(repositoryRoot.appendingPathComponent("third_party/hatari/build/src/Hatari.app/Contents/MacOS/Hatari"))
                candidates.append(repositoryRoot.appendingPathComponent("third_party/hatari/build/Hatari.app/Contents/MacOS/Hatari"))
                candidates.append(repositoryRoot.appendingPathComponent("third_party/hatari/build/src/hatari"))
                candidates.append(repositoryRoot.appendingPathComponent("third_party/hatari/build/hatari"))
            }
            candidates.append(contentsOf: which("hatari", fileManager: fileManager))
        }

        for candidate in unique(candidates) where fileManager.isExecutableFile(atPath: candidate.path) {
            return candidate
        }

        throw BackendLaunchError.missingBackendBinary("Missing \(backend.displayName) binary. Build the vendored core first or set the corresponding ATARIEMU_*_BIN environment override.")
    }

    private static func resolveEightBitFirmware(
        for model: MachineModel,
        mediaLibrary: LocalMediaLibrary
    ) throws -> (
        primaryURL: URL?,
        basicURL: URL?,
        usesBuiltinAltirraBIOS: Bool,
        usesBuiltinAltirraBASIC: Bool
    ) {
        let primaryURL = prefer(
            in: mediaLibrary.atariFirmwareFiles,
            containingAnyOf: [
                ["xlxe"],
                ["atarixl"],
                ["800xl"],
                ["130xe"],
                ["65xe"],
                ["xegs"],
                ["xl"],
                ["xe"]
            ],
            excluding: ["basic", "5200", "tos", "emutos", "etos"]
        ) ?? mediaLibrary.atariFirmwareFiles.first(where: { !normalizedName(for: $0).contains("basic") })

        let basicURL = prefer(
            in: mediaLibrary.atariFirmwareFiles,
            containingAnyOf: [
                ["basic"],
                ["ataribas"]
            ],
            excluding: ["tos", "emutos", "etos"]
        )

        if let primaryURL {
            return (primaryURL, basicURL, false, basicURL == nil)
        }

        // Atari800 ships with optional built-in Altirra-compatible ROMs.
        return (nil, basicURL, true, basicURL == nil)
    }

    private static func resolveTOSFirmware(
        for model: MachineModel,
        mediaLibrary: LocalMediaLibrary
    ) throws -> (url: URL, summary: String) {
        let atariCandidates = mediaLibrary.atariFirmwareFiles.filter(isBootableTOSImage)
        let emuCandidates = mediaLibrary.emuTOSFirmwareFiles.filter(isBootableTOSImage)

        if let atariURL = preferAtariTOS(for: model, candidates: atariCandidates) {
            return (atariURL, "Atari TOS: \(atariURL.lastPathComponent)")
        }

        if let emuURL = preferEmuTOS(for: model, candidates: emuCandidates) {
            return (emuURL, "EmuTOS: \(emuURL.lastPathComponent)")
        }

        throw BackendLaunchError.missingFirmware("Missing bootable TOS/EmuTOS ROM for \(model.displayName). Put .img, .rom, .bin, or .tos files under UserMedia/Firmware/Atari or UserMedia/Firmware/EmuTOS.")
    }

    private static func preferAtariTOS(for model: MachineModel, candidates: [URL]) -> URL? {
        let rules = tosRules(for: model)
        return prefer(in: candidates, containingAnyOf: rules, excluding: ["emutos", "etos"])
            ?? prefer(in: candidates, containingAnyOf: [["tos"]], excluding: ["emutos", "etos"])
    }

    private static func preferEmuTOS(for model: MachineModel, candidates: [URL]) -> URL? {
        let rules = tosRules(for: model)
        return prefer(in: candidates, containingAnyOf: rules, excluding: [])
            ?? prefer(in: candidates, containingAnyOf: [["etos"], ["emutos"]], excluding: [])
    }

    private static func tosRules(for model: MachineModel) -> [[String]] {
        switch model {
        case .atariSTF, .atariMegaST, .atariStacy, .superST, .superMegaST, .superMaxST:
            return [
                ["104"],
                ["102"],
                ["100"],
                ["st"],
                ["256"],
                ["512"]
            ]
        case .atariSTE, .atariMegaSTE:
            return [
                ["206"],
                ["205"],
                ["ste"],
                ["512"],
                ["1024"]
            ]
        case .atariTT030, .superTT, .superMaxTT:
            return [
                ["306"],
                ["tt"],
                ["1024"],
                ["512"]
            ]
        case .atariFalcon030, .superMaxFalcon, .superFalconX1200:
            return [
                ["404"],
                ["402"],
                ["falcon"],
                ["1024"]
            ]
        default:
            return [["tos"]]
        }
    }

    private static func machineArgument(for model: MachineModel) -> String {
        switch model {
        case .atariXL, .atari65XE:
            return "-xl"
        case .atariXE, .atari130XE:
            return "-xe"
        case .superXL:
            return "-576xe"
        case .superMaxXL:
            return "-1088xe"
        default:
            return "-xl"
        }
    }

    private static func hatariMachineType(for model: MachineModel) -> String {
        switch model {
        case .atariSTF, .superST:
            return "st"
        case .atariMegaST, .superMegaST, .superMaxST:
            return "megast"
        case .atariStacy:
            return "st"
        case .atariSTE:
            return "ste"
        case .atariMegaSTE:
            return "megaste"
        case .atariTT030, .superTT, .superMaxTT:
            return "tt"
        case .atariFalcon030, .superMaxFalcon, .superFalconX1200:
            return "falcon"
        default:
            return "st"
        }
    }

    private static func hatariHardwareProfile(for model: MachineModel) -> (arguments: [String], summary: String) {
        switch model {
        case .atariSTF:
            return (["--memsize", "1"], "ST 1 MiB")
        case .atariMegaST:
            return (["--memsize", "4"], "Mega ST 4 MiB")
        case .atariStacy:
            return (["--memsize", "4"], "Stacy mapped to ST 4 MiB profile")
        case .atariSTE:
            return (["--memsize", "4"], "STE 4 MiB")
        case .atariMegaSTE:
            return (["--memsize", "4", "--cpuclock", "16"], "Mega STE 4 MiB / 16 MHz")
        case .superST:
            return (
                ["--memsize", "14", "--cpulevel", "3", "--cpuclock", "32", "--fpu", "68882", "--compatible", "false", "--cpu-exact", "false"],
                "Super ST 14 MiB / 32 MHz"
            )
        case .superMegaST:
            return (
                ["--memsize", "14", "--cpulevel", "3", "--cpuclock", "32", "--fpu", "68882", "--compatible", "false", "--cpu-exact", "false"],
                "Super Mega ST 14 MiB / 32 MHz"
            )
        case .superMaxST:
            return (
                ["--memsize", "14", "--cpulevel", "3", "--cpuclock", "32", "--fpu", "68882", "--compatible", "false", "--cpu-exact", "false"],
                "Super Max ST 14 MiB / 32 MHz"
            )
        case .atariTT030:
            return (["--memsize", "10", "--ttram", "32", "--cpulevel", "3", "--fpu", "68882", "--mmu", "true", "--addr24", "false"], "TT030")
        case .superTT:
            return (
                ["--memsize", "14", "--ttram", "256", "--cpulevel", "4", "--cpuclock", "32", "--fpu", "68882", "--mmu", "true", "--addr24", "false", "--compatible", "false", "--cpu-exact", "false"],
                "Super TT 14 MiB ST-RAM / 256 MiB TT-RAM"
            )
        case .superMaxTT:
            return (
                ["--memsize", "14", "--ttram", "1024", "--cpulevel", "6", "--cpuclock", "32", "--fpu", "internal", "--mmu", "true", "--addr24", "false", "--compatible", "false", "--cpu-exact", "false"],
                "Super Max TT 14 MiB ST-RAM / 1024 MiB TT-RAM"
            )
        case .atariFalcon030:
            return (["--memsize", "14", "--cpulevel", "3", "--fpu", "68882", "--addr24", "false"], "Falcon030")
        case .superMaxFalcon:
            return (
                ["--memsize", "14", "--ttram", "1024", "--cpulevel", "6", "--cpuclock", "32", "--fpu", "internal", "--mmu", "true", "--addr24", "false", "--compatible", "false", "--cpu-exact", "false"],
                "Super Max Falcon 14 MiB ST-RAM / 1024 MiB TT-RAM"
            )
        case .superFalconX1200:
            return (
                ["--memsize", "14", "--ttram", "1024", "--cpulevel", "6", "--cpuclock", "32", "--fpu", "internal", "--mmu", "true", "--addr24", "false", "--compatible", "false", "--cpu-exact", "false"],
                "Super Falcon X1200 14 MiB ST-RAM / 1024 MiB TT-RAM"
            )
        default:
            return (["--memsize", "1"], "Default profile")
        }
    }

    private static func needsFalconDSP(for model: MachineModel) -> Bool {
        switch model {
        case .atariFalcon030, .superMaxFalcon, .superFalconX1200:
            return true
        default:
            return false
        }
    }

    private static func usesIDEStorage(for model: MachineModel) -> Bool {
        switch model {
        case .atariTT030, .superTT, .superMaxTT, .atariFalcon030, .superMaxFalcon, .superFalconX1200:
            return true
        default:
            return false
        }
    }

    private static func isVirtualStoragePreset(_ model: MachineModel) -> Bool {
        switch model {
        case .superST, .superMegaST, .superMaxST, .superTT, .superMaxTT, .superMaxFalcon, .superFalconX1200:
            return true
        default:
            return false
        }
    }

    private static func classifyAtari800Media(_ url: URL) -> Atari800MediaKind? {
        let pathExtension = normalizedExtension(for: url)

        switch pathExtension {
        case "xex", "com", "exe", "bas", "lst":
            return .program
        case "car", "cart", "rom", "bin":
            return .cartridge
        case "cas":
            return .tape
        case "atr", "atx", "atz", "dcm", "pro", "xfd", "xfz", "atrgz", "xfdgz":
            return .disk
        default:
            return nil
        }
    }

    private static func classifyHatariMedia(_ url: URL) -> HatariMediaKind? {
        let pathExtension = normalizedExtension(for: url)

        switch pathExtension {
        case "prg", "ttp", "tos":
            return .gemDOSProgram
        case "hda", "hdf", "hdv", "vdi", "vhd":
            return .hardDisk
        case "img":
            let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return fileSize > 2_000_000 ? .hardDisk : .floppy
        case "st", "msa", "stx", "ipf", "dim", "raw", "ctr", "mfm", "fdi", "flp", "stt", "stgz", "msagz", "dimgz", "ipfgz", "ctrgz", "stzip", "msazip":
            return .floppy
        default:
            return nil
        }
    }

    private static func prefer(
        in candidates: [URL],
        containingAnyOf rules: [[String]],
        excluding excludedTokens: [String]
    ) -> URL? {
        for rule in rules {
            if let match = candidates.first(where: { url in
                let name = normalizedName(for: url)
                return rule.allSatisfy(name.contains) && excludedTokens.allSatisfy { !name.contains($0) }
            }) {
                return match
            }
        }

        return nil
    }

    private static func normalizedName(for url: URL) -> String {
        url.lastPathComponent.lowercased().replacingOccurrences(of: " ", with: "")
    }

    private static func normalizedExtension(for url: URL) -> String {
        let filename = url.lastPathComponent.lowercased()

        for compound in [".atr.gz", ".xfd.gz", ".st.gz", ".msa.gz", ".dim.gz", ".ipf.gz", ".ctr.gz", ".st.zip", ".msa.zip"] {
            if filename.hasSuffix(compound) {
                return compound.replacingOccurrences(of: ".", with: "")
            }
        }

        return url.pathExtension.lowercased()
    }

    private static func isBootableTOSImage(_ url: URL) -> Bool {
        switch url.pathExtension.lowercased() {
        case "bin", "img", "rom", "tos":
            return true
        default:
            return false
        }
    }

    private static func basicFirmwareSummary(
        primaryURL: URL?,
        basicURL: URL?,
        usesAltirraBIOS: Bool,
        usesAltirraBasic: Bool
    ) -> String {
        let osSummary = primaryURL?.lastPathComponent ?? (usesAltirraBIOS ? "Altirra OS" : "Missing XL/XE OS")

        if let basicURL {
            return "\(osSummary) + \(basicURL.lastPathComponent)"
        }

        if usesAltirraBasic {
            return "\(osSummary) + Altirra BASIC"
        }

        return "\(osSummary) (BASIC off)"
    }

    private static func launchDirectoryName(model: MachineModel, preset: SoftwarePreset?) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let suffix = preset.map { sanitize($0.name) } ?? "cold-boot"
        return "\(timestamp)-\(model.rawValue)-\(suffix)"
    }

    private static func sanitize(_ value: String) -> String {
        let filtered = value.lowercased().map { character -> Character in
            if character.isLetter || character.isNumber {
                return character
            }
            return "-"
        }

        return String(filtered).replacingOccurrences(of: "--", with: "-")
    }

    private static func which(_ executableName: String, fileManager: FileManager) -> [URL] {
        guard let pathValue = ProcessInfo.processInfo.environment["PATH"] else {
            return []
        }

        return pathValue
            .split(separator: ":")
            .map { URL(fileURLWithPath: String($0)).appendingPathComponent(executableName) }
            .filter { fileManager.isExecutableFile(atPath: $0.path) }
    }

    private static func unique(_ urls: [URL]) -> [URL] {
        var seen = Set<String>()
        var result: [URL] = []

        for url in urls {
            let path = url.standardizedFileURL.path
            if seen.insert(path).inserted {
                result.append(url)
            }
        }

        return result
    }

    private enum Atari800MediaKind {
        case disk
        case program
        case cartridge
        case tape
    }

    private enum HatariMediaKind {
        case floppy
        case hardDisk
        case gemDOSProgram
    }
}
