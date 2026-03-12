import AtariEmuCore
import SwiftUI

struct PresetMenuCommands: Commands {
    let viewModel: EmulatorViewModel

    var body: some Commands {
        CommandMenu("Presets") {
            Button("Rescan Media Library") {
                viewModel.refreshLibrary()
            }

            Divider()

            ForEach(MachineModel.allCases) { model in
                let presets = SoftwarePresetCatalog.presets(for: model)
                if !presets.isEmpty {
                    Menu(model.displayName) {
                        ForEach(presets) { preset in
                            let plan = viewModel.mediaLibrary.launchPlan(
                                for: preset,
                                descriptor: MachineCatalog.descriptor(for: model)
                            )
                            Button(preset.name) {
                                viewModel.launchPreset(preset)
                            }
                            .disabled(!plan.isReady)
                        }
                    }
                }
            }
        }
    }
}
