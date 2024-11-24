import PackagePlugin

protocol CommandContext {
    var tool: String { get throws }

    var cacheDirectory: String { get }

    var workingDirectory: String { get }

    var unitName: String { get }

    var subUnitName: String { get }

    func targets(named names: [String]) throws -> [(path: String, name: String)]
}

extension PluginContext: CommandContext {
    var tool: String {
        get throws {
            try tool(named: "swiftlint").path.string
        }
    }

    var cacheDirectory: String {
        pluginWorkDirectory.string
    }

    var workingDirectory: String {
        package.directory.string
    }

    var unitName: String {
        "package"
    }

    var subUnitName: String {
        "module"
    }

    func targets(named names: [String]) throws -> [(path: String, name: String)] {
        let targets = names.isEmpty
            ? package.targets
            : try package.targets(named: names)
        return targets.compactMap { target in
            guard let target = target.sourceModule else {
                Diagnostics.warning("Target '\(target.name)' is not a source module; skipping it")
                return nil
            }
            return (path: target.directory.string, name: target.name)
        }
    }
}

#if canImport(XcodeProjectPlugin)

import XcodeProjectPlugin

extension XcodePluginContext: CommandContext {
    var tool: String {
        get throws {
            try tool(named: "swiftlint").path.string
        }
    }

    var cacheDirectory: String {
        pluginWorkDirectory.string
    }

    var workingDirectory: String {
        xcodeProject.directory.string
    }

    var unitName: String {
        "project"
    }

    var subUnitName: String {
        "target"
    }

    func targets(named _: [String]) throws -> [(path: String, name: String)] {
        []
    }
}

#endif
