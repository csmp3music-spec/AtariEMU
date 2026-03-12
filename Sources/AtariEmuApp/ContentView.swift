import AtariEmuCore
import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: EmulatorViewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationSplitView {
            List(MachineModel.allCases) { model in
                Button {
                    viewModel.selectModel(model)
                } label: {
                    machineRow(model, isSelected: model == viewModel.selectedModel)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Machines")
            .listStyle(.sidebar)
        } detail: {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        controlRow
                        screenPreview
                        localLibrarySection
                        presetsSection
                        targetsSection
                        subsystemSection
                        firmwareSection
                        mediaSection
                        operatingSystemsSection
                        captureSection
                    }
                    .padding(24)
                }

                if viewModel.loaderPhase != .idle {
                    LoaderOverlay(
                        phase: viewModel.loaderPhase,
                        title: viewModel.activePreset?.name ?? viewModel.descriptor.model.displayName,
                        subtitle: viewModel.loaderMessage
                    )
                    .transition(.opacity)
                }
            }
            .navigationTitle(viewModel.descriptor.model.displayName)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text(viewModel.descriptor.model.displayName)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                if viewModel.descriptor.isVirtualPreset {
                    Text("Virtual Preset")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.15), in: Capsule())
                }
            }
            Text(viewModel.descriptor.summary)
                .foregroundStyle(.secondary)
            HStack(spacing: 18) {
                metric(title: "Family", value: viewModel.descriptor.familyName)
                metric(title: "CPU", value: viewModel.descriptor.cpuDescription)
                metric(title: "Clock", value: "\(viewModel.descriptor.defaultClockHz.formatted()) Hz")
                metric(title: "RAM", value: viewModel.descriptor.ramDescription)
                metric(title: "Storage", value: viewModel.descriptor.storageDescription)
                metric(title: "Backend", value: BackendLauncher.defaultBackendDisplayName(for: viewModel.selectedModel))
                metric(title: "Video", value: "External Window")
            }
        }
    }

    private var controlRow: some View {
        HStack(spacing: 12) {
            Button("Launch") {
                viewModel.start()
            }
            .buttonStyle(.borderedProminent)

            Button("Stop") {
                viewModel.stop()
            }
            .buttonStyle(.bordered)

            Button("Relaunch") {
                viewModel.reset()
            }
            .buttonStyle(.bordered)

            Button("Rescan Media") {
                viewModel.refreshLibrary()
            }
            .buttonStyle(.bordered)

            Button("Add Media") {
                viewModel.importMediaForSelectedModel()
            }
            .buttonStyle(.bordered)

            Button("Add Firmware") {
                viewModel.importFirmware()
            }
            .buttonStyle(.bordered)

            Button("Open Library") {
                viewModel.revealUserMediaLibrary()
            }
            .buttonStyle(.bordered)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let preset = viewModel.activePreset {
                    Text("Preset: \(preset.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(viewModel.statusLine)
                    .font(.callout.monospaced())
                    .foregroundStyle(viewModel.isRunning ? .green : .secondary)
            }
        }
    }

    private var screenPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.07, green: 0.09, blue: 0.12),
                            Color(red: 0.01, green: 0.02, blue: 0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 12) {
                Text(viewModel.activePreset?.name ?? viewModel.descriptor.model.displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Text(viewModel.activeMachineSummary)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, 28)
                Text("Rendering runs in a separate emulator window with native fullscreen support.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.horizontal, 28)
                VStack(spacing: 6) {
                    ForEach(viewModel.runtimeSnapshot, id: \.self) { line in
                        Text(line)
                            .font(.callout.monospaced())
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
        }
        .frame(height: 260)
        .overlay(alignment: .topLeading) {
            Text(viewModel.descriptor.model.displayName.uppercased())
                .font(.caption.monospaced())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.35), in: Capsule())
                .padding(16)
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    private var localLibrarySection: some View {
        section(title: "Local Library") {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.libraryRootPath)
                    .font(.callout.monospaced())
                HStack(spacing: 18) {
                    metric(title: "Firmware", value: "\(viewModel.inventory.firmwareCount)")
                    metric(title: "Software", value: "\(viewModel.inventory.softwareFiles.count)")
                    metric(title: "Ready Presets", value: "\(viewModel.presetPlans.filter(\.isReady).count)/\(viewModel.presetPlans.count)")
                }
            }
            .padding(14)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var presetsSection: some View {
        section(title: "Run Presets") {
            if viewModel.availablePresets.isEmpty {
                Text("No software presets are defined for this machine yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.presetPlans) { plan in
                    let acquisitionLink = PresetAcquisitionCatalog.link(for: plan.preset)
                    HStack(alignment: .top, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(plan.preset.name)
                                .font(.headline)
                            Text("\(plan.preset.category) • \(plan.preset.availability.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(plan.preset.launchNotes)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Text("\(plan.readinessLabel) • \(plan.matchSource) • \(plan.matchedMediaName)")
                                .font(.caption)
                                .foregroundStyle(plan.isReady ? .green : .secondary)
                            if let acquisitionLink, !plan.isReady {
                                Text(acquisitionLink.sourceDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if plan.isReady {
                            Button("Load") {
                                viewModel.launchPreset(plan.preset)
                            }
                            .buttonStyle(.borderedProminent)
                        } else if let acquisitionLink {
                            VStack(spacing: 8) {
                                Button(acquisitionLink.label) {
                                    openURL(acquisitionLink.url)
                                }
                                .buttonStyle(.bordered)

                                Button("Import Here") {
                                    viewModel.importMedia(for: plan.preset.machineModel)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        } else {
                            Button("Import Here") {
                                viewModel.importMedia(for: plan.preset.machineModel)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(14)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var targetsSection: some View {
        section(title: "Emulation Targets") {
            ForEach(viewModel.descriptor.hardwareTargets, id: \.self) { target in
                Text(target)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var subsystemSection: some View {
        section(title: "Subsystems") {
            ForEach(viewModel.descriptor.subsystemNames, id: \.self) { subsystem in
                Text(subsystem)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var firmwareSection: some View {
        section(title: "Firmware") {
            legalBanner
            ForEach(viewModel.descriptor.firmwareSlots, id: \.name) { slot in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(slot.name)
                            .font(.headline)
                        Spacer()
                        Text(slot.isRequired ? "Required" : "Optional")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(slot.isRequired ? .red : .secondary)
                    }
                    ForEach(slot.options, id: \.name) { option in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(option.name)
                                    .font(.callout.weight(.medium))
                                Spacer()
                                Text(option.distributionPolicy.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(option.distributionPolicy == .bundleableOpenSource ? .green : .secondary)
                            }
                            Text(option.notes)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(14)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var mediaSection: some View {
        section(title: "Boot Media") {
            ForEach(viewModel.descriptor.mediaSlots, id: \.name) { slot in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(slot.name)
                            .font(.headline)
                        Spacer()
                        Text(slot.isRequired ? "Required" : "Optional")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(slot.isRequired ? .red : .secondary)
                    }
                    Text(slot.notes)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var operatingSystemsSection: some View {
        section(title: "OS Profiles") {
            ForEach(viewModel.descriptor.operatingProfiles, id: \.name) { profile in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(profile.name)
                            .font(.headline)
                        Spacer()
                        Text(profile.availability)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text(profile.notes)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var captureSection: some View {
        section(title: "Capture / Export") {
            VStack(alignment: .leading, spacing: 12) {
                metricRow(title: "Video", values: viewModel.descriptor.captureSupport.videoFormats)
                metricRow(title: "Audio", values: viewModel.descriptor.captureSupport.audioFormats)
                Text(viewModel.descriptor.captureSupport.notes)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var legalBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Original Atari ROMs, TOS, Atari DOS, and commercial software remain user-supplied in this project.")
                .font(.headline)
            Text("EmuTOS is the default legal firmware path for ST, TT, and Falcon-class machines where open-source firmware is acceptable. Presets describe launch flows, but they do not embed copyrighted media.")
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private func machineRow(_ model: MachineModel, isSelected: Bool) -> some View {
        let descriptor = MachineCatalog.descriptor(for: model)

        return VStack(alignment: .leading, spacing: 4) {
            Text(model.displayName)
                .font(.headline)
                .foregroundStyle(isSelected ? .primary : .primary)
            Text("\(descriptor.familyName) • \(descriptor.cpuDescription)")
                .font(.caption)
                .foregroundStyle(isSelected ? Color.primary.opacity(0.72) : Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.06))
        )
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))
            content()
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.medium))
        }
        .frame(minWidth: 140, alignment: .leading)
    }

    private func metricRow(title: String, values: [String]) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)
            Text(values.joined(separator: ", "))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
