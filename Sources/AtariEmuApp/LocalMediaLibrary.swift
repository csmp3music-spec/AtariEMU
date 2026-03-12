import AtariEmuCore
import Foundation

struct MachineLibraryInventory: Equatable {
    let rootURL: URL?
    let atariFirmwareFiles: [URL]
    let emuTOSFirmwareFiles: [URL]
    let softwareFiles: [URL]

    var firmwareCount: Int {
        atariFirmwareFiles.count + emuTOSFirmwareFiles.count
    }
}

struct PresetLaunchPlan: Identifiable, Equatable {
    let preset: SoftwarePreset
    let matchedMediaURL: URL?
    let firmwareReady: Bool
    let mediaReady: Bool
    let firmwareSummary: String
    let matchSource: String

    var id: String {
        preset.id
    }

    var isReady: Bool {
        firmwareReady && (!preset.requiresExternalMedia || mediaReady)
    }

    var readinessLabel: String {
        if !firmwareReady {
            return "Firmware missing"
        }

        if !preset.requiresExternalMedia {
            return "Ready"
        }

        guard let matchedMediaURL else {
            return "Awaiting media"
        }

        return mediaReady ? "Ready" : "\(matchedMediaURL.pathExtension.uppercased()) is not directly bootable"
    }

    var matchedMediaName: String {
        matchedMediaURL?.lastPathComponent ?? "No matching file"
    }

    var preparationMessage: String {
        if let matchedMediaURL {
            if mediaReady {
                return "Using \(matchedMediaURL.lastPathComponent) • \(firmwareSummary)"
            }

            return "\(matchedMediaURL.lastPathComponent) is not directly bootable • \(firmwareSummary)"
        }

        return preset.requiresExternalMedia ? "Missing media • \(firmwareSummary)" : firmwareSummary
    }

    var loadingMessage: String {
        if let matchedMediaURL {
            return "Loading \(matchedMediaURL.lastPathComponent)"
        }

        return "Booting \(preset.name)"
    }
}

struct LocalMediaLibrary: Equatable {
    let rootURL: URL?
    let atariFirmwareFiles: [URL]
    let emuTOSFirmwareFiles: [URL]
    let softwareFilesByMachine: [MachineModel: [URL]]
    let explicitMappings: [String: URL]

    static func scan() -> LocalMediaLibrary {
        let fileManager = FileManager.default
        let rootURL = candidateRoots(fileManager: fileManager).first { fileManager.fileExists(atPath: $0.path) }

        guard let rootURL else {
            return LocalMediaLibrary(
                rootURL: nil,
                atariFirmwareFiles: [],
                emuTOSFirmwareFiles: [],
                softwareFilesByMachine: [:],
                explicitMappings: [:]
            )
        }

        let atariFirmwareFiles = scanFirmwareFiles(at: rootURL.appendingPathComponent("Firmware/Atari"), fileManager: fileManager)
        let emuTOSFirmwareFiles = scanFirmwareFiles(at: rootURL.appendingPathComponent("Firmware/EmuTOS"), fileManager: fileManager)

        var softwareFilesByMachine: [MachineModel: [URL]] = [:]
        for model in MachineModel.allCases {
            let softwareRoot = rootURL.appendingPathComponent("Software/\(model.rawValue)")
            softwareFilesByMachine[model] = scanSoftwareFiles(at: softwareRoot, fileManager: fileManager)
        }

        let explicitMappings = loadMappings(from: rootURL, fileManager: fileManager)

        return LocalMediaLibrary(
            rootURL: rootURL,
            atariFirmwareFiles: atariFirmwareFiles,
            emuTOSFirmwareFiles: emuTOSFirmwareFiles,
            softwareFilesByMachine: softwareFilesByMachine,
            explicitMappings: explicitMappings
        )
    }

    func inventory(for model: MachineModel) -> MachineLibraryInventory {
        MachineLibraryInventory(
            rootURL: rootURL,
            atariFirmwareFiles: atariFirmwareFiles,
            emuTOSFirmwareFiles: emuTOSFirmwareFiles,
            softwareFiles: softwareFilesByMachine[model, default: []]
        )
    }

    func launchPlan(for preset: SoftwarePreset, descriptor: MachineDescriptor) -> PresetLaunchPlan {
        let inventory = inventory(for: preset.machineModel)
        let firmwareAvailability = BackendLauncher.firmwareAvailability(for: descriptor.model, mediaLibrary: self)

        let explicitKey = Self.mappingKey(machine: preset.machineModel, presetName: preset.name)
        let explicitMatch = explicitMappings[explicitKey].flatMap { explicitURL in
            FileManager.default.fileExists(atPath: explicitURL.path) ? explicitURL : nil
        }
        let heuristicMatch = explicitMatch == nil ? heuristicMatch(for: preset, inventory: inventory) : nil
        let match = explicitMatch ?? heuristicMatch
        let matchSource = explicitMatch != nil ? "Preset mapping" : (heuristicMatch != nil ? "Filename match" : "No match")
        let mediaReady = match.map { BackendLauncher.isLaunchableMedia($0, for: preset.machineModel) } ?? false

        return PresetLaunchPlan(
            preset: preset,
            matchedMediaURL: match,
            firmwareReady: firmwareAvailability.isReady,
            mediaReady: mediaReady,
            firmwareSummary: firmwareAvailability.summary,
            matchSource: matchSource
        )
    }

    private func heuristicMatch(for preset: SoftwarePreset, inventory: MachineLibraryInventory) -> URL? {
        let normalizedPresetName = normalize(preset.name)
        let presetTokens = presetKeywords(for: preset)

        let scoredMatches = inventory.softwareFiles.compactMap { fileURL -> (url: URL, score: Int)? in
            let normalizedFilename = normalize(fileURL.deletingPathExtension().lastPathComponent)
            let filenameTokens = tokenSet(for: fileURL.deletingPathExtension().lastPathComponent)

            var score = 0
            if normalizedFilename.contains(normalizedPresetName) {
                score += 100
            }

            score += filenameTokens.intersection(presetTokens).count * 10

            return score > 0 ? (fileURL, score) : nil
        }

        return scoredMatches
            .sorted {
                if $0.score == $1.score {
                    return $0.url.lastPathComponent.localizedCaseInsensitiveCompare($1.url.lastPathComponent) == .orderedAscending
                }
                return $0.score > $1.score
            }
            .first?
            .url
    }

    private func normalize(_ string: String) -> String {
        string
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    private func presetKeywords(for preset: SoftwarePreset) -> Set<String> {
        let stopWords: Set<String> = [
            "atari",
            "audio",
            "desktop",
            "elite",
            "falcon",
            "linux",
            "m68k",
            "max",
            "mint",
            "plus",
            "shell",
            "studio",
            "super",
            "turbo",
            "workstation",
            "word"
        ]

        let keywords = tokenSet(for: preset.name)
            .filter { $0.count >= 3 && !stopWords.contains($0) }

        if !keywords.isEmpty {
            return keywords
        }

        return tokenSet(for: preset.name)
    }

    private func tokenSet(for string: String) -> Set<String> {
        Set(
            string
                .lowercased()
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map(String.init)
        )
    }

    private static func mappingKey(machine: MachineModel, presetName: String) -> String {
        "\(machine.rawValue)::\(presetName)"
    }

    private static func loadMappings(from rootURL: URL, fileManager: FileManager) -> [String: URL] {
        let mappingURL = rootURL.appendingPathComponent("PresetMappings.json")
        guard fileManager.fileExists(atPath: mappingURL.path) else {
            return [:]
        }

        do {
            let data = try Data(contentsOf: mappingURL)
            let manifest = try JSONDecoder().decode(PresetMappingManifest.self, from: data)

            return Dictionary(
                uniqueKeysWithValues: manifest.mappings.map { mapping in
                    let resolvedURL = rootURL.appendingPathComponent(mapping.relativePath)
                    return (mappingKey(machine: mapping.machineModel, presetName: mapping.presetName), resolvedURL)
                }
            )
        } catch {
            return [:]
        }
    }

    private static func candidateRoots(fileManager: FileManager) -> [URL] {
        WorkspacePaths.userMediaRoots(fileManager: fileManager)
    }

    private static func scanFirmwareFiles(at rootURL: URL, fileManager: FileManager) -> [URL] {
        scanFiles(at: rootURL, fileManager: fileManager, predicate: SupportedMediaFormats.isRecognizedFirmware)
    }

    private static func scanSoftwareFiles(at rootURL: URL, fileManager: FileManager) -> [URL] {
        scanFiles(at: rootURL, fileManager: fileManager, predicate: SupportedMediaFormats.isRecognizedSoftware)
    }

    private static func scanFiles(
        at rootURL: URL,
        fileManager: FileManager,
        predicate: (URL) -> Bool
    ) -> [URL] {
        guard fileManager.fileExists(atPath: rootURL.path) else {
            return []
        }

        let urls = (fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )?.allObjects as? [URL]) ?? []

        return urls.filter { url in
            ((try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false)
                && predicate(url)
        }
        .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
    }
}

enum SupportedMediaFormats {
    static let softwareExtensions: Set<String> = [
        "atr",
        "atx",
        "atz",
        "bas",
        "bin",
        "car",
        "cart",
        "cas",
        "com",
        "ctr",
        "dat",
        "dim",
        "dcm",
        "exe",
        "fdi",
        "flp",
        "gem",
        "hda",
        "hdf",
        "hdv",
        "img",
        "ipf",
        "lst",
        "m3u",
        "mfm",
        "msa",
        "neo",
        "prg",
        "pro",
        "raw",
        "rom",
        "sav",
        "scp",
        "st",
        "stt",
        "stx",
        "tos",
        "ttp",
        "vdi",
        "vhd",
        "xfd",
        "xfz",
        "xex",
        "ximg",
        "zip"
    ]

    static let firmwareExtensions: Set<String> = [
        "bin",
        "img",
        "rom",
        "tos"
    ]

    static let softwareCompoundSuffixes: [String] = [
        ".atr.gz",
        ".xfd.gz",
        ".st.gz",
        ".msa.gz",
        ".dim.gz",
        ".ipf.gz",
        ".ctr.gz",
        ".st.zip",
        ".msa.zip"
    ]

    static func isRecognized(_ url: URL) -> Bool {
        isRecognizedSoftware(url) || isRecognizedFirmware(url)
    }

    static func isRecognizedSoftware(_ url: URL) -> Bool {
        let filename = url.lastPathComponent.lowercased()
        let simpleExtension = url.pathExtension.lowercased()
        if softwareExtensions.contains(simpleExtension) {
            return true
        }

        for suffix in softwareCompoundSuffixes where filename.hasSuffix(suffix) {
            return true
        }

        return false
    }

    static func isRecognizedFirmware(_ url: URL) -> Bool {
        firmwareExtensions.contains(url.pathExtension.lowercased())
    }

    static var importableExtensions: [String] {
        Array(softwareExtensions.union(firmwareExtensions)).sorted()
    }
}

private struct PresetMappingManifest: Decodable {
    let mappings: [PresetMappingRecord]
}

private struct PresetMappingRecord: Decodable {
    let machine: String
    let preset: String
    let relativePath: String

    var machineModel: MachineModel {
        MachineModel(rawValue: machine) ?? .atariXL
    }

    var presetName: String {
        preset
    }
}
