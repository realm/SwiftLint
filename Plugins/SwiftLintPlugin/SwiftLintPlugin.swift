import Foundation
import PackagePlugin

@main
struct SwiftLintPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }
        return try createBuildCommands(
            inputFiles: sourceTarget.sourceFiles(withSuffix: "swift").map(\.path),
            packageDirectory: context.package.directory,
            workingDirectory: context.pluginWorkDirectory,
            tool: try context.tool(named: "swiftlint")
        )
    }

    private func createBuildCommands(inputFiles: [Path],
                                     packageDirectory: Path,
                                     workingDirectory: Path,
                                     tool: PluginContext.Tool,
                                     preventInputFileConsumption: Bool = false
    ) throws -> [Command] {
        if inputFiles.isEmpty {
            // Don't lint anything if there are no Swift source files in this target
            return []
        }

        var arguments = [
            "lint",
            "--quiet",
            "--cache-path", "\(workingDirectory)"
        ]

        // Manually look for configuration files, to avoid issues when the plugin does not execute our tool from the
        // package source directory.
        if let configuration = packageDirectory.firstConfigurationFileInParentDirectories() {
            arguments.append(contentsOf: ["--config", "\(configuration.string)"])
        }
        arguments += inputFiles.map(\.string)

        let buildCommandInputFiles: [Path]
        if preventInputFileConsumption {
            // This is a workaround for an issue that affects Xcode targets under Xcode 14.x (FB11835329, FB11877146):
            // If a build tool plugin is applied to an Xcode target and lists `.swift` source files as inputs of
            // the build commands it generates, then those `.swift` source files aren't seen by Xcode's build
            // system (as they've been "consumed" by the plugin command).
            //
            // The workaround creates a new symbolic link to the project directory within the build plugin's working 
            // directory, then references every input file via that symbolically linked directory as the input files
            // for the build command. This prevents Xcode "consuming" the input files, and allows further processing 
            // such as compilation.
            let xcodeProjDirSymlink = workingDirectory.appending("ProjectDir")
            try? FileManager.default.removeItem(atPath: xcodeProjDirSymlink.string)
            try FileManager.default.createSymbolicLink(
                atPath: xcodeProjDirSymlink.string,
                withDestinationPath: packageDirectory.string
            )

            buildCommandInputFiles = inputFiles.map { inputFile in
                let relativePath = inputFile.relative(to: packageDirectory)
                return xcodeProjDirSymlink.appending(subpath: relativePath.string)
            }
        } else {
            buildCommandInputFiles = inputFiles
        }

        let nonExistentOutputDirectory = workingDirectory.appending(UUID().uuidString)
        try FileManager.default.createDirectory(atPath: nonExistentOutputDirectory.string, withIntermediateDirectories: false)

        return [
            .buildCommand(
                displayName: "SwiftLint",
                executable: tool.path,
                arguments: arguments,
                inputFiles: buildCommandInputFiles,
                outputFiles: [nonExistentOutputDirectory]
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftLintPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let inputFilePaths = target.inputFiles
            .filter { $0.type == .source && $0.path.extension == "swift" }
            .map(\.path)

        return try createBuildCommands(
            inputFiles: inputFilePaths,
            packageDirectory: context.xcodeProject.directory,
            workingDirectory: context.pluginWorkDirectory,
            tool: try context.tool(named: "swiftlint"),
            preventInputFileConsumption: true
        )
    }
}
#endif
