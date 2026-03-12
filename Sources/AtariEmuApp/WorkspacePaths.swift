import Foundation

enum WorkspacePaths {
    static func repositoryRoot(fileManager: FileManager = .default) -> URL? {
        let environment = ProcessInfo.processInfo.environment
        var candidates: [URL] = []

        if let override = environment["ATARIEMU_WORKSPACE_ROOT"], !override.isEmpty {
            candidates.append(URL(fileURLWithPath: override))
        }

        candidates.append(URL(fileURLWithPath: fileManager.currentDirectoryPath))

        if let executableURL = Bundle.main.executableURL {
            candidates.append(executableURL.deletingLastPathComponent())
        }

        candidates.append(Bundle.main.bundleURL)

        if let resourceURL = Bundle.main.resourceURL {
            candidates.append(resourceURL)
        }

        for candidate in unique(candidates) {
            if let root = ascendToRepositoryRoot(from: candidate, fileManager: fileManager) {
                return root
            }
        }

        return nil
    }

    static func userMediaRoots(fileManager: FileManager = .default) -> [URL] {
        let environment = ProcessInfo.processInfo.environment
        var roots: [URL] = []

        if let override = environment["ATARIEMU_USERMEDIA"], !override.isEmpty {
            roots.append(URL(fileURLWithPath: override))
        }

        if let repositoryRoot = repositoryRoot(fileManager: fileManager) {
            roots.append(repositoryRoot.appendingPathComponent("UserMedia", isDirectory: true))
            roots.append(repositoryRoot.appendingPathComponent("dist/UserMedia", isDirectory: true))
        }

        roots.append(URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent("UserMedia", isDirectory: true))
        roots.append(Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("UserMedia", isDirectory: true))

        if let resourceURL = Bundle.main.resourceURL {
            roots.append(resourceURL.appendingPathComponent("UserMedia", isDirectory: true))
        }

        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            roots.append(documentsDirectory.appendingPathComponent("AtariEmu/UserMedia", isDirectory: true))
        }

        if let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            roots.append(applicationSupportDirectory.appendingPathComponent("AtariEmu/UserMedia", isDirectory: true))
        }

        return unique(roots)
    }

    static func runtimeRoot(fileManager: FileManager = .default) -> URL {
        let root: URL

        if let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            root = applicationSupportDirectory.appendingPathComponent("AtariEmu/Runtime", isDirectory: true)
        } else if let repositoryRoot = repositoryRoot(fileManager: fileManager) {
            root = repositoryRoot.appendingPathComponent("Runtime", isDirectory: true)
        } else {
            root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AtariEmu/Runtime", isDirectory: true)
        }

        try? fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    static func writableUserMediaRoot(fileManager: FileManager = .default) -> URL {
        let environment = ProcessInfo.processInfo.environment
        let root: URL

        if let override = environment["ATARIEMU_USERMEDIA"], !override.isEmpty {
            root = URL(fileURLWithPath: override)
        } else if let repositoryRoot = repositoryRoot(fileManager: fileManager) {
            root = repositoryRoot.appendingPathComponent("UserMedia", isDirectory: true)
        } else if let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            root = applicationSupportDirectory.appendingPathComponent("AtariEmu/UserMedia", isDirectory: true)
        } else {
            root = URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent("UserMedia", isDirectory: true)
        }

        try? fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private static func ascendToRepositoryRoot(from candidate: URL, fileManager: FileManager) -> URL? {
        var currentURL = candidate.standardizedFileURL

        while true {
            if isRepositoryRoot(currentURL, fileManager: fileManager) {
                return currentURL
            }

            let parentURL = currentURL.deletingLastPathComponent()
            if parentURL.path == currentURL.path {
                return nil
            }
            currentURL = parentURL
        }
    }

    private static func isRepositoryRoot(_ url: URL, fileManager: FileManager) -> Bool {
        let packagePath = url.appendingPathComponent("Package.swift").path
        let sourcesPath = url.appendingPathComponent("Sources").path
        let thirdPartyPath = url.appendingPathComponent("third_party").path

        return fileManager.fileExists(atPath: packagePath)
            || (fileManager.fileExists(atPath: sourcesPath) && fileManager.fileExists(atPath: thirdPartyPath))
    }

    private static func unique(_ urls: [URL]) -> [URL] {
        var seen = Set<String>()
        var result: [URL] = []

        for url in urls {
            let key = url.standardizedFileURL.path
            if seen.insert(key).inserted {
                result.append(url)
            }
        }

        return result
    }
}
