import Foundation // swiftlint:disable:this file_name
import SourceKittenFramework

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if os(Windows)
import func WinSDK.Sleep
#endif

internal extension Configuration.FileGraph.FilePath {
    // MARK: - Properties: Remote Cache
    /// This should never be touched.
    private static let swiftlintPath = ".swiftlint"

    /// This should never be touched. Change the version number for changes to the cache format
    private static let remoteCachePath = "\(swiftlintPath)/RemoteConfigCache"

    /// If the format of the caching is changed in the future, change this version number
    private static let remoteCacheVersionNumber = "v1"

    /// Use this to get the path to the cache directory for the current cache format
    private static let versionedRemoteCachePath = "\(remoteCachePath)/\(remoteCacheVersionNumber)"

    /// The path to the gitignore file.
    private static let gitignorePath = ".gitignore"

    /// This dictionary has URLs as its keys and contents of those URLs as its values
    /// In production mode, this should be empty. For tests, it may be filled.
    static var mockedNetworkResults: [URL: String] = [:]

    // MARK: - Methods: Resolving
    mutating func resolve(
        remoteConfigTimeout: Double,
        remoteConfigTimeoutIfCached: Double
    ) throws -> URL {
        switch self {
        case let .existing(path):
            return path

        case let .promised(url):
            return try resolve(
                url: url,
                remoteConfigTimeout: remoteConfigTimeout,
                remoteConfigTimeoutIfCached: remoteConfigTimeoutIfCached
            )
        }
    }

    private mutating func resolve(
        url: URL,
        remoteConfigTimeout: Double,
        remoteConfigTimeoutIfCached: Double
    ) throws -> URL {
        // Always use top level as root directory for remote files
        let rootDirectory = URL.currentDirectory()

        // Get cache path
        let cachedFilePath = getCachedFilePath(url: url, rootDirectory: rootDirectory)

        let configString: String
        if let mockedValue = Configuration.FileGraph.FilePath.mockedNetworkResults[url] {
            configString = mockedValue
        } else {
            // Load from url
            var taskResult: (Data?, URLResponse?, (any Error)?)
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
#if os(Windows)
                Sleep(50)
#else
                usleep(50_000) // Sleep for 50 ms
#endif
            }

            // Handle wrong data
            guard
                taskResult.2 == nil, // No error
                (taskResult.1 as? HTTPURLResponse)?.statusCode == 200,
                let configStr = (taskResult.0.flatMap { String(data: $0, encoding: .utf8) })
            else {
                return try handleWrongData(
                    url: url,
                    cachedFilePath: cachedFilePath,
                    taskDone: taskDone,
                    timeout: timeout
                )
            }

            configString = configStr
        }

        // Handle file write failure
        guard let filePath = cache(configString: configString, from: url, rootDirectory: rootDirectory) else {
            return try handleFileWriteFailure(url: url, cachedFilePath: cachedFilePath)
        }

        // Handle success
        self = .existing(path: filePath)
        return filePath
    }

    private mutating func handleWrongData(
        url: URL,
        cachedFilePath: URL?,
        taskDone: Bool,
        timeout: TimeInterval
    ) throws -> URL {
        if let cachedFilePath {
            if taskDone {
                queuedPrintError(
                    """
                    warning: Unable to load remote config from '\(url.filepath)'. Using cached version as a fallback.
                    """
                )
            } else {
                queuedPrintError(
                    """
                    warning: Timeout (\(timeout) sec): Unable to load remote config from '\(url.filepath)'. \
                    Using cached version as a fallback.
                    """
                )
            }

            self = .existing(path: cachedFilePath)
            return cachedFilePath
        }
        if taskDone {
            throw Issue.genericWarning(
                "Unable to load remote config from '\(url.filepath)'. "
                    + "Also didn't found cached version to fallback to."
            )
        }
        throw Issue.genericWarning(
            "Timeout (\(timeout) sec): Unable to load remote config from '\(url.filepath)'. "
                + "Also didn't found cached version to fallback to."
        )
    }

    private mutating func handleFileWriteFailure(url: URL, cachedFilePath: URL?) throws -> URL {
        if let cachedFilePath {
            queuedPrintError(
                "warning: Unable to cache remote config from \"\(url.filepath)\". Using cached version as a fallback."
            )
            self = .existing(path: cachedFilePath)
            return cachedFilePath
        }
        throw Issue.genericWarning(
            "Unable to cache remote config from \"\(url.filepath)\". Also cannot find cached version to fallback to."
        )
    }

    // MARK: Caching
    private func getCachedFilePath(url: URL, rootDirectory: URL) -> URL? {
        let path = filePath(for: url, rootDirectory: rootDirectory)
        return path.exists ? path : nil
    }

    private func cache(configString: String, from url: URL, rootDirectory: URL) -> URL? {
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
            + "# Automatically downloaded from \(url.filepath) by SwiftLint on \(formatter.string(from: Date())).\n"
            + "#\n"
            + configString

        // Create file
        let path = filePath(for: url, rootDirectory: rootDirectory)
        return FileManager.default.createFile(
            atPath: path.filepath,
            contents: Data(configString.utf8),
            attributes: [:]
        ) ? path : nil
    }

    private func filePath(for url: URL, rootDirectory: URL) -> URL {
        let invalidCharacters = [":", "<", ">", "\"", "/", "\\", "|", "?", "*"]
        var adjustedUrlString = url.filepath
        for char in invalidCharacters {
            adjustedUrlString = adjustedUrlString.replacingOccurrences(of: char, with: "_")
        }
        adjustedUrlString = adjustedUrlString.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        let path = Configuration.FileGraph.FilePath.versionedRemoteCachePath + "/\(adjustedUrlString).yml"
        return URL(fileURLWithPath: path, relativeTo: rootDirectory)
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

    private func maintainRemoteConfigCache(rootDirectory: URL) throws {
        // Create directory if needed
        let directory = URL(
            filePath: Configuration.FileGraph.FilePath.versionedRemoteCachePath,
            relativeTo: rootDirectory
        )
        if !directory.exists {
            try FileManager.default.createDirectory(atPath: directory.filepath, withIntermediateDirectories: true)
        }

        // Delete all cache folders except for the current version's folder
        let directoryWithoutVersionNum = directory.deletingLastPathComponent()
        try (try FileManager.default.subpathsOfDirectory(atPath: directoryWithoutVersionNum.filepath)).forEach {
            if !$0.contains("/"), $0 != Configuration.FileGraph.FilePath.remoteCacheVersionNumber {
                try FileManager.default.removeItem(
                    atPath: URL(filePath: $0, relativeTo: directoryWithoutVersionNum).filepath
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
                throw Issue.genericWarning("Issue maintaining remote config cache.")
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
