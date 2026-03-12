import Foundation

public enum MachineFactory {
    public static func makeMachine(for model: MachineModel) -> EmulatedMachine {
        ProfiledMachine(model: model)
    }

    public static var catalog: [MachineDescriptor] {
        MachineCatalog.allDescriptors
    }
}
