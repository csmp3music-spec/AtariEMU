import AtariEmuCore
import Foundation

struct PresetAcquisitionLink {
    let url: URL
    let label: String
    let sourceDescription: String
}

enum PresetAcquisitionCatalog {
    static func link(for preset: SoftwarePreset) -> PresetAcquisitionLink? {
        switch preset.id {
        case "atariXL::Ice-T", "atari65XE::Ice-T":
            return direct("https://github.com/itaych/Ice-T", label: "Download", source: "Official Ice-T project")
        case "superMaxXL::FastBasic Max":
            return direct("https://github.com/dmsc/fastbasic", label: "Download", source: "Official FastBasic project")
        case "atariStacy::Portable TOS Desktop":
            return direct("https://emutos.sourceforge.io/en/download.htm", label: "Download", source: "Official EmuTOS download page")
        case "atariMegaSTE::Atari MiNT Desktop",
             "superMegaST::MiNT Workstation",
             "superTT::MiNT X Desktop",
             "superFalconX1200::MiNT Studio":
            return direct("https://freemint.github.io/", label: "Download", source: "Official FreeMiNT project")
        case "superMaxST::TeraDesk Max":
            return direct("https://github.com/freemint/teradesk", label: "Download", source: "Official TeraDesk repository")
        case "atariTT030::Linux/m68k Shell",
             "atariFalcon030::Linux/m68k Shell":
            return direct("https://www.debian.org/ports/m68k/", label: "Download", source: "Official Debian m68k port page")
        case "superMaxTT::NetSurf Atari Max":
            return direct("https://www.netsurf-browser.org/downloads/atari/", label: "Download", source: "Official NetSurf Atari downloads")
        case "superMaxFalcon::AFROS Falcon Max":
            return direct("https://aranym.github.io/afros.html", label: "Download", source: "Official AFROS page")
        default:
            return fallbackSearch(for: preset)
        }
    }

    private static func direct(_ urlString: String, label: String, source: String) -> PresetAcquisitionLink? {
        guard let url = URL(string: urlString) else {
            return nil
        }

        return PresetAcquisitionLink(
            url: url,
            label: label,
            sourceDescription: source
        )
    }

    private static func fallbackSearch(for preset: SoftwarePreset) -> PresetAcquisitionLink? {
        var components = URLComponents(string: "https://duckduckgo.com/")
        components?.queryItems = [
            URLQueryItem(
                name: "q",
                value: "\"\(preset.name)\" \(preset.machineModel.displayName) Atari site:atarimania.com OR site:atariage.com"
            )
        ]

        guard let url = components?.url else {
            return nil
        }

        return PresetAcquisitionLink(
            url: url,
            label: "Find Media",
            sourceDescription: "AtariAge/Atarimania web search"
        )
    }
}
