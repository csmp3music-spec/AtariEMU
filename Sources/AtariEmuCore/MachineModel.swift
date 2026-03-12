import Foundation

public enum MachineModel: String, CaseIterable, Codable, Sendable, Hashable, Identifiable {
    case atariXL
    case atariXE
    case atari65XE
    case atari130XE
    case superXL
    case superMaxXL
    case atariSTF
    case atariMegaST
    case atariStacy
    case atariSTE
    case atariMegaSTE
    case superST
    case superMegaST
    case superMaxST
    case atariTT030
    case superTT
    case superMaxTT
    case atariFalcon030
    case superMaxFalcon
    case superFalconX1200

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .atariXL:
            return "Atari XL"
        case .atariXE:
            return "Atari XE"
        case .atari65XE:
            return "Atari 65XE"
        case .atari130XE:
            return "Atari 130XE"
        case .superXL:
            return "Super XL"
        case .superMaxXL:
            return "Super Max XL"
        case .atariSTF:
            return "Atari ST/F"
        case .atariMegaST:
            return "Atari Mega ST"
        case .atariStacy:
            return "Atari Stacy"
        case .atariSTE:
            return "Atari STE"
        case .atariMegaSTE:
            return "Atari Mega STE"
        case .superST:
            return "Super ST"
        case .superMegaST:
            return "Super Mega ST"
        case .superMaxST:
            return "Super Max ST"
        case .atariTT030:
            return "Atari TT030"
        case .superTT:
            return "Super TT"
        case .superMaxTT:
            return "Super Max TT"
        case .atariFalcon030:
            return "Atari Falcon030"
        case .superMaxFalcon:
            return "Super Max Falcon"
        case .superFalconX1200:
            return "Super Falcon X1200"
        }
    }
}
