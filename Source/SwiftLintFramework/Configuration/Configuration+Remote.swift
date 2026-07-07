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
    @TaskLocal static var mockedNetworkResults = [String: String]()

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
        // Get cache path
        let cachedFilePath = getCachedFilePath(urlString: urlString, rootDirectory: URL.cwd)

        let configString: String
        if let mockedValue = Self.mockedNetworkResults[urlString] {
            configString = mockedValue
        } else {
            // Handle wrong url format
            guard let url = URL(string: urlString) else {
                throw Issue.genericWarning("Invalid configuration entry: \"\(urlString)\" isn't a valid url.")
            }

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
                    urlString: urlString,
                    cachedFilePath: cachedFilePath,
                    taskDone: taskDone,
                    timeout: timeout
                )
            }

            configString = configStr
        }

        // Handle file write failure
        guard let filePath = cache(configString: configString, from: urlString, rootDirectory: URL.cwd) else {
            return try handleFileWriteFailure(urlString: urlString, cachedFilePath: cachedFilePath)
        }

        // Handle success
        self = .existing(path: filePath.filepath)
        return filePath.filepath
    }

    private mutating func handleWrongData(
        urlString: String,
        cachedFilePath: URL?,
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

            self = .existing(path: cachedFilePath.filepath)
            return cachedFilePath.filepath
        }
        if taskDone {
            throw Issue.genericWarning(
                "Unable to load remote config from \"\(urlString)\". "
                    + "Also didn't found cached version to fallback to."
            )
        }
        throw Issue.genericWarning(
            "Timeout (\(timeout) sec): Unable to load remote config from \"\(urlString)\". "
                + "Also didn't found cached version to fallback to."
        )
    }

    private mutating func handleFileWriteFailure(urlString: String, cachedFilePath: URL?) throws -> String {
        if let cachedFilePath {
            queuedPrintError(
                "warning: Unable to cache remote config from \"\(urlString)\". Using cached version as a fallback."
            )
            self = .existing(path: cachedFilePath.filepath)
            return cachedFilePath.filepath
        }
        throw Issue.genericWarning(
            "Unable to cache remote config from \"\(urlString)\". Also didn't found cached version to fallback to."
        )
    }

    // MARK: Caching
    private func getCachedFilePath(urlString: String, rootDirectory: URL) -> URL? {
        let path = filePath(for: urlString, rootDirectory: rootDirectory)
        return path.exists ? path : nil
    }

    private func cache(configString: String, from urlString: String, rootDirectory: URL) -> URL? {
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
        do {
            try configString.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            queuedPrintError("Failed cache for for remote configuration at path '\(path)'")
            return nil
        }
    }

    private func filePath(for urlString: String, rootDirectory: URL) -> URL {
        let invalidCharacters = [":", "<", ">", "\"", "/", "\\", "|", "?", "*"]
        var adjustedUrlString = urlString
        for char in invalidCharacters {
            adjustedUrlString = adjustedUrlString.replacingOccurrences(of: char, with: "_")
        }
        adjustedUrlString = adjustedUrlString.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return rootDirectory
            .appending(path: Self.versionedRemoteCachePath, directoryHint: .isDirectory)
            .appending(path: adjustedUrlString + ".yml")
    }

    private func maintainRemoteConfigCache(rootDirectory: URL) throws {
        // Create directory if needed
        let directory = rootDirectory.appending(path: Self.versionedRemoteCachePath, directoryHint: .isDirectory)
        if !directory.exists {
            try FileManager.default.createDirectory(atPath: directory.filepath, withIntermediateDirectories: true)
        }

        // Delete all cache folders except for the current version's folder
        let directoryWithoutVersionNum = directory.deletingLastPathComponent()
        try (try FileManager.default.subpathsOfDirectory(atPath: directoryWithoutVersionNum.filepath)).forEach {
            if !$0.contains("/"), $0 != Self.remoteCacheVersionNumber {
                try FileManager.default.removeItem(
                    atPath: directoryWithoutVersionNum.appending(path: $0, directoryHint: .isDirectory).filepath
                )
            }
        }

        // Add gitignore entry if needed
        let requiredGitignoreAppendix = "\(Self.remoteCachePath)"
        let newGitignoreAppendix = "# SwiftLint Remote Config Cache\n\(requiredGitignoreAppendix)"
        let gitignoreFile = rootDirectory.appending(path: Self.gitignorePath, directoryHint: .notDirectory)

        if gitignoreFile.exists {
            var contents = try String(contentsOf: gitignoreFile, encoding: .utf8)
            if !contents.contains(requiredGitignoreAppendix) {
                contents += "\n\n\(newGitignoreAppendix)"
                try contents.write(to: gitignoreFile, atomically: true, encoding: .utf8)
            }
        } else {
            try newGitignoreAppendix.write(to: gitignoreFile, atomically: true, encoding: .utf8)
        }
    }
}
