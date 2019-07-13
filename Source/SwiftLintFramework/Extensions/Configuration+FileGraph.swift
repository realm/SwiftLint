import Foundation

internal extension Configuration {
    struct FileGraph: Hashable {
        // MARK: - Subtypes
        public enum FilePath: Hashable { // swiftlint:disable:this nesting
            case promised(urlString: String)
            case existing(path: String)
        }

        private class Vertix: Hashable { // swiftlint:disable:this nesting
            internal var originatesFromRemote: Bool { return originalRemoteString != nil }
            internal let originalRemoteString: String?

            private(set) var filePath: FilePath

            private(set) var configurationString: String = ""
            private(set) var configurationDict: [String: Any] = [:]

            init(string: String, rootDirectory: String) {
                if string.hasPrefix("http://") || string.hasPrefix("https://") {
                    originalRemoteString = string
                    filePath = .promised(urlString: string)
                } else {
                    originalRemoteString = nil
                    filePath = .existing(
                        path: string.bridge().absolutePathRepresentation(rootDirectory: rootDirectory)
                    )
                }
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
                configurationString = try read(at: path)
                configurationDict = try YamlParser.parse(configurationString)
            }

            private func read(at path: String) throws -> String {
                guard !path.isEmpty && FileManager.default.fileExists(atPath: path) else {
                    throw ConfigurationError.generic("File \(path) can't be found.")
                }

                return try String(contentsOfFile: path, encoding: .utf8)
            }

            internal static func == (lhs: Vertix, rhs: Vertix) -> Bool {
                return lhs.filePath == rhs.filePath
            }

            internal func hash(into hasher: inout Hasher) {
                hasher.combine(filePath)
            }
        }

        private struct Edge: Hashable { // swiftlint:disable:this nesting
            var type: EdgeType
            var origin: Vertix!
            var target: Vertix!

            internal static func == (lhs: Edge, rhs: Edge) -> Bool {
                return lhs.type == rhs.type &&
                    lhs.origin == rhs.origin &&
                    lhs.target == rhs.target
            }

            internal func hash(into hasher: inout Hasher) {
                hasher.combine(type)
                hasher.combine(origin)
                hasher.combine(target)
            }
        }

        private enum EdgeType: Hashable { // swiftlint:disable:this nesting
            case childConfig
            case parentConfig
            case commandLineChildConfig
        }

        // MARK: - Properties
        private static let defaultRemoteConfigTimeout: TimeInterval = 2
        private static let defaultRemoteConfigTimeoutIfCached: TimeInterval = 1

        internal let rootDirectory: String

        private let ignoreParentAndChildConfigs: Bool

        private var vertices: Set<Vertix>
        private var edges: Set<Edge>

        private var isBuilt: Bool = false

        // MARK: - Initializers
        internal init(commandLineChildConfigs: [String], rootDirectory: String, ignoreParentAndChildConfigs: Bool) {
            vertices = Set(commandLineChildConfigs.map { Vertix(string: $0, rootDirectory: rootDirectory) })
            edges = Set(zip(vertices, vertices.dropFirst()).map {
                Edge(type: .commandLineChildConfig, origin: $0.0, target: $0.1)
            })

            self.rootDirectory = rootDirectory
            self.ignoreParentAndChildConfigs = ignoreParentAndChildConfigs
        }

        internal init(config: String, rootDirectory: String, ignoreParentAndChildConfigs: Bool) throws {
            self.init(
                commandLineChildConfigs: [config],
                rootDirectory: rootDirectory,
                ignoreParentAndChildConfigs: ignoreParentAndChildConfigs
            )
        }

        /// Dummy init to get a FileGraph that just represents a root directory
        internal init(rootDirectory: String) {
            self.init(
                commandLineChildConfigs: [],
                rootDirectory: rootDirectory,
                ignoreParentAndChildConfigs: false
            )

            isBuilt = true
        }

        // MARK: - Methods
        internal mutating func resultingConfiguration(enableAllRules: Bool) throws -> Configuration {
            // Build if needed
            if !isBuilt {
                try build()
            }

            return try merged(
                configurationDicts: try validate(),
                enableAllRules: enableAllRules
            )
        }

        internal func includesFile(atPath path: String) -> Bool? {
            guard isBuilt else { return nil }

            return vertices.contains { vertix in
                if case let .existing(filePath) = vertix.filePath {
                    return path == filePath
                }

                return false
            }
        }

        // MARK: Building
        private mutating func build() throws {
            for vertix in vertices {
                try process(vertix: vertix)
            }

            isBuilt = true
        }

        private mutating func process(
            vertix: Vertix,
            remoteConfigTimeoutOverride: TimeInterval? = nil,
            remoteConfigTimeoutIfCachedOverride: TimeInterval? = nil
        ) throws {
            try vertix.build(
                remoteConfigTimeout: remoteConfigTimeoutOverride ?? Configuration.FileGraph.defaultRemoteConfigTimeout,
                remoteConfigTimeoutIfCached: remoteConfigTimeoutIfCachedOverride
                    ?? remoteConfigTimeoutOverride ?? Configuration.FileGraph.defaultRemoteConfigTimeoutIfCached
            )

            if !ignoreParentAndChildConfigs {
                try processPossibleReference(
                    ofType: .childConfig,
                    from: vertix,
                    remoteConfigTimeoutOverride: remoteConfigTimeoutOverride,
                    remoteConfigTimeoutIfCachedOverride: remoteConfigTimeoutIfCachedOverride
                )
                try processPossibleReference(
                    ofType: .parentConfig,
                    from: vertix,
                    remoteConfigTimeoutOverride: remoteConfigTimeoutOverride,
                    remoteConfigTimeoutIfCachedOverride: remoteConfigTimeoutIfCachedOverride
                )
            }
        }

        private func findPossiblyExistingVertix(sameAs vertix: Vertix) -> Vertix? {
            return vertices.first {
                $0.originalRemoteString != nil && $0.originalRemoteString == vertix.originalRemoteString
            } ?? vertices.first { $0.filePath == vertix.filePath }
        }

        private mutating func processPossibleReference(
            ofType type: EdgeType,
            from vertix: Vertix,
            remoteConfigTimeoutOverride: TimeInterval?,
            remoteConfigTimeoutIfCachedOverride: TimeInterval?
        ) throws {
            let key = type == .childConfig ? Configuration.Key.childConfig.rawValue
                : Configuration.Key.parentConfig.rawValue

            if let reference = vertix.configurationDict[key] as? String {
                var rootDirectory: String = ""
                if case let .existing(path) = vertix.filePath {
                    rootDirectory = path.bridge().deletingLastPathComponent
                }

                let referencedVertix = Vertix(string: reference, rootDirectory: rootDirectory)

                // Local vertices are allowed to have local / remote references
                // Remote vertices are only allowed to have remote references
                if vertix.originatesFromRemote && !referencedVertix.originatesFromRemote {
                    throw ConfigurationError.generic("Remote configs are not allowed to reference local configs.")
                } else {
                    let existingVertix = findPossiblyExistingVertix(sameAs: referencedVertix)

                    let edge: Edge
                    switch type {
                    case .childConfig, .commandLineChildConfig: // The latter should not happen
                        edge = Edge(type: .childConfig, origin: vertix, target: existingVertix ?? referencedVertix)

                    case .parentConfig:
                        edge = Edge(type: .parentConfig, origin: existingVertix ?? referencedVertix, target: vertix)
                    }

                    edges.insert(edge)

                    if existingVertix == nil {
                        vertices.insert(referencedVertix)

                        // Use timeout config from vertix / parent of vertix if some
                        let remoteConfigTimeout =
                            vertix.configurationDict[Configuration.Key.remoteConfigTimeout.rawValue]
                                as? TimeInterval
                                ?? remoteConfigTimeoutOverride // from vertix parent
                        let remoteConfigTimeoutIfCached =
                            vertix.configurationDict[Configuration.Key.remoteConfigTimeoutIfCached.rawValue]
                                as? TimeInterval
                                ?? remoteConfigTimeoutIfCachedOverride // from vertix parent

                        try process(
                            vertix: referencedVertix,
                            remoteConfigTimeoutOverride: remoteConfigTimeout,
                            remoteConfigTimeoutIfCachedOverride: remoteConfigTimeoutIfCached
                        )
                    }
                }
            }
        }

        // MARK: Validating
        /// Validates the Graph and throws failures
        /// If successful, returns array of configuration dicts that represents the graph
        private func validate() throws -> [[String: Any]] {
            // Detect cycles via back-edge detection during DFS
            func walkDown(stack: [Vertix]) throws {
                let neighbours = edges.filter { $0.origin == stack.last }.map { $0.target! }
                if stack.contains(where: neighbours.contains) {
                    throw ConfigurationError.generic("There's a cycle of child / parent config references. "
                        + "Please check the hierarchy of configuration files passed via the command line "
                        + "and the childConfig / parentConfig entries within them.")
                }
                try neighbours.forEach { try walkDown(stack: stack + [$0]) }
            }

            try vertices.forEach { try walkDown(stack: [$0]) }

            // Detect ambiguities
            if (edges.contains { edge in edges.filter { $0.origin == edge.origin }.count > 1 }) {
                throw ConfigurationError.generic("There's an ambiguity in the child / parent configuration tree: "
                    + "More than one parent is declared for a specific configuration, "
                    + "where there should only be exactly one.")
            }

            if (edges.contains { edge in edges.filter { $0.target == edge.target }.count > 1 }) {
                throw ConfigurationError.generic("There's an ambiguity in the child / parent configuration tree: "
                    + "More than one child is declared for a specific configuration, "
                    + "where there should only be exactly one.")
            }

            // The graph should be like an array if validation passed -> return that array
            guard
                let startingVertix = (vertices.first { vertix in !edges.contains { $0.target == vertix } })
            else {
                guard vertices.isEmpty else {
                    throw ConfigurationError.generic("Unknown Configuration Error")
                }

                return []
            }

            var verticesToMerge = [startingVertix]
            while let vertix = (edges.first { $0.origin == verticesToMerge.last }?.target) {
                guard !verticesToMerge.contains(vertix) else {
                    // This shouldn't happen on a cycle free graph but let's safeguard
                    throw ConfigurationError.generic("Unknown Configuration Error")
                }

                verticesToMerge.append(vertix)
            }

            return verticesToMerge.map { $0.configurationDict }
        }

        // MARK: Merging
        private func merged(
            configurationDicts: [[String: Any]],
            enableAllRules: Bool
        ) throws -> Configuration {
            let firstConfigurationDict = configurationDicts.first ?? [:] // Use empty dict if nothing else provided
            let configurationDicts = Array(configurationDicts.dropFirst())
            let firstConfiguration = try Configuration(dict: firstConfigurationDict, enableAllRules: enableAllRules)
            return try configurationDicts.reduce(firstConfiguration) {
                $0.merged(with: try Configuration(dict: $1, enableAllRules: enableAllRules))
            }
        }
    }
}
