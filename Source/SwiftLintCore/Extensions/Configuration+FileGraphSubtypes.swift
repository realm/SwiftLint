import Foundation // swiftlint:disable:this file_name

internal extension Configuration.FileGraph {
    // MARK: - FilePath
    enum FilePath: Hashable {
        case promised(urlString: String)
        case existing(path: String)
    }

    // MARK: - Vertix
    class Vertix: Hashable {
        internal let originalRemoteString: String?
        internal var originatesFromRemote: Bool { originalRemoteString != nil }
        internal var rootDirectory: String {
            if !originatesFromRemote, case let .existing(path) = filePath {
                // This is a local file, so its root directory is its containing directory
                return path.bridge().deletingLastPathComponent
            } else {
                // This is a remote file, so its root directory is the directory where it was referenced from
                return originalRootDirectory
            }
        }

        private let originalRootDirectory: String
        let isInitialVertix: Bool
        private(set) var filePath: FilePath
        private(set) var configurationDict: [String: Any] = [:]

        init(string: String, rootDirectory: String, isInitialVertix: Bool) {
            originalRootDirectory = rootDirectory
            if string.hasPrefix("http://") || string.hasPrefix("https://") {
                originalRemoteString = string
                filePath = .promised(urlString: string)
            } else {
                originalRemoteString = nil
                filePath = .existing(
                    path: string.bridge().absolutePathRepresentation(rootDirectory: rootDirectory)
                )
            }
            self.isInitialVertix = isInitialVertix
        }

        init(originalRemoteString: String?, originalRootDirectory: String, filePath: FilePath, isInitialVertix: Bool) {
            self.originalRemoteString = originalRemoteString
            self.originalRootDirectory = originalRootDirectory
            self.filePath = filePath
            self.isInitialVertix = isInitialVertix
        }

        internal func copy(withNewRootDirectory rootDirectory: String) -> Vertix {
            let vertix = Vertix(
                originalRemoteString: originalRemoteString,
                originalRootDirectory: rootDirectory,
                filePath: filePath,
                isInitialVertix: isInitialVertix
            )
            vertix.configurationDict = configurationDict
            return vertix
        }

        internal func build(
            remoteConfigTimeout: TimeInterval,
            remoteConfigTimeoutIfCached: TimeInterval
        ) throws {
            let path = try filePath.resolve(
                remoteConfigTimeout: remoteConfigTimeout,
                remoteConfigTimeoutIfCached: remoteConfigTimeoutIfCached
            )

            filePath = .existing(path: path)
            configurationDict = try YamlParser.parse(read(at: path))
        }

        private func read(at path: String) throws -> String {
            guard !path.isEmpty && FileManager.default.fileExists(atPath: path) else {
                throw isInitialVertix ?
                    ConfigurationError.initialFileNotFound(path: path) :
                    ConfigurationError.generic("File \(path) can't be found.")
            }

            return try String(contentsOfFile: path, encoding: .utf8)
        }

        internal static func == (lhs: Vertix, rhs: Vertix) -> Bool {
            return lhs.filePath == rhs.filePath
                && lhs.originalRemoteString == rhs.originalRemoteString
                && lhs.rootDirectory == rhs.rootDirectory
        }

        internal func hash(into hasher: inout Hasher) {
            hasher.combine(filePath)
            hasher.combine(originalRemoteString)
            hasher.combine(originalRootDirectory)
        }
    }

    // MARK: - Edge
    struct Edge: Hashable {
        var parent: Vertix!
        var child: Vertix!
    }

    // MARK: - EdgeType
    enum EdgeType: Hashable {
        case childConfig
        case parentConfig
    }
}
