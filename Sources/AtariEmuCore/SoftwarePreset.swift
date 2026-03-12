import Foundation

public enum SoftwarePresetAvailability: String, Equatable, Sendable {
    case userSuppliedMedia = "User-supplied media"
    case bundledOpenSource = "Bundled open-source"
}

public struct SoftwarePreset: Identifiable, Equatable, Sendable {
    public let machineModel: MachineModel
    public let name: String
    public let category: String
    public let availability: SoftwarePresetAvailability
    public let requiresExternalMedia: Bool
    public let launchNotes: String

    public var id: String {
        "\(machineModel.rawValue)::\(name)"
    }

    public init(
        machineModel: MachineModel,
        name: String,
        category: String,
        availability: SoftwarePresetAvailability,
        requiresExternalMedia: Bool = true,
        launchNotes: String
    ) {
        self.machineModel = machineModel
        self.name = name
        self.category = category
        self.availability = availability
        self.requiresExternalMedia = requiresExternalMedia
        self.launchNotes = launchNotes
    }
}

public enum SoftwarePresetCatalog {
    public static let all: [SoftwarePreset] = [
        SoftwarePreset(
            machineModel: .atariXL,
            name: "AtariWriter",
            category: "Productivity",
            availability: .userSuppliedMedia,
            launchNotes: "Boot the XL profile directly into a user-supplied AtariWriter disk."
        ),
        SoftwarePreset(
            machineModel: .atariXL,
            name: "Ice-T",
            category: "Utility",
            availability: .userSuppliedMedia,
            launchNotes: "Auto-attach the user-supplied Ice-T disk and cold boot the XL."
        ),
        SoftwarePreset(
            machineModel: .atariXL,
            name: "Colourspace",
            category: "Graphics",
            availability: .userSuppliedMedia,
            launchNotes: "Boot the XL profile into a user-supplied Colourspace disk image."
        ),
        SoftwarePreset(
            machineModel: .atariXE,
            name: "AtariWriter",
            category: "Productivity",
            availability: .userSuppliedMedia,
            launchNotes: "Boot the XE profile with a user-supplied AtariWriter disk."
        ),
        SoftwarePreset(
            machineModel: .atari65XE,
            name: "Ice-T",
            category: "Utility",
            availability: .userSuppliedMedia,
            launchNotes: "Auto-load a user-supplied Ice-T image on the 65XE profile."
        ),
        SoftwarePreset(
            machineModel: .atari130XE,
            name: "Colourspace",
            category: "Graphics",
            availability: .userSuppliedMedia,
            launchNotes: "Use the 130XE profile and attach a user-supplied Colourspace disk."
        ),
        SoftwarePreset(
            machineModel: .superXL,
            name: "AtariWriter Turbo",
            category: "Productivity",
            availability: .userSuppliedMedia,
            launchNotes: "Launch the Super XL preset with expanded RAM and a user-supplied AtariWriter disk."
        ),
        SoftwarePreset(
            machineModel: .superMaxXL,
            name: "FastBasic Max",
            category: "Language",
            availability: .userSuppliedMedia,
            launchNotes: "Launch the Super Max XL preset with your FastBasic ATR or XEX media."
        ),
        SoftwarePreset(
            machineModel: .atariSTF,
            name: "1st Word Plus",
            category: "Productivity",
            availability: .userSuppliedMedia,
            launchNotes: "Boot the ST/F profile with a user-supplied 1st Word Plus disk."
        ),
        SoftwarePreset(
            machineModel: .atariSTF,
            name: "DEGAS Elite",
            category: "Graphics",
            availability: .userSuppliedMedia,
            launchNotes: "Attach a user-supplied DEGAS Elite disk and boot the ST/F profile."
        ),
        SoftwarePreset(
            machineModel: .atariMegaST,
            name: "ST Writer Elite",
            category: "Productivity",
            availability: .userSuppliedMedia,
            launchNotes: "Auto-load ST Writer Elite from user-supplied media on the Mega ST profile."
        ),
        SoftwarePreset(
            machineModel: .atariStacy,
            name: "Portable TOS Desktop",
            category: "Desktop",
            availability: .bundledOpenSource,
            requiresExternalMedia: false,
            launchNotes: "Boot the Stacy profile into TOS or EmuTOS desktop mode."
        ),
        SoftwarePreset(
            machineModel: .atariSTE,
            name: "Cubase",
            category: "Music",
            availability: .userSuppliedMedia,
            launchNotes: "Attach a user-supplied Cubase disk and start the STE profile."
        ),
        SoftwarePreset(
            machineModel: .atariMegaSTE,
            name: "Atari MiNT Desktop",
            category: "OS",
            availability: .userSuppliedMedia,
            launchNotes: "Boot the Mega STE profile into a user-supplied Atari MiNT environment."
        ),
        SoftwarePreset(
            machineModel: .superST,
            name: "DEGAS Elite Turbo",
            category: "Graphics",
            availability: .userSuppliedMedia,
            launchNotes: "Launch the Super ST preset and auto-attach a user-supplied graphics disk."
        ),
        SoftwarePreset(
            machineModel: .superMaxST,
            name: "TeraDesk Max",
            category: "Desktop",
            availability: .userSuppliedMedia,
            launchNotes: "Launch the Super Max ST preset with a TeraDesk or FreeMiNT disk/hard-disk image."
        ),
        SoftwarePreset(
            machineModel: .superMegaST,
            name: "MiNT Workstation",
            category: "OS",
            availability: .userSuppliedMedia,
            launchNotes: "Boot the Super Mega ST preset into a user-supplied Atari MiNT hard disk image."
        ),
        SoftwarePreset(
            machineModel: .atariTT030,
            name: "Calamus SL",
            category: "Desktop Publishing",
            availability: .userSuppliedMedia,
            launchNotes: "Attach user-supplied Calamus media and boot the TT030 workstation profile."
        ),
        SoftwarePreset(
            machineModel: .atariTT030,
            name: "Linux/m68k Shell",
            category: "OS",
            availability: .userSuppliedMedia,
            launchNotes: "Boot a user-supplied Linux/m68k kernel and root image on the TT030 profile."
        ),
        SoftwarePreset(
            machineModel: .superTT,
            name: "MiNT X Desktop",
            category: "OS",
            availability: .userSuppliedMedia,
            launchNotes: "Launch the Super TT preset with a user-supplied MiNT workstation disk."
        ),
        SoftwarePreset(
            machineModel: .superMaxTT,
            name: "NetSurf Atari Max",
            category: "Browser",
            availability: .userSuppliedMedia,
            launchNotes: "Launch the Super Max TT preset with an AFROS, FreeMiNT, or NetSurf-ready hard disk image."
        ),
        SoftwarePreset(
            machineModel: .atariFalcon030,
            name: "Cubase Audio Falcon",
            category: "Music",
            availability: .userSuppliedMedia,
            launchNotes: "Boot the Falcon profile with a user-supplied Cubase Audio Falcon image."
        ),
        SoftwarePreset(
            machineModel: .atariFalcon030,
            name: "Linux/m68k Shell",
            category: "OS",
            availability: .userSuppliedMedia,
            launchNotes: "Use user-supplied Linux/m68k media on the Falcon profile."
        ),
        SoftwarePreset(
            machineModel: .superFalconX1200,
            name: "MiNT Studio",
            category: "OS",
            availability: .userSuppliedMedia,
            launchNotes: "Launch the Super Falcon X1200 preset with a user-supplied MiNT workstation disk."
        ),
        SoftwarePreset(
            machineModel: .superMaxFalcon,
            name: "AFROS Falcon Max",
            category: "OS",
            availability: .userSuppliedMedia,
            launchNotes: "Launch the Super Max Falcon preset with an AFROS or FreeMiNT Falcon hard disk image."
        )
    ]

    public static func presets(for model: MachineModel) -> [SoftwarePreset] {
        all.filter { $0.machineModel == model }
    }
}
