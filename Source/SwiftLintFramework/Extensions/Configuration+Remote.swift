import Foundation // swiftlint:disable:this file_name

public extension Configuration.FileGraph.FilePath {
    // MARK: Resolving
    mutating func resolve(
        remoteConfigLoadingTimeout: Double,
        remoteConfigLoadingTimeoutIfCached: Double,
        rootDirectory: String
    ) throws -> String {
        switch self {
        case let .existing(path):
            return resolve(existingPath: path, rootDirectory: rootDirectory)

        case let .promised(urlString):
            return try resolve(
                urlString: urlString,
                rootDirectory: rootDirectory,
                remoteConfigLoadingTimeout: remoteConfigLoadingTimeout,
                remoteConfigLoadingTimeoutIfCached: remoteConfigLoadingTimeoutIfCached
            )
        }
    }

    private func resolve(existingPath path: String, rootDirectory: String) -> String {
        return path.bridge().absolutePathRepresentation(rootDirectory: rootDirectory)
    }

    private mutating func resolve(
        urlString: String,
        rootDirectory: String,
        remoteConfigLoadingTimeout: Double,
        remoteConfigLoadingTimeoutIfCached: Double
    ) throws -> String {
        let cachedFilePath = getCachedFilePath(urlString: urlString, rootDirectory: rootDirectory)

        // Handle missing network
        guard Reachability.isConnectedToNetwork() else {
            return try handleMissingNetwork(urlString: urlString, cachedFilePath: cachedFilePath)
        }

        // Handle wrong url fromat
        guard let url = URL(string: urlString) else {
            throw ConfigurationError.generic("Invalid configuration entry: \"\(urlString)\" isn't a valid url.")
        }

        // Load from url
        var taskResult: (Data?, URLResponse?, Error?)
        var taskDone: Bool = false
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            taskResult = (data, response, error)
            taskDone = true
        }

        task.resume()

        let timeout = cachedFilePath == nil ? remoteConfigLoadingTimeout : remoteConfigLoadingTimeoutIfCached
        let time = CFAbsoluteTimeGetCurrent()

        // Block main thread until timeout is reached / task is done
        while true {
            if taskDone { break }
            if CFAbsoluteTimeGetCurrent() - time > timeout { task.cancel(); break }
            usleep(50_000) // Sleep for 50 ms
        }

        // Handle wrong data
        guard
            taskResult.2 == nil, // No error
            (taskResult.1 as? HTTPURLResponse)?.statusCode == 200,
            let configString = (taskResult.0.flatMap { String(data: $0, encoding: .utf8) })
        else {
            return try handleWrongData(urlString: urlString, cachedFilePath: cachedFilePath, taskDone: taskDone)
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
        if let cachedFilePath = cachedFilePath {
            queuedPrint(
                "No internet connectivity: Unable to load remote config from \"\(urlString)\". "
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

    private mutating func handleWrongData(urlString: String, cachedFilePath: String?, taskDone: Bool) throws -> String {
        if let cachedFilePath = cachedFilePath {
            if taskDone {
                queuedPrint("Unable to load remote config from \"\(urlString)\". Using cached version as a fallback.")
            } else {
                queuedPrint(
                    "Timeout: Unable to load remote config from \"\(urlString)\". Using cached version as a fallback."
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
                    "Timeout: Unable to load remote config from \"\(urlString)\". "
                        + "Also didn't found cached version to fallback to."
                )
            }
        }
    }

    private mutating func handleFileWriteFailure(urlString: String, cachedFilePath: String?) throws -> String {
        if let cachedFilePath = cachedFilePath {
            queuedPrint("Unable to cache remote config from \"\(urlString)\". Using cached version as a fallback.")
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
        return FileManager.default.fileExists(atPath: path) ? path: nil
    }

    private func cache(configString: String, from urlString: String, rootDirectory: String) -> String? {
        // Add comment line at the top of the config string
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy 'at' HH:mm:ss"
        let configString =
            "# Automatically downloaded from \"\(urlString)\" by SwiftLint on \(formatter.string(from: Date())).\n"
            + configString

        // Get path
        let path = filePath(for: urlString, rootDirectory: rootDirectory)

        // Create directory if needed
        let directory = path.components(separatedBy: "/").dropLast().joined(separator: "/")
        if !FileManager.default.fileExists(atPath: directory) {
            do {
                try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            } catch {
                return nil
            }
        }

        // Create file
        return FileManager.default.createFile(
            atPath: path,
            contents: Data(configString.utf8),
            attributes: [:]
        ) ? path: nil
    }

    private func filePath(for urlString: String, rootDirectory: String) -> String {
        let adjustUrlString = urlString
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ".", with: "+")

        // If this string or caching is changed in the future,
        // update the version in the string and delete caches from the previous versions
        let versionNum = "v1"
        let path = "/.swiftlint/RemoteConfigCache/swiftlint_cache_\(versionNum)_\(adjustUrlString).yml"

        return path.bridge().absolutePathRepresentation(rootDirectory: rootDirectory)
    }
}
