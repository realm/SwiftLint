import Foundation

private struct ExportedImportsCacheKey: Hashable {
    let module: String
    let compilerArguments: [String]
}

final class ExportedImportsResolver: @unchecked Sendable {
    typealias DigesterRunner = @Sendable ([String]) -> Data?

    private let lock = NSLock()
    private var cache = [ExportedImportsCacheKey: Set<String>]()
    private let runDigester: DigesterRunner

    init() {
        runDigester = { arguments in
            Self.runDigester(arguments: arguments)
        }
    }

    init(runDigester: @escaping DigesterRunner) {
        self.runDigester = runDigester
    }

    func exportedImports(
        for modules: Set<String>,
        compilerArguments: [String]
    ) -> [String: Set<String>] {
        guard modules.isNotEmpty else {
            return [:]
        }

        let digesterArguments = compilerArgumentsForAPIDigester(
            compilerArguments
        )

        // Keep lookup and loading in one critical section. This prevents
        // parallel file analysis from launching duplicate digester processes
        // for the same modules and compiler context.
        lock.lock()
        defer {
            lock.unlock()
        }

        var result = [String: Set<String>]()
        var missingModules = Set<String>()

        for module in modules {
            let key = cacheKey(
                module: module,
                compilerArguments: digesterArguments
            )

            if let cached = cache[key] {
                result[module] = cached
            } else {
                missingModules.insert(module)
            }
        }

        guard missingModules.isNotEmpty else {
            return result
        }

        // A failed lookup is deliberately not cached, so a transient
        // toolchain or module-loading failure can be retried later.
        guard let loaded = loadExportedImports(
            for: missingModules,
            compilerArguments: digesterArguments
        ) else {
            return result
        }

        for module in missingModules {
            let exportedImports = loaded[module] ?? []
            let key = cacheKey(
                module: module,
                compilerArguments: digesterArguments
            )

            cache[key] = exportedImports
            result[module] = exportedImports
        }

        return result
    }

    private func cacheKey(
        module: String,
        compilerArguments: [String]
    ) -> ExportedImportsCacheKey {
        ExportedImportsCacheKey(
            module: module,
            compilerArguments: compilerArguments
        )
    }

    private func loadExportedImports(
        for modules: Set<String>,
        compilerArguments: [String]
    ) -> [String: Set<String>]? {
        let arguments = digesterArguments(
            modules: modules,
            compilerArguments: compilerArguments
        )

        guard let data = runDigester(arguments) else {
            return nil
        }

        return parseExportedImports(
            from: data,
            modules: modules
        )
    }

    private static func runDigester(
        arguments: [String]
    ) -> Data? {
        let process = makeProcess()
        let output = Pipe()

        process.arguments?.append(contentsOf: arguments)
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return nil
        }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            return nil
        }

        return data
    }

    private static func makeProcess() -> Process {
        let process = Process()

#if os(macOS)
        process.executableURL = URL(
            fileURLWithPath: "/usr/bin/xcrun"
        )
        process.arguments = ["swift-api-digester"]
#elseif os(Windows)
        let command = ProcessInfo.processInfo.environment["COMSPEC"]
            ?? "C:\\Windows\\System32\\cmd.exe"

        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = ["/C", "swift-api-digester"]
#else
        process.executableURL = URL(
            fileURLWithPath: "/usr/bin/env"
        )
        process.arguments = ["swift-api-digester"]
#endif

        return process
    }

    private func digesterArguments(
        modules: Set<String>,
        compilerArguments: [String]
    ) -> [String] {
        var arguments = [
            "-dump-sdk",
            "-abort-on-module-fail",
            "-avoid-location",
            "-avoid-tool-args",
            "-o",
            "-",
        ]

        for module in modules.sorted() {
            arguments.append(contentsOf: ["-module", module])
        }

        arguments.append(contentsOf: compilerArguments)
        return arguments
    }

    private func parseExportedImports(
        from data: Data,
        modules: Set<String>
    ) -> [String: Set<String>]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }

        var result = Dictionary(
            uniqueKeysWithValues: modules.map { ($0, Set<String>()) }
        )

        collectExportedImports(
            from: json,
            modules: modules,
            into: &result
        )

        return result
    }

    private func collectExportedImports(
        from value: Any,
        modules: Set<String>,
        into result: inout [String: Set<String>]
    ) {
        if let dictionary = value as? [String: Any] {
            if let exportedImport = exportedImport(
                from: dictionary,
                modules: modules
            ) {
                result[exportedImport.owner, default: []]
                    .insert(exportedImport.importedModule)
            }

            for child in dictionary.values {
                collectExportedImports(
                    from: child,
                    modules: modules,
                    into: &result
                )
            }

            return
        }

        guard let array = value as? [Any] else {
            return
        }

        for child in array {
            collectExportedImports(
                from: child,
                modules: modules,
                into: &result
            )
        }
    }

    private func exportedImport(
        from dictionary: [String: Any],
        modules: Set<String>
    ) -> (owner: String, importedModule: String)? {
        guard dictionary["kind"] as? String == "Import",
              let owner = dictionary["moduleName"] as? String,
              modules.contains(owner),
              let attributes = dictionary["declAttributes"] as? [String],
              attributes.contains("Exported"),
              let importedModule = dictionary["name"] as? String,
              let rootModule = importedModule.split(separator: ".").first else {
            return nil
        }

        return (
            owner: owner,
            importedModule: String(rootModule)
        )
    }
}
