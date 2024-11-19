import Foundation // swiftlint:disable:this file_name

extension Configuration.FileGraph {
    // MARK: - FilePath
    enum FilePath: Hashable {
        case promised(urlString: String)
        case existing(path: String)
    }

    // MARK: - Vertex
    final class Vertex: Hashable, Sendable {
        var originatesFromRemote: Bool { originalRemoteString != nil }
        var rootDirectory: String {
            if !originatesFromRemote, case let .existing(path) = filePath {
                // This is a local file, so its root directory is its containing directory
                return path.bridge().deletingLastPathComponent
            }
            // This is a remote file, so its root directory is the directory where it was referenced from
            return originalRootDirectory
        }

        private let originalRootDirectory: String
        let originalRemoteString: String?
        let isInitialVertex: Bool
        private let lock = NSLock()
        private(set) nonisolated(unsafe) var filePath: FilePath
        private(set) nonisolated(unsafe) var configurationDict: [String: Any]

        convenience init(string: String, rootDirectory: String, isInitialVertex: Bool) {
            let (originalRemoteString, filePath): (String?, FilePath) =
                if string.hasPrefix("http://") || string.hasPrefix("https://") {
                    (string, .promised(urlString: string))
                } else {
                    (nil, .existing(path: string.bridge().absolutePathRepresentation(rootDirectory: rootDirectory)))
                }
            self.init(
                originalRemoteString: originalRemoteString,
                originalRootDirectory: rootDirectory,
                filePath: filePath,
                isInitialVertex: isInitialVertex
            )
        }

        init(originalRemoteString: String?,
             originalRootDirectory: String,
             filePath: FilePath,
             isInitialVertex: Bool,
             configurationDict: [String: Any] = [:]) {
            self.originalRemoteString = originalRemoteString
            self.originalRootDirectory = originalRootDirectory
            self.filePath = filePath
            self.isInitialVertex = isInitialVertex
            self.configurationDict = configurationDict
        }

        func copy(withNewRootDirectory rootDirectory: String) -> Vertex {
            Vertex(
                originalRemoteString: originalRemoteString,
                originalRootDirectory: rootDirectory,
                filePath: filePath,
                isInitialVertex: isInitialVertex,
                configurationDict: configurationDict
            )
        }

        func adaptFromConfig(
            remoteConfigTimeout: TimeInterval,
            remoteConfigTimeoutIfCached: TimeInterval
        ) async throws {
            let path = try await filePath.resolve(
                remoteConfigTimeout: remoteConfigTimeout,
                remoteConfigTimeoutIfCached: remoteConfigTimeoutIfCached
            )
            try lock.withLock {
                self.filePath = .existing(path: path)
                self.configurationDict = try YamlParser.parse(read(at: path))
            }
        }

        private func read(at path: String) throws -> String {
            guard !path.isEmpty && FileManager.default.fileExists(atPath: path) else {
                throw isInitialVertex
                    ? Issue.initialFileNotFound(path: path)
                    : Issue.fileNotFound(path: path)
            }

            return try String(contentsOfFile: path, encoding: .utf8)
        }

        static func == (lhs: Vertex, rhs: Vertex) -> Bool {
            lhs.filePath == rhs.filePath
                && lhs.originalRemoteString == rhs.originalRemoteString
                && lhs.rootDirectory == rhs.rootDirectory
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(filePath)
            hasher.combine(originalRemoteString)
            hasher.combine(originalRootDirectory)
        }
    }

    // MARK: - Edge
    struct Edge: Hashable, Sendable {
        // swiftlint:disable implicitly_unwrapped_optional
        var parent: Vertex!
        var child: Vertex!
        // swiftlint:enable implicitly_unwrapped_optional
    }

    // MARK: - EdgeType
    enum EdgeType: Hashable {
        case childConfig
        case parentConfig
    }
}
