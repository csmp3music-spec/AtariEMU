import Foundation

public enum MachineCatalog {
    public static func descriptor(for model: MachineModel) -> MachineDescriptor {
        switch model {
        case .atariXL:
            return eightBitDescriptor(
                model: model,
                displaySummary: "General XL-class Atari 8-bit configuration for ANTIC/GTIA/POKEY software.",
                ramDescription: "64 KB RAM",
                extraHardware: [
                    "SIO peripheral bus",
                    "Cartridge and cassette interfaces"
                ]
            )
        case .atariXE:
            return eightBitDescriptor(
                model: model,
                displaySummary: "General XE-class Atari 8-bit configuration for later XE-era software and peripherals.",
                ramDescription: "64 KB RAM",
                extraHardware: [
                    "XE keyboard and I/O layout",
                    "SIO peripheral bus"
                ]
            )
        case .atari65XE:
            return eightBitDescriptor(
                model: model,
                displaySummary: "65XE profile with XE-era compatibility target and compact RAM map.",
                ramDescription: "64 KB RAM",
                extraHardware: [
                    "XE memory map",
                    "SIO peripheral bus"
                ]
            )
        case .atari130XE:
            return eightBitDescriptor(
                model: model,
                displaySummary: "130XE profile with bank-switched memory support for later Atari 8-bit software.",
                ramDescription: "128 KB bank-switched RAM",
                extraHardware: [
                    "XE bank-switched memory expansion",
                    "SIO peripheral bus"
                ]
            )
        case .superXL:
            return MachineDescriptor(
                model: model,
                familyName: "XL/XE Virtual Preset",
                cpuDescription: "Virtualized 6502C-compatible core",
                defaultClockHz: 14_320_000,
                summary: "Non-historical XL/XE power preset with turbo timing, expanded memory, and oversized virtual media for aggressive 8-bit workflows.",
                ramDescription: "1 MB extended RAM",
                storageDescription: "512 MB virtual SIO hard disk",
                isVirtualPreset: true,
                subsystemNames: [
                    "Virtualized 6502-compatible CPU",
                    "ANTIC display processor",
                    "GTIA graphics",
                    "POKEY audio and I/O",
                    "Extended RAM and virtual storage"
                ],
                hardwareTargets: [
                    "Turbo 8-bit timing profile",
                    "Expanded memory banking",
                    "Large virtual media support"
                ],
                firmwareSlots: eightBitFirmwareSlots(),
                mediaSlots: eightBitMediaSlots(),
                operatingProfiles: eightBitOperatingProfiles(),
                captureSupport: standardCaptureSupport(),
                targetVideoRateHz: 59.92
            )
        case .superMaxXL:
            return MachineDescriptor(
                model: model,
                familyName: "XL/XE Super Max",
                cpuDescription: "Virtualized 6502C-compatible core",
                defaultClockHz: 14_320_000,
                summary: "Research-backed XL/XE max preset built around Atari800-class 1088K memory expansion, eight drive support, and a virtual turbo CPU profile.",
                ramDescription: "1088 KB XE-compatible expanded RAM",
                storageDescription: "8 virtual SIO drives plus host-backed storage",
                isVirtualPreset: true,
                subsystemNames: [
                    "Virtualized 6502-compatible CPU",
                    "ANTIC display processor",
                    "GTIA graphics",
                    "POKEY audio and I/O",
                    "XE-compatible 1088K memory expansion"
                ],
                hardwareTargets: [
                    "1088K expanded memory profile",
                    "Eight drive SIO workflow",
                    "Virtual turbo CPU profile inferred on top of documented memory expansion support"
                ],
                firmwareSlots: eightBitFirmwareSlots(),
                mediaSlots: eightBitMediaSlots(),
                operatingProfiles: eightBitOperatingProfiles(),
                captureSupport: standardCaptureSupport(),
                targetVideoRateHz: 59.92
            )
        case .atariSTF:
            return stDescriptor(
                model: model,
                familyName: "ST",
                cpuDescription: "Motorola 68000",
                defaultClockHz: 8_000_000,
                summary: "ST/F baseline with TOS-era desktop software target, floppy workflow, and MIDI support.",
                ramDescription: "512 KB to 1 MB RAM",
                storageDescription: "Floppy-first boot, optional ACSI hard disk",
                subsystemNames: [
                    "Motorola 68000 CPU",
                    "Shifter video",
                    "GLUE / MMU chipset",
                    "YM2149 audio",
                    "Floppy, ACSI, and MIDI"
                ]
            )
        case .atariMegaST:
            return stDescriptor(
                model: model,
                familyName: "ST",
                cpuDescription: "Motorola 68000",
                defaultClockHz: 8_000_000,
                summary: "Mega ST workstation profile with desktop-class expansion posture and Atari TOS software focus.",
                ramDescription: "2 MB to 4 MB RAM",
                storageDescription: "Floppy and ACSI hard disk",
                subsystemNames: [
                    "Motorola 68000 CPU",
                    "Shifter video",
                    "GLUE / MMU chipset",
                    "YM2149 audio",
                    "Desktop expansion and ACSI storage"
                ]
            )
        case .atariStacy:
            return stDescriptor(
                model: model,
                familyName: "ST",
                cpuDescription: "Motorola 68000",
                defaultClockHz: 8_000_000,
                summary: "Portable Stacy profile that stays in the ST class while preserving portable-specific timing and I/O expectations.",
                ramDescription: "1 MB to 4 MB RAM",
                storageDescription: "Internal floppy and optional hard disk",
                subsystemNames: [
                    "Motorola 68000 CPU",
                    "Shifter video",
                    "GLUE / MMU chipset",
                    "YM2149 audio",
                    "Portable storage and power-management quirks"
                ]
            )
        case .atariSTE:
            return stDescriptor(
                model: model,
                familyName: "STE",
                cpuDescription: "Motorola 68000",
                defaultClockHz: 8_000_000,
                summary: "STE profile with DMA audio, Blitter, hardware scrolling, and expanded palette behavior.",
                ramDescription: "1 MB to 4 MB RAM",
                storageDescription: "Floppy and optional ACSI hard disk",
                subsystemNames: [
                    "Motorola 68000 CPU",
                    "Enhanced Shifter video",
                    "Blitter",
                    "DMA audio",
                    "Floppy, ACSI, and MIDI"
                ]
            )
        case .atariMegaSTE:
            return stDescriptor(
                model: model,
                familyName: "Mega STE",
                cpuDescription: "Motorola 68000",
                defaultClockHz: 16_000_000,
                summary: "Mega STE profile with faster CPU mode, cache behavior, DMA audio, and workstation-oriented peripherals.",
                ramDescription: "2 MB to 4 MB RAM",
                storageDescription: "Floppy and hard disk",
                subsystemNames: [
                    "Motorola 68000 CPU",
                    "Enhanced Shifter video",
                    "CPU cache and turbo timing",
                    "DMA audio and Blitter",
                    "Workstation storage and serial/MIDI I/O"
                ]
            )
        case .superST:
            return MachineDescriptor(
                model: model,
                familyName: "ST Virtual Preset",
                cpuDescription: "Virtualized 68000-compatible core",
                defaultClockHz: 32_000_000,
                summary: "Non-historical ST power preset with higher CPU speed, oversized RAM, and workstation-style virtual storage.",
                ramDescription: "64 MB RAM",
                storageDescription: "1 GB virtual hard disk",
                isVirtualPreset: true,
                subsystemNames: [
                    "Virtualized 68000-compatible CPU",
                    "Shifter video",
                    "GLUE / MMU chipset",
                    "YM2149 audio",
                    "Virtual hard disk and MIDI"
                ],
                hardwareTargets: [
                    "Turbo ST timing profile",
                    "Atari MiNT boot path",
                    "High-capacity virtual storage"
                ],
                firmwareSlots: tosFirmwareSlots(),
                mediaSlots: sixteenBitMediaSlots(),
                operatingProfiles: workstationProfiles(includeLinux: false),
                captureSupport: standardCaptureSupport(),
                targetVideoRateHz: 60.0
            )
        case .superMegaST:
            return MachineDescriptor(
                model: model,
                familyName: "Mega ST Virtual Preset",
                cpuDescription: "Virtualized 68000-compatible core",
                defaultClockHz: 48_000_000,
                summary: "Non-historical Mega ST workstation preset with fast CPU timing, large RAM, and roomy virtual disks.",
                ramDescription: "128 MB RAM",
                storageDescription: "1 GB virtual hard disk",
                isVirtualPreset: true,
                subsystemNames: [
                    "Virtualized 68000-compatible CPU",
                    "Shifter video",
                    "DMA audio-compatible routing",
                    "Virtual workstation storage",
                    "Serial, MIDI, and hard disk I/O"
                ],
                hardwareTargets: [
                    "Turbo Mega ST timing profile",
                    "Atari MiNT workstation path",
                    "Large-memory productivity workflows"
                ],
                firmwareSlots: tosFirmwareSlots(),
                mediaSlots: sixteenBitMediaSlots(),
                operatingProfiles: workstationProfiles(includeLinux: false),
                captureSupport: standardCaptureSupport(),
                targetVideoRateHz: 60.0
            )
        case .superMaxST:
            return MachineDescriptor(
                model: model,
                familyName: "ST Super Max",
                cpuDescription: "Virtualized 68060-class accelerator profile",
                defaultClockHz: 32_000_000,
                summary: "Research-backed ST super-max preset using the Hatari-class accelerator envelope: 32 MHz CPU clock, up to 14 MiB ST-RAM, and >1 GB ACSI-capable storage support.",
                ramDescription: "14 MiB ST-RAM",
                storageDescription: "2 GB virtual ACSI hard disk",
                isVirtualPreset: true,
                subsystemNames: [
                    "68000-68060 CPU/FPU/MMU profile",
                    "Shifter video",
                    "GLUE / MMU chipset",
                    "YM2149 audio",
                    "Extended ACSI hard disk path"
                ],
                hardwareTargets: [
                    "32 MHz accelerator clock",
                    "14 MiB ST-RAM ceiling",
                    "Accelerator-board style non-standard ST timing"
                ],
                firmwareSlots: tosFirmwareSlots(),
                mediaSlots: sixteenBitMediaSlots(),
                operatingProfiles: workstationProfiles(includeLinux: false),
                captureSupport: standardCaptureSupport(),
                targetVideoRateHz: 60.0
            )
        case .atariTT030:
            return MachineDescriptor(
                model: model,
                familyName: "TT",
                cpuDescription: "Motorola 68030",
                defaultClockHz: 32_000_000,
                summary: "TT workstation profile with 68030 timing, TT-RAM/ST-RAM split, SCSI, MiNT, and Linux/m68k target paths.",
                ramDescription: "2 MB to 256 MB virtual TT-RAM/ST-RAM mix",
                storageDescription: "Floppy, SCSI hard disk, and virtual disk images",
                isVirtualPreset: false,
                subsystemNames: [
                    "Motorola 68030 CPU",
                    "TT video subsystem",
                    "DMA audio",
                    "SCSI, floppy, and serial/MIDI I/O",
                    "TT-RAM / ST-RAM memory map"
                ],
                hardwareTargets: [
                    "68030 exception and MMU behavior",
                    "TT-specific video timing",
                    "MiNT and Linux/m68k boot path"
                ],
                firmwareSlots: tosFirmwareSlots(),
                mediaSlots: sixteenBitMediaSlots(),
                operatingProfiles: workstationProfiles(includeLinux: true),
                captureSupport: standardCaptureSupport(),
                targetVideoRateHz: 60.0
            )
        case .superTT:
            return MachineDescriptor(
                model: model,
                familyName: "TT Virtual Preset",
                cpuDescription: "Virtualized 68030-compatible core",
                defaultClockHz: 96_000_000,
                summary: "Non-historical TT workstation preset with accelerated 68030 timing, large TT-RAM, and roomy virtual disk targets.",
                ramDescription: "512 MB TT-RAM",
                storageDescription: "1 GB virtual SCSI hard disk",
                isVirtualPreset: true,
                subsystemNames: [
                    "Virtualized 68030-compatible CPU",
                    "TT video subsystem",
                    "DMA audio",
                    "SCSI, floppy, and serial/MIDI I/O",
                    "Large TT-RAM / ST-RAM map"
                ],
                hardwareTargets: [
                    "Turbo TT timing profile",
                    "Atari MiNT and Linux/m68k boot path",
                    "Workstation-class memory and storage"
                ],
                firmwareSlots: tosFirmwareSlots(),
                mediaSlots: sixteenBitMediaSlots(),
                operatingProfiles: workstationProfiles(includeLinux: true),
                captureSupport: standardCaptureSupport(),
                targetVideoRateHz: 60.0
            )
        case .superMaxTT:
            return MachineDescriptor(
                model: model,
                familyName: "TT Super Max",
                cpuDescription: "Virtualized 68040/68060 accelerator profile",
                defaultClockHz: 32_000_000,
                summary: "Research-backed TT super-max preset using Hatari-style ceilings: 32 MHz accelerator clock, 14 MiB ST-RAM, and 1024 MiB TT-RAM.",
                ramDescription: "14 MiB ST-RAM + 1024 MiB TT-RAM",
                storageDescription: "2 GB virtual SCSI hard disk",
                isVirtualPreset: true,
                subsystemNames: [
                    "68030-68060 CPU/FPU/MMU profile",
                    "TT video subsystem",
                    "DMA audio",
                    "SCSI, floppy, and serial/MIDI I/O",
                    "Large TT-RAM / ST-RAM map"
                ],
                hardwareTargets: [
                    "32 MHz TT accelerator clock",
                    "1024 MiB TT-RAM ceiling",
                    "MiNT and Linux/m68k workstation path"
                ],
                firmwareSlots: tosFirmwareSlots(),
                mediaSlots: sixteenBitMediaSlots(),
                operatingProfiles: workstationProfiles(includeLinux: true),
                captureSupport: standardCaptureSupport(),
                targetVideoRateHz: 60.0
            )
        case .atariFalcon030:
            return MachineDescriptor(
                model: model,
                familyName: "Falcon",
                cpuDescription: "Motorola 68030 + DSP56001",
                defaultClockHz: 16_000_000,
                summary: "Falcon profile with VIDEL, DMA audio, IDE/SCSI, and explicit DSP56001 emulation in the architecture.",
                ramDescription: "4 MB to 14 MB RAM",
                storageDescription: "Floppy, IDE, SCSI, and virtual disk images",
                isVirtualPreset: false,
                subsystemNames: [
                    "Motorola 68030 CPU",
                    "VIDEL video",
                    "DMA audio",
                    "DSP56001 coprocessor",
                    "IDE, SCSI, floppy, and MIDI"
                ],
                hardwareTargets: [
                    "Cycle-aware VIDEL timing",
                    "DSP56001 emulation path",
                    "MiNT and Linux/m68k boot path"
                ],
                firmwareSlots: tosFirmwareSlots(),
                mediaSlots: sixteenBitMediaSlots(),
                operatingProfiles: workstationProfiles(includeLinux: true),
                captureSupport: standardCaptureSupport(),
                targetVideoRateHz: 60.0
            )
        case .superMaxFalcon:
            return MachineDescriptor(
                model: model,
                familyName: "Falcon Super Max",
                cpuDescription: "Virtualized 68060-class accelerator profile + DSP56001",
                defaultClockHz: 32_000_000,
                summary: "Research-backed Falcon super-max preset using documented Hatari-class ceilings: DSP emulation, 32 MHz accelerator clock, 14 MiB ST-RAM, and 1024 MiB TT-RAM.",
                ramDescription: "14 MiB ST-RAM + 1024 MiB TT-RAM",
                storageDescription: "2 GB virtual IDE/SCSI hard disk",
                isVirtualPreset: true,
                subsystemNames: [
                    "68030-68060 CPU/FPU/MMU profile",
                    "VIDEL video",
                    "DMA audio",
                    "DSP56001 coprocessor",
                    "IDE, SCSI, floppy, and MIDI"
                ],
                hardwareTargets: [
                    "DSP56001 emulation path",
                    "32 MHz accelerator clock",
                    "1024 MiB TT-RAM ceiling with MiNT/Linux support"
                ],
                firmwareSlots: tosFirmwareSlots(),
                mediaSlots: sixteenBitMediaSlots(),
                operatingProfiles: workstationProfiles(includeLinux: true),
                captureSupport: standardCaptureSupport(),
                targetVideoRateHz: 60.0
            )
        case .superFalconX1200:
            return MachineDescriptor(
                model: model,
                familyName: "Falcon Virtual Preset",
                cpuDescription: "Virtualized 68030-compatible core + DSP56001",
                defaultClockHz: 120_000_000,
                summary: "Non-historical power-user Falcon preset with turbo headroom, Falcon DSP path, 1 GB RAM, and a 1 GB virtual disk target.",
                ramDescription: "1 GB RAM",
                storageDescription: "1 GB virtual IDE hard disk",
                isVirtualPreset: true,
                subsystemNames: [
                    "Virtualized 68030-compatible CPU",
                    "VIDEL video",
                    "DMA audio",
                    "DSP56001 coprocessor",
                    "IDE, SCSI, floppy, and MIDI"
                ],
                hardwareTargets: [
                    "DSP56001 emulation path",
                    "Overclocked virtual timing profile",
                    "Large-memory and large-disk stress path"
                ],
                firmwareSlots: tosFirmwareSlots(),
                mediaSlots: sixteenBitMediaSlots(),
                operatingProfiles: workstationProfiles(includeLinux: true),
                captureSupport: standardCaptureSupport(),
                targetVideoRateHz: 60.0
            )
        }
    }

    public static var allDescriptors: [MachineDescriptor] {
        MachineModel.allCases.map(descriptor(for:))
    }

    private static func eightBitDescriptor(
        model: MachineModel,
        displaySummary: String,
        ramDescription: String,
        extraHardware: [String]
    ) -> MachineDescriptor {
        MachineDescriptor(
            model: model,
            familyName: "XL/XE",
            cpuDescription: "MOS 6502C",
            defaultClockHz: 1_790_000,
            summary: displaySummary,
            ramDescription: ramDescription,
            storageDescription: "SIO floppy/cassette and cartridge media",
            isVirtualPreset: false,
            subsystemNames: [
                "6502-compatible CPU",
                "ANTIC display processor",
                "GTIA graphics",
                "POKEY audio and I/O"
            ] + extraHardware,
            hardwareTargets: [
                "Cycle-aware ANTIC/GTIA timing",
                "POKEY audio path",
                "SIO disk and cartridge boot behavior"
            ],
            firmwareSlots: eightBitFirmwareSlots(),
            mediaSlots: eightBitMediaSlots(),
            operatingProfiles: eightBitOperatingProfiles(),
            captureSupport: standardCaptureSupport(),
            targetVideoRateHz: 59.92
        )
    }

    private static func stDescriptor(
        model: MachineModel,
        familyName: String,
        cpuDescription: String,
        defaultClockHz: Int,
        summary: String,
        ramDescription: String,
        storageDescription: String,
        subsystemNames: [String]
    ) -> MachineDescriptor {
        MachineDescriptor(
            model: model,
            familyName: familyName,
            cpuDescription: cpuDescription,
            defaultClockHz: defaultClockHz,
            summary: summary,
            ramDescription: ramDescription,
            storageDescription: storageDescription,
            isVirtualPreset: false,
            subsystemNames: subsystemNames,
            hardwareTargets: [
                "TOS-compatible boot behavior",
                "MIDI and disk-controller timing",
                "Atari MiNT boot path"
            ],
            firmwareSlots: tosFirmwareSlots(),
            mediaSlots: sixteenBitMediaSlots(),
            operatingProfiles: workstationProfiles(includeLinux: false),
            captureSupport: standardCaptureSupport(),
            targetVideoRateHz: 60.0
        )
    }

    private static func tosFirmwareSlots() -> [FirmwareSlot] {
        [
            FirmwareSlot(
                name: "System firmware",
                isRequired: true,
                options: [
                    FirmwareOption(
                        name: "Original Atari TOS ROM",
                        distributionPolicy: .userSuppliedOnly,
                        notes: "Use your own legally obtained Atari TOS image for original firmware behavior."
                    ),
                    FirmwareOption(
                        name: "EmuTOS ROM",
                        distributionPolicy: .bundleableOpenSource,
                        notes: "GPLv2 open-source firmware option for ST, TT, and Falcon-class systems."
                    )
                ]
            )
        ]
    }

    private static func eightBitFirmwareSlots() -> [FirmwareSlot] {
        [
            FirmwareSlot(
                name: "System firmware",
                isRequired: true,
                options: [
                    FirmwareOption(
                        name: "Original Atari XL/XE OS ROM",
                        distributionPolicy: .userSuppliedOnly,
                        notes: "Provide your own legally obtained Atari OS ROM image."
                    )
                ]
            ),
            FirmwareSlot(
                name: "BASIC firmware",
                isRequired: false,
                options: [
                    FirmwareOption(
                        name: "Original Atari BASIC ROM",
                        distributionPolicy: .userSuppliedOnly,
                        notes: "Optional for BASIC boot behavior and software compatibility."
                    )
                ]
            )
        ]
    }

    private static func eightBitMediaSlots() -> [MediaSlot] {
        [
            MediaSlot(
                name: "Disk image",
                isRequired: false,
                notes: "ATR/XFD boot media are user-supplied."
            ),
            MediaSlot(
                name: "Cartridge image",
                isRequired: false,
                notes: "ROM/CAR images are user-supplied."
            ),
            MediaSlot(
                name: "Cassette image",
                isRequired: false,
                notes: "CAS-style media are user-supplied."
            )
        ]
    }

    private static func eightBitOperatingProfiles() -> [OperatingProfile] {
        [
            OperatingProfile(
                name: "Atari DOS",
                availability: "User-supplied disk image",
                notes: "Supported as boot media, but not bundled in this repository."
            ),
            OperatingProfile(
                name: "Host-backed H: device",
                availability: "Virtual host storage",
                notes: "Expose a host-backed storage path for high-capacity virtualized 8-bit presets."
            )
        ]
    }

    private static func sixteenBitMediaSlots() -> [MediaSlot] {
        [
            MediaSlot(
                name: "Floppy image",
                isRequired: false,
                notes: "ST/MSA/IMG media are user-supplied."
            ),
            MediaSlot(
                name: "Hard disk image",
                isRequired: false,
                notes: "ACSI/SCSI/IDE images are user-supplied."
            )
        ]
    }

    private static func workstationProfiles(includeLinux: Bool) -> [OperatingProfile] {
        var profiles = [
            OperatingProfile(
                name: "TOS desktop",
                availability: "Firmware boot path",
                notes: "Boot using original Atari TOS or EmuTOS, depending installed firmware."
            ),
            OperatingProfile(
                name: "Atari MiNT",
                availability: "User-supplied disk image",
                notes: "Expose MiNT as an alternate boot target on ST, STE, TT, and Falcon-class systems."
            )
        ]

        if includeLinux {
            profiles.append(
                OperatingProfile(
                    name: "Linux/m68k",
                    availability: "User-supplied kernel/root media",
                    notes: "Expose an Atari Linux option for TT030, Falcon030, and the Super Falcon preset."
                )
            )
        }

        return profiles
    }

    private static func standardCaptureSupport() -> CaptureSupport {
        CaptureSupport(
            videoFormats: ["MP4"],
            audioFormats: ["FLAC", "AIFF", "MP3"],
            notes: "Export hooks are planned for synchronized video/audio capture once the video and sound pipelines are implemented."
        )
    }
}
