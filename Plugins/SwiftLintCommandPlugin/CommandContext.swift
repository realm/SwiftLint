import Foundation
import PackagePlugin

protocol CommandContext {
    var tool: URL { get throws }

    var cacheDirectory: URL { get }

    var workingDirectory: URL { get }

    var unitName: String { get }

    var subUnitName: String { get }

    func targets(named names: [String]) throws -> [(paths: [URL], name: String)]
}

extension PluginContext: CommandContext {
    var tool: URL {
        get throws {
            try tool(named: "swiftlint").url
        }
    }

    var cacheDirectory: URL {
        pluginWorkDirectoryURL
    }

    var workingDirectory: URL {
        package.directoryURL
    }

    var unitName: String {
        "package"
    }

    var subUnitName: String {
        "module"
    }

    func targets(named names: [String]) throws -> [(paths: [URL], name: String)] {
        let targets = names.isEmpty
            ? package.targets
            : try package.targets(named: names)
        return targets.compactMap { target -> (paths: [URL], name: String)? in
            guard let target = target.sourceModule else {
                Diagnostics.warning("Target '\(target.name)' is not a source module; skipping it")
                return nil
            }
            // Packages have a 1-to-1 mapping between targets and directories.
            return (paths: [target.directoryURL], name: target.name)
        }
    }
}

#if canImport(XcodeProjectPlugin)

import XcodeProjectPlugin

extension XcodePluginContext: CommandContext {
    var tool: URL {
        get throws {
            try tool(named: "swiftlint").url
        }
    }

    var cacheDirectory: URL {
        pluginWorkDirectoryURL
    }

    var workingDirectory: URL {
        xcodeProject.directoryURL
    }

    var unitName: String {
        "project"
    }

    var subUnitName: String {
        "target"
    }

    func targets(named names: [String]) -> [(paths: [URL], name: String)] {
        if names.isEmpty {
            return [(paths: [xcodeProject.directoryURL], name: xcodeProject.displayName)]
        }
        return xcodeProject.targets
            .filter { names.contains($0.displayName) }
            .map { (paths: $0.inputFiles.map(\.url).filter { $0.pathExtension == "swift" }, name: $0.displayName) }
    }
}

#endif
