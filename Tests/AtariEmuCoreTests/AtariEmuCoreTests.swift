import AtariEmuCore
import Testing

@Test
func machineCatalogIncludesExpandedTargets() {
    let models = Set(MachineFactory.catalog.map(\.model))

    #expect(models.count == MachineModel.allCases.count)
    #expect(models.contains(.superXL))
    #expect(models.contains(.superST))
    #expect(models.contains(.superTT))
    #expect(models.contains(.superMaxFalcon))
    #expect(models.contains(.superFalconX1200))
}

@Test
func xlFrameStepAdvancesCounters() {
    let session = EmulatorSession(model: .atariXL)

    session.runFrame()

    #expect(session.runtimeState.executedFrames == 1)
    #expect(session.runtimeState.accumulatedCycles > 0)
}

@Test
func falconDescriptorIncludesDSPAndLinuxProfile() {
    let descriptor = MachineCatalog.descriptor(for: .atariFalcon030)

    #expect(descriptor.subsystemNames.contains("DSP56001 coprocessor"))
    #expect(descriptor.operatingProfiles.contains { $0.name == "Linux/m68k" })
}

@Test
func superFalconDescriptorExposesHighEndPreset() {
    let descriptor = MachineCatalog.descriptor(for: .superFalconX1200)

    #expect(descriptor.isVirtualPreset)
    #expect(descriptor.ramDescription == "1 GB RAM")
    #expect(descriptor.storageDescription == "1 GB virtual IDE hard disk")
}

@Test
func superMaxFalconDescriptorUsesResearchedCeilings() {
    let descriptor = MachineCatalog.descriptor(for: .superMaxFalcon)

    #expect(descriptor.isVirtualPreset)
    #expect(descriptor.defaultClockHz == 32_000_000)
    #expect(descriptor.ramDescription == "14 MiB ST-RAM + 1024 MiB TT-RAM")
    #expect(descriptor.subsystemNames.contains("DSP56001 coprocessor"))
}

@Test
func presetCatalogIncludesNamedSoftware() {
    let presetNames = Set(SoftwarePresetCatalog.presets(for: .atariXL).map(\.name))

    #expect(presetNames.contains("AtariWriter"))
    #expect(presetNames.contains("Ice-T"))
    #expect(presetNames.contains("Colourspace"))
}
