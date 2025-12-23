import Foundation // swiftlint:disable:this file_name
import SourceKittenFramework

internal extension Configuration.FileGraph {
    // MARK: - FilePath
    enum FilePath: Hashable {
        case promised(urlString: URL)
        case existing(path: URL)
    }

    // MARK: - Vertex
    class Vertex: Hashable {
        var originatesFromRemote: Bool {
            if case .promised = filePath {
                return true
            }
            return false
         }

        var rootDirectory: URL {
            if case let .existing(path) = filePath {
                // This is a local file, so its root directory is its containing directory
                return path.deletingLastPathComponent()
            }
            // This is a remote file, so its root directory is the directory where it was referenced from
            return originalRootDirectory
        }

        private let originalRootDirectory: URL
        let isInitialVertex: Bool
        private(set) var filePath: FilePath
        private(set) var configurationDict: [String: Any] = [:]

        init(configPath: URL, rootDirectory: URL, isInitialVertex: Bool) {
            originalRootDirectory = rootDirectory
            filePath =
                if ["http", "https"].contains(configPath.scheme) {
                    .promised(urlString: configPath)
                } else {
                    .existing(path: URL(filePath: configPath.path, relativeTo: rootDirectory))
                }
            self.isInitialVertex = isInitialVertex
        }

        init(originalRootDirectory: URL, filePath: FilePath, isInitialVertex: Bool) {
            self.originalRootDirectory = originalRootDirectory
            self.filePath = filePath
            self.isInitialVertex = isInitialVertex
        }

        internal func copy(withNewRootDirectory rootDirectory: URL) -> Vertex {
            let vertex = Vertex(
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

        private func read(at path: URL) throws -> String {
            guard path.exists else {
                throw isInitialVertex
                    ? Issue.initialFileNotFound(path: path)
                    : Issue.fileNotFound(path: path)
            }

            return try String(contentsOf: path, encoding: .utf8)
        }

        static func == (lhs: Vertex, rhs: Vertex) -> Bool {
            lhs.filePath == rhs.filePath && lhs.rootDirectory == rhs.rootDirectory
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(filePath)
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
