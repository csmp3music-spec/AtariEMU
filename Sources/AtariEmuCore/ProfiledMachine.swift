import Foundation

final class ProfiledMachine: BaseMachine {
    init(model: MachineModel) {
        super.init(descriptor: MachineCatalog.descriptor(for: model))
    }
}
