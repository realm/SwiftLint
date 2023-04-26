import Foundation // swiftlint:disable:this file_name

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

internal extension Configuration.FileGraph.FilePath {
    // MARK: - Properties: Remote Cache
    /// This should never be touched.
    private static let swiftlintPath: String = ".swiftlint"

    /// This should never be touched. Change the version number for changes to the cache format
    private static let remoteCachePath: String = "\(swiftlintPath)/RemoteConfigCache"

    /// If the format of the caching is changed in the future, change this version number
    private static let remoteCacheVersionNumber: String = "v1"

    /// Use this to get the path to the cache directory for the current cache format
    private static let versionedRemoteCachePath: String = "\(remoteCachePath)/\(remoteCacheVersionNumber)"

    /// The path to the gitignore file.
    private static let gitignorePath: String = ".gitignore"

    /// This dictionary has URLs as its keys and contents of those URLs as its values
    /// In production mode, this should be empty. For tests, it may be filled.
    static var mockedNetworkResults: [String: String] = [:]

    // MARK: - Methods: Resolving
    mutating func resolve(
        remoteConfigTimeout: Double,
        remoteConfigTimeoutIfCached: Double
    ) throws -> String {
        switch self {
        case let .existing(path):
            return path

        case let .promised(urlString):
            return try resolve(
                urlString: urlString,
                remoteConfigTimeout: remoteConfigTimeout,
                remoteConfigTimeoutIfCached: remoteConfigTimeoutIfCached
            )
        }
    }

    private mutating func resolve(
        urlString: String,
        remoteConfigTimeout: Double,
        remoteConfigTimeoutIfCached: Double
    ) throws -> String {
        // Always use top level as root directory for remote files
        let rootDirectory = FileManager.default.currentDirectoryPath.bridge().standardizingPath

        // Get cache path
        let cachedFilePath = getCachedFilePath(urlString: urlString, rootDirectory: rootDirectory)

        let configString: String
        if let mockedValue = Configuration.FileGraph.FilePath.mockedNetworkResults[urlString] {
            configString = mockedValue
        } else {
            // Handle missing network
            guard Reachability.connectivityStatus != .disconnected else {
                return try handleMissingNetwork(urlString: urlString, cachedFilePath: cachedFilePath)
            }

            // Handle wrong url format
            guard let url = URL(string: urlString) else {
                throw ConfigurationError.generic("Invalid configuration entry: \"\(urlString)\" isn't a valid url.")
            }

            // Load from url
            var taskResult: (Data?, URLResponse?, Error?)
            var taskDone = false

            // `.ephemeral` disables caching (which we don't want to be managed by the system)
            let task = URLSession(configuration: .ephemeral).dataTask(with: url) { data, response, error in
                taskResult = (data, response, error)
                taskDone = true
            }

            task.resume()

            let timeout = cachedFilePath == nil ? remoteConfigTimeout : remoteConfigTimeoutIfCached
            let startDate = Date()

            // Block main thread until timeout is reached / task is done
            while true {
                if taskDone { break }
                if Date().timeIntervalSince(startDate) > timeout { task.cancel(); break }
                usleep(50_000) // Sleep for 50 ms
            }

            // Handle wrong data
            guard
                taskResult.2 == nil, // No error
                (taskResult.1 as? HTTPURLResponse)?.statusCode == 200,
                let configStr = (taskResult.0.flatMap { String(data: $0, encoding: .utf8) })
            else {
                return try handleWrongData(
                    urlString: urlString,
                    cachedFilePath: cachedFilePath,
                    taskDone: taskDone,
                    timeout: timeout
                )
            }

            configString = configStr
        }

        // Handle file write failure
        guard let filePath = cache(configString: configString, from: urlString, rootDirectory: rootDirectory) else {
            return try handleFileWriteFailure(urlString: urlString, cachedFilePath: cachedFilePath)
        }

        // Handle success
        self = .existing(path: filePath)
        return filePath
    }

    private mutating func handleMissingNetwork(urlString: String, cachedFilePath: String?) throws -> String {
        if let cachedFilePath {
            queuedPrintError(
                "warning: No internet connectivity: Unable to load remote config from \"\(urlString)\". "
                    + "Using cached version as a fallback."
            )
            self = .existing(path: cachedFilePath)
            return cachedFilePath
        } else {
            throw ConfigurationError.generic(
                "No internet connectivity: Unable to load remote config from \"\(urlString)\". "
                    + "Also didn't found cached version to fallback to."
            )
        }
    }

    private mutating func handleWrongData(
        urlString: String,
        cachedFilePath: String?,
        taskDone: Bool,
        timeout: TimeInterval
    ) throws -> String {
        if let cachedFilePath {
            if taskDone {
                queuedPrintError(
                    "warning: Unable to load remote config from \"\(urlString)\". Using cached version as a fallback."
                )
            } else {
                queuedPrintError(
                    "warning: Timeout (\(timeout) sec): Unable to load remote config from \"\(urlString)\". "
                        + "Using cached version as a fallback."
                )
            }

            self = .existing(path: cachedFilePath)
            return cachedFilePath
        } else {
            if taskDone {
                throw ConfigurationError.generic(
                    "Unable to load remote config from \"\(urlString)\". "
                        + "Also didn't found cached version to fallback to."
                )
            } else {
                throw ConfigurationError.generic(
                    "Timeout (\(timeout) sec): Unable to load remote config from \"\(urlString)\". "
                        + "Also didn't found cached version to fallback to."
                )
            }
        }
    }

    private mutating func handleFileWriteFailure(urlString: String, cachedFilePath: String?) throws -> String {
        if let cachedFilePath {
            queuedPrintError("Unable to cache remote config from \"\(urlString)\". Using cached version as a fallback.")
            self = .existing(path: cachedFilePath)
            return cachedFilePath
        } else {
            throw ConfigurationError.generic(
                "Unable to cache remote config from \"\(urlString)\". Also didn't found cached version to fallback to."
            )
        }
    }

    // MARK: Caching
    private func getCachedFilePath(urlString: String, rootDirectory: String) -> String? {
        let path = filePath(for: urlString, rootDirectory: rootDirectory)
        return FileManager.default.fileExists(atPath: path) ? path : nil
    }

    private func cache(configString: String, from urlString: String, rootDirectory: String) -> String? {
        // Do cache maintenance
        do {
            try maintainRemoteConfigCache(rootDirectory: rootDirectory)
        } catch {
            return nil
        }

        // Add comment line at the top of the config string
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy 'at' HH:mm:ss"
        let configString =
            "#\n"
            + "# Automatically downloaded from \(urlString) by SwiftLint on \(formatter.string(from: Date())).\n"
            + "#\n"
            + configString

        // Create file
        let path = filePath(for: urlString, rootDirectory: rootDirectory)
        return FileManager.default.createFile(
            atPath: path,
            contents: Data(configString.utf8),
            attributes: [:]
        ) ? path : nil
    }

    private func filePath(for urlString: String, rootDirectory: String) -> String {
        let adjustedUrlString = urlString.replacingOccurrences(of: "/", with: "_")
        let path = Configuration.FileGraph.FilePath.versionedRemoteCachePath + "/\(adjustedUrlString).yml"
        return path.bridge().absolutePathRepresentation(rootDirectory: rootDirectory)
    }

    /// As a safeguard, this method only works when there are mocked network results.
    /// It deletes both the .gitignore and the remote cache that may have got created by a test.
    static func deleteGitignoreAndSwiftlintCache() {
        guard !mockedNetworkResults.isEmpty else { return }

        try? FileManager.default.removeItem(atPath: gitignorePath)
        try? FileManager.default.removeItem(atPath: remoteCachePath)

        if (try? FileManager.default.contentsOfDirectory(atPath: swiftlintPath))?.isEmpty == true {
            try? FileManager.default.removeItem(atPath: swiftlintPath)
        }
    }

    private func maintainRemoteConfigCache(rootDirectory: String) throws {
        // Create directory if needed
        let directory = Configuration.FileGraph.FilePath.versionedRemoteCachePath
            .bridge().absolutePathRepresentation(rootDirectory: rootDirectory)
        if !FileManager.default.fileExists(atPath: directory) {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }

        // Delete all cache folders except for the current version's folder
        let directoryWithoutVersionNum = directory.components(separatedBy: "/").dropLast().joined(separator: "/")
        try (try FileManager.default.subpathsOfDirectory(atPath: directoryWithoutVersionNum)).forEach {
            if !$0.contains("/") && $0 != Configuration.FileGraph.FilePath.remoteCacheVersionNumber {
                try FileManager.default.removeItem(atPath:
                    $0.bridge().absolutePathRepresentation(rootDirectory: directoryWithoutVersionNum)
                )
            }
        }

        // Add gitignore entry if needed
        let requiredGitignoreAppendix = "\(Configuration.FileGraph.FilePath.remoteCachePath)"
        let newGitignoreAppendix = "# SwiftLint Remote Config Cache\n\(requiredGitignoreAppendix)"

        if !FileManager.default.fileExists(atPath: Configuration.FileGraph.FilePath.gitignorePath) {
            guard FileManager.default.createFile(
                atPath: Configuration.FileGraph.FilePath.gitignorePath,
                contents: Data(newGitignoreAppendix.utf8),
                attributes: [:]
            ) else {
                throw ConfigurationError.generic("Issue maintaining remote config cache.")
            }
        } else {
            var contents = try String(contentsOfFile: Configuration.FileGraph.FilePath.gitignorePath, encoding: .utf8)
            if !contents.contains(requiredGitignoreAppendix) {
                contents += "\n\n\(newGitignoreAppendix)"
                try contents.write(
                    toFile: Configuration.FileGraph.FilePath.gitignorePath,
                    atomically: true,
                    encoding: .utf8
                )
            }
        }
    }
}
