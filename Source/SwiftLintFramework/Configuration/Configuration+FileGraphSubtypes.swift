import Foundation // swiftlint:disable:this file_name

internal extension Configuration.FileGraph {
    // MARK: - FilePath
    enum FilePath: Hashable {
        case promised(urlString: String)
        case existing(path: String)
    }

    // MARK: - Vertex
    class Vertex: Hashable {
        internal let originalRemoteString: String?
        internal var originatesFromRemote: Bool { originalRemoteString != nil }
        internal var rootDirectory: String {
            if !originatesFromRemote, case let .existing(path) = filePath {
                // This is a local file, so its root directory is its containing directory
                return path.bridge().deletingLastPathComponent
            }
            // This is a remote file, so its root directory is the directory where it was referenced from
            return originalRootDirectory
        }

        private let originalRootDirectory: String
        let isInitialVertex: Bool
        private(set) var filePath: FilePath
        private(set) var configurationDict: [String: Any] = [:]

        init(string: String, rootDirectory: String, isInitialVertex: Bool) {
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
            self.isInitialVertex = isInitialVertex
        }

        init(originalRemoteString: String?, originalRootDirectory: String, filePath: FilePath, isInitialVertex: Bool) {
            self.originalRemoteString = originalRemoteString
            self.originalRootDirectory = originalRootDirectory
            self.filePath = filePath
            self.isInitialVertex = isInitialVertex
        }

        internal func copy(withNewRootDirectory rootDirectory: String) -> Vertex {
            let vertex = Vertex(
                originalRemoteString: originalRemoteString,
                originalRootDirectory: rootDirectory,
                filePath: filePath,
                isInitialVertex: isInitialVertex
            )
            vertex.configurationDict = configurationDict
            return vertex
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
                throw isInitialVertex
                    ? Issue.initialFileNotFound(path: path)
                    : Issue.fileNotFound(path: path)
            }

            return try String(contentsOfFile: path, encoding: .utf8)
        }

        internal static func == (lhs: Vertex, rhs: Vertex) -> Bool {
            lhs.filePath == rhs.filePath
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
