import Foundation

internal extension Configuration {
    struct FileGraph: Hashable {
        // MARK: - Subtypes
        public enum FilePath: Hashable { // swiftlint:disable:this nesting
            case promised(urlString: String)
            case existing(path: String)
        }

        private class Vertix: Hashable { // swiftlint:disable:this nesting
            private(set) var filePath: FilePath
            private(set) var configurationString: String = ""
            private(set) var configurationDict: [String: Any] = [:]

            init(string: String) {
                // Get file path
                let remotePrefix = "remote:"
                if string.hasPrefix(remotePrefix) {
                    filePath = .promised(urlString: String(string.dropFirst(remotePrefix.count)))
                } else {
                    filePath = .existing(path: string)
                }
            }

            internal func build(
                rootDirectory: String,
                remoteConfigLoadingTimeout: Double,
                remoteConfigLoadingTimeoutIfCached: Double
            ) throws {
                let path = try filePath.resolve(
                    remoteConfigLoadingTimeout: remoteConfigLoadingTimeout,
                    remoteConfigLoadingTimeoutIfCached: remoteConfigLoadingTimeoutIfCached,
                    rootDirectory: rootDirectory
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
            var edgeType: EdgeType
            unowned var origin: Vertix!
            unowned var target: Vertix!

            internal static func == (lhs: Edge, rhs: Edge) -> Bool {
                return lhs.edgeType == rhs.edgeType &&
                    lhs.origin == rhs.origin &&
                    lhs.target == rhs.target
            }

            internal func hash(into hasher: inout Hasher) {
                hasher.combine(edgeType)
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
        internal let rootDirectory: String

        private let ignoreParentAndChildConfigs: Bool

        private var vertices: Set<Vertix>
        private var edges: Set<Edge>

        private var isBuilt: Bool = false

        // MARK: - Initializers
        internal init(commandLineChildConfigs: [String], rootDirectory: String, ignoreParentAndChildConfigs: Bool) {
            vertices = Set(commandLineChildConfigs.map { Vertix(string: $0) })
            edges = Set(zip(vertices, vertices.dropFirst()).map {
                Edge(edgeType: .commandLineChildConfig, origin: $0.0, target: $0.1)
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

        internal init(rootDirectory: String, ignoreParentAndChildConfigs: Bool) {
            self.init(
                commandLineChildConfigs: [],
                rootDirectory: rootDirectory,
                ignoreParentAndChildConfigs: ignoreParentAndChildConfigs
            )
        }

        // MARK: - Methods
        internal mutating func resultingConfiguration(
            enableAllRules: Bool,
            remoteConfigLoadingTimeout: Double,
            remoteConfigLoadingTimeoutIfCached: Double
        ) throws -> Configuration {
            // Build if needed
            if !isBuilt {
                try build(
                    remoteConfigLoadingTimeout: remoteConfigLoadingTimeout,
                    remoteConfigLoadingTimeoutIfCached: remoteConfigLoadingTimeoutIfCached
                )
                isBuilt = true
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

        // MARK: Private
        private mutating func build(
            remoteConfigLoadingTimeout: Double,
            remoteConfigLoadingTimeoutIfCached: Double
        ) throws {
            func process(vertix: Vertix) throws {
                try vertix.build(
                    rootDirectory: rootDirectory,
                    remoteConfigLoadingTimeout: remoteConfigLoadingTimeout,
                    remoteConfigLoadingTimeoutIfCached: remoteConfigLoadingTimeoutIfCached
                )

                if !ignoreParentAndChildConfigs {
                    if
                        let childConfigReference =
                            vertix.configurationDict[Configuration.Key.childConfig.rawValue] as? String
                    {
                        let childVertix = Vertix(string: childConfigReference)
                        vertices.insert(childVertix)
                        let childEdge = Edge(edgeType: .childConfig, origin: vertix, target: childVertix)
                        edges.insert(childEdge)
                        try process(vertix: childVertix)
                    }

                    if
                        let parentConfigReference =
                            vertix.configurationDict[Configuration.Key.parentConfig.rawValue] as? String
                    {
                        let parentVertix = Vertix(string: parentConfigReference)
                        vertices.insert(parentVertix)
                        let parentEdge = Edge(edgeType: .parentConfig, origin: parentVertix, target: vertix)
                        edges.insert(parentEdge)
                        try process(vertix: parentVertix)
                    }
                }
            }

            for vertix in vertices {
                try process(vertix: vertix)
            }
        }

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
                throw ConfigurationError.generic("Unknown Configuration Error")
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

        private func merged(
            configurationDicts: [[String: Any]],
            enableAllRules: Bool
        ) throws -> Configuration {
            guard let firstConfigurationDict = configurationDicts.first else {
                throw ConfigurationError.generic("Unknown Configuration Error")
            }

            let configurationDicts = Array(configurationDicts.dropFirst())
            let firstConfiguration = try Configuration(dict: firstConfigurationDict, enableAllRules: enableAllRules)
            return try configurationDicts.reduce(firstConfiguration) {
                $0.merged(with: try Configuration(dict: $1, enableAllRules: enableAllRules))
            }
        }
    }
}
