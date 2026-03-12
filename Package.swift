// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AtariEmu",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AtariEmuCore",
            targets: ["AtariEmuCore"]
        ),
        .executable(
            name: "AtariEmuApp",
            targets: ["AtariEmuApp"]
        )
    ],
    targets: [
        .target(
            name: "AtariEmuCore"
        ),
        .executableTarget(
            name: "AtariEmuApp",
            dependencies: ["AtariEmuCore"]
        ),
        .testTarget(
            name: "AtariEmuCoreTests",
            dependencies: ["AtariEmuCore"]
        )
    ]
)
