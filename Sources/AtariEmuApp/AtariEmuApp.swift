import AtariEmuCore
import SwiftUI

@main
struct AtariEmuApp: App {
    @State private var viewModel = EmulatorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 980, minHeight: 620)
        }
        .windowStyle(.automatic)
        .commands {
            PresetMenuCommands(viewModel: viewModel)
        }
    }
}
