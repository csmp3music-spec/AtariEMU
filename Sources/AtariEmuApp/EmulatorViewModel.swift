import AtariEmuCore
import AppKit
import Foundation
import Observation

enum LoaderPhase: Equatable {
    case idle
    case bootSplash
    case rainbow
}

@MainActor
@Observable
final class EmulatorViewModel {
    private var loaderTask: Task<Void, Never>?
    private var activeBackend: ActiveBackendProcess?
    private var lastLaunchPlan: BackendLaunchPlan?
    private var manualAttachmentsByModel: [MachineModel: MediaAttachments] = [:]
    private(set) var mediaLibrary = LocalMediaLibrary.scan()

    var selectedModel: MachineModel = .atariXL
    var isRunning = false
    var statusLine = "Idle"
    var activePreset: SoftwarePreset?
    var loaderPhase: LoaderPhase = .idle
    var loaderMessage = "Ready"

    var descriptor: MachineDescriptor {
        MachineCatalog.descriptor(for: selectedModel)
    }

    var availablePresets: [SoftwarePreset] {
        SoftwarePresetCatalog.presets(for: selectedModel)
    }

    var presetPlans: [PresetLaunchPlan] {
        availablePresets.map { mediaLibrary.launchPlan(for: $0, descriptor: descriptor) }
    }

    var inventory: MachineLibraryInventory {
        mediaLibrary.inventory(for: selectedModel)
    }

    var attachmentSlots: [MediaAttachmentSlot] {
        MediaAttachmentSlot.allCases.filter { $0.isAvailable(for: selectedModel) }
    }

    var selectedAttachments: MediaAttachments {
        attachments(for: selectedModel)
    }

    var libraryRootPath: String {
        mediaLibrary.rootURL?.path ?? "No UserMedia library found"
    }

    var activeMachineSummary: String {
        if let activePreset {
            return activePreset.launchNotes
        }

        return descriptor.summary
    }

    var runtimeSnapshot: [String] {
        if let lastLaunchPlan {
            return [
                "Backend: \(lastLaunchPlan.backend.displayName)",
                "Firmware: \(lastLaunchPlan.firmwareSummary)",
                "Media: \(lastLaunchPlan.mediaSummary)",
                "Video: External emulator window",
                "Core: \(lastLaunchPlan.executableURL.lastPathComponent)",
                "Log: \(lastLaunchPlan.logURL.path)"
            ]
        }

        return [
            "Backend: \(BackendLauncher.defaultBackendDisplayName(for: selectedModel))",
            "Firmware: \(BackendLauncher.firmwareSummary(for: descriptor, mediaLibrary: mediaLibrary))",
            "Media files: \(inventory.softwareFiles.count)",
            "Attached: \(selectedAttachments.summaryLines(for: selectedModel).joined(separator: " • ").ifEmpty("None"))",
            "Video: External emulator window",
            "Core: \(BackendLauncher.binarySummary(for: selectedModel))",
            "Machine state: \(statusLine)"
        ]
    }

    func selectModel(_ model: MachineModel) {
        stopActiveBackend()
        refreshLibrary()
        loaderTask?.cancel()
        loaderPhase = .idle
        activePreset = nil
        selectedModel = model
        lastLaunchPlan = nil
        statusLine = "\(model.displayName) selected"
        isRunning = false
    }

    func start() {
        launch(
            model: selectedModel,
            preset: nil,
            matchedMediaURL: nil,
            attachments: attachments(for: selectedModel)
        )
    }

    func stop() {
        loaderTask?.cancel()
        loaderPhase = .idle
        stopActiveBackend()
        statusLine = "\(selectedModel.displayName) stopped"
    }

    func reset() {
        let model = activePreset?.machineModel ?? selectedModel
        launch(
            model: model,
            preset: activePreset,
            matchedMediaURL: nil,
            attachments: attachments(for: model),
            usePresetMediaLookup: true
        )
    }

    func stepFrame() {
        statusLine = "Frame stepping is unavailable with external cores"
    }

    func launchPreset(_ preset: SoftwarePreset) {
        let launchPlan = mediaLibrary.launchPlan(for: preset, descriptor: MachineCatalog.descriptor(for: preset.machineModel))
        guard launchPlan.isReady else {
            activePreset = preset
            selectedModel = preset.machineModel
            lastLaunchPlan = nil
            isRunning = false
            statusLine = launchPlan.preparationMessage
            loaderMessage = launchPlan.preparationMessage
            loaderPhase = .idle
            return
        }

        launch(
            model: preset.machineModel,
            preset: preset,
            matchedMediaURL: launchPlan.matchedMediaURL,
            attachments: attachments(for: preset.machineModel)
        )
    }

    func refreshLibrary() {
        mediaLibrary = LocalMediaLibrary.scan()
    }

    func importMediaForSelectedModel() {
        importMedia(for: selectedModel)
    }

    func importMedia(for model: MachineModel) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.resolvesAliases = true
        panel.title = "Add media to \(model.displayName)"
        panel.message = "Selected files will be copied into the local catalog for \(model.displayName)."

        guard panel.runModal() == .OK else {
            return
        }

        do {
            let destinationDirectory = try ensureWritableSoftwareDirectory(for: model)
            let (importedCount, skippedCount) = try copyImportedMedia(from: panel.urls, to: destinationDirectory)
            refreshLibrary()

            if importedCount == 0 {
                statusLine = skippedCount == 0
                    ? "No files imported"
                    : "No recognized Atari media selected"
                return
            }

            if skippedCount == 0 {
                statusLine = "Imported \(importedCount) file(s) into \(model.displayName)"
            } else {
                statusLine = "Imported \(importedCount) file(s), skipped \(skippedCount)"
            }
        } catch {
            statusLine = "Import failed: \(error.localizedDescription)"
        }
    }

    func importFirmware() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.resolvesAliases = true
        panel.title = "Add firmware"
        panel.message = "Selected ROM/TOS/EmuTOS files will be copied into the local firmware library."

        guard panel.runModal() == .OK else {
            return
        }

        do {
            let (importedCount, skippedCount) = try copyImportedFirmware(from: panel.urls)
            refreshLibrary()

            if importedCount == 0 {
                statusLine = skippedCount == 0
                    ? "No firmware imported"
                    : "No recognizable firmware selected"
                return
            }

            if skippedCount == 0 {
                statusLine = "Imported \(importedCount) firmware file(s)"
            } else {
                statusLine = "Imported \(importedCount) firmware file(s), skipped \(skippedCount)"
            }
        } catch {
            statusLine = "Firmware import failed: \(error.localizedDescription)"
        }
    }

    func revealUserMediaLibrary() {
        let root = WorkspacePaths.writableUserMediaRoot()
        NSWorkspace.shared.activateFileViewerSelecting([root])
    }

    func attachmentURL(for slot: MediaAttachmentSlot) -> URL? {
        attachments(for: selectedModel)[slot]
    }

    func chooseMediaAttachment(for slot: MediaAttachmentSlot) {
        let model = selectedModel
        guard slot.isAvailable(for: model) else {
            statusLine = "\(slot.title(for: model)) is unavailable for \(model.displayName)"
            return
        }

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.resolvesAliases = true
        panel.title = "Select \(slot.title(for: model)) media"
        panel.message = "\(slot.notes(for: model)) Supported extensions: \(BackendLauncher.supportedAttachmentExtensions(for: slot, model: model).joined(separator: ", "))"
        panel.directoryURL = suggestedAttachmentDirectory(for: model)

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            return
        }

        guard BackendLauncher.isAttachableMedia(selectedURL, to: slot, for: model) else {
            statusLine = "\(selectedURL.lastPathComponent) is not valid for \(slot.title(for: model))"
            return
        }

        var updated = attachments(for: model)
        updated[slot] = selectedURL
        manualAttachmentsByModel[model] = updated
        statusLine = "Attached \(selectedURL.lastPathComponent) to \(slot.title(for: model))"
    }

    func clearMediaAttachment(for slot: MediaAttachmentSlot) {
        let model = selectedModel
        var updated = attachments(for: model)

        guard updated[slot] != nil else {
            return
        }

        updated[slot] = nil
        manualAttachmentsByModel[model] = updated
        statusLine = "Cleared \(slot.title(for: model))"
    }

    private func launch(
        model: MachineModel,
        preset: SoftwarePreset?,
        matchedMediaURL: URL?,
        attachments: MediaAttachments,
        usePresetMediaLookup: Bool = false
    ) {
        stopActiveBackend()
        refreshLibrary()
        loaderTask?.cancel()

        activePreset = preset
        selectedModel = model
        lastLaunchPlan = nil
        isRunning = false
        statusLine = "Preparing \(preset?.name ?? model.displayName)"
        loaderMessage = "Resolving firmware and backend"
        loaderPhase = .bootSplash

        loaderTask = Task { [weak self] in
            guard let self else { return }

            do {
                let resolvedMediaURL: URL?
                if usePresetMediaLookup, let preset {
                    let launchPlan = self.mediaLibrary.launchPlan(for: preset, descriptor: MachineCatalog.descriptor(for: model))
                    resolvedMediaURL = launchPlan.matchedMediaURL
                } else {
                    resolvedMediaURL = matchedMediaURL
                }

                let plan = try BackendLauncher.prepareLaunch(
                    model: model,
                    preset: preset,
                    matchedMediaURL: resolvedMediaURL,
                    attachments: attachments,
                    mediaLibrary: self.mediaLibrary
                )

                guard !Task.isCancelled else { return }

                self.loaderPhase = .rainbow
                self.loaderMessage = "Launching \(plan.backend.displayName)"

                let activeBackend = try BackendLauncher.launch(plan: plan) { [weak self] status, reason in
                    Task { @MainActor in
                        guard let self else { return }
                        let failureSummary = status == 0 ? nil : BackendLauncher.launchFailureSummary(from: plan.logURL)
                        self.isRunning = false
                        self.loaderPhase = .idle
                        self.loaderMessage = "Ready"
                        if let failureSummary {
                            self.statusLine = failureSummary
                        } else {
                            self.statusLine = "Exited (\(reason == .exit ? "code" : "signal") \(status))"
                        }
                    }
                }

                guard !Task.isCancelled else {
                    activeBackend.terminate()
                    return
                }

                self.activeBackend = activeBackend
                self.lastLaunchPlan = plan
                self.isRunning = true
                self.statusLine = "\(plan.backend.displayName) running"
                self.loaderMessage = "Ready"
                self.loaderPhase = .idle
            } catch {
                guard !Task.isCancelled else { return }
                self.loaderPhase = .idle
                self.loaderMessage = error.localizedDescription
                self.statusLine = error.localizedDescription
                self.isRunning = false
            }
        }
    }

    private func stopActiveBackend() {
        activeBackend?.terminate()
        activeBackend = nil
        isRunning = false
    }

    private func attachments(for model: MachineModel) -> MediaAttachments {
        manualAttachmentsByModel[model] ?? .empty
    }

    private func suggestedAttachmentDirectory(for model: MachineModel) -> URL? {
        if let rootURL = mediaLibrary.rootURL {
            let softwareDirectory = rootURL.appendingPathComponent("Software/\(model.rawValue)", isDirectory: true)
            if FileManager.default.fileExists(atPath: softwareDirectory.path) {
                return softwareDirectory
            }
            return rootURL
        }

        return WorkspacePaths.repositoryRoot(fileManager: .default)
    }

    private func ensureWritableSoftwareDirectory(for model: MachineModel) throws -> URL {
        let root = WorkspacePaths.writableUserMediaRoot()
        let softwareDirectory = root.appendingPathComponent("Software/\(model.rawValue)", isDirectory: true)
        try FileManager.default.createDirectory(at: softwareDirectory, withIntermediateDirectories: true)
        return softwareDirectory
    }

    private func ensureWritableFirmwareDirectories() throws -> (atari: URL, emuTOS: URL) {
        let root = WorkspacePaths.writableUserMediaRoot()
        let atariDirectory = root.appendingPathComponent("Firmware/Atari", isDirectory: true)
        let emuTOSDirectory = root.appendingPathComponent("Firmware/EmuTOS", isDirectory: true)
        let fileManager = FileManager.default

        try fileManager.createDirectory(at: atariDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: emuTOSDirectory, withIntermediateDirectories: true)

        return (atariDirectory, emuTOSDirectory)
    }

    private func copyImportedMedia(from sourceURLs: [URL], to destinationDirectory: URL) throws -> (imported: Int, skipped: Int) {
        let fileManager = FileManager.default
        var importedCount = 0
        var skippedCount = 0

        for sourceURL in sourceURLs {
            guard SupportedMediaFormats.isRecognizedSoftware(sourceURL) else {
                skippedCount += 1
                continue
            }

            let destinationURL = uniqueDestinationURL(
                for: sourceURL.lastPathComponent,
                in: destinationDirectory,
                fileManager: fileManager
            )

            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            importedCount += 1
        }

        return (importedCount, skippedCount)
    }

    private func copyImportedFirmware(from sourceURLs: [URL]) throws -> (imported: Int, skipped: Int) {
        let fileManager = FileManager.default
        let destinations = try ensureWritableFirmwareDirectories()
        var importedCount = 0
        var skippedCount = 0

        for sourceURL in sourceURLs {
            guard let targetDirectory = firmwareTargetDirectory(for: sourceURL, destinations: destinations) else {
                skippedCount += 1
                continue
            }

            let destinationURL = uniqueDestinationURL(
                for: sourceURL.lastPathComponent,
                in: targetDirectory,
                fileManager: fileManager
            )

            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            importedCount += 1
        }

        return (importedCount, skippedCount)
    }

    private func firmwareTargetDirectory(for sourceURL: URL, destinations: (atari: URL, emuTOS: URL)) -> URL? {
        guard SupportedMediaFormats.isRecognizedFirmware(sourceURL) else {
            return nil
        }

        let name = sourceURL.lastPathComponent.lowercased()
        if name.contains("emutos") || name.contains("etos") {
            return destinations.emuTOS
        }

        return destinations.atari
    }

    private func uniqueDestinationURL(for filename: String, in directory: URL, fileManager: FileManager) -> URL {
        let sourceURL = URL(fileURLWithPath: filename)
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let pathExtension = sourceURL.pathExtension

        var candidateURL = directory.appendingPathComponent(filename)
        var counter = 2

        while fileManager.fileExists(atPath: candidateURL.path) {
            let uniqueName: String
            if pathExtension.isEmpty {
                uniqueName = "\(baseName)-\(counter)"
            } else {
                uniqueName = "\(baseName)-\(counter).\(pathExtension)"
            }
            candidateURL = directory.appendingPathComponent(uniqueName)
            counter += 1
        }

        return candidateURL
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
