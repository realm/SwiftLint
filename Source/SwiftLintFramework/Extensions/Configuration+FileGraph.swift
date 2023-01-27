import Foundation

@_spi(TestHelper)
public extension Configuration {
    struct FileGraph: Hashable {
        // MARK: - Properties
        private static let defaultRemoteConfigTimeout: TimeInterval = 2
        private static let defaultRemoteConfigTimeoutIfCached: TimeInterval = 1

        internal let rootDirectory: String

        private let ignoreParentAndChildConfigs: Bool

        private var vertices: Set<Vertix>
        private var edges: Set<Edge>

        private var isBuilt = false

        // MARK: - Initializers
        internal init(commandLineChildConfigs: [String], rootDirectory: String, ignoreParentAndChildConfigs: Bool) {
            let verticesArray = commandLineChildConfigs.map { config in
                Vertix(string: config, rootDirectory: rootDirectory, isInitialVertix: true)
            }
            vertices = Set(verticesArray)
            edges = Set(zip(verticesArray, verticesArray.dropFirst()).map { Edge(parent: $0.0, child: $0.1) })

            self.rootDirectory = rootDirectory
            self.ignoreParentAndChildConfigs = ignoreParentAndChildConfigs
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
        internal mutating func resultingConfiguration(
            enableAllRules: Bool,
            cachePath: String?
        ) throws -> Configuration {
            // Build if needed
            if !isBuilt {
                try build()
            }

            return try merged(
                configurationData: try validate(),
                enableAllRules: enableAllRules,
                cachePath: cachePath
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

        private mutating func processPossibleReference(
            ofType type: EdgeType,
            from vertix: Vertix,
            remoteConfigTimeoutOverride: TimeInterval?,
            remoteConfigTimeoutIfCachedOverride: TimeInterval?
        ) throws {
            let key = type == .childConfig ? Configuration.Key.childConfig.rawValue
                : Configuration.Key.parentConfig.rawValue

            if let reference = vertix.configurationDict[key] as? String {
                let referencedVertix = Vertix(string: reference, rootDirectory: vertix.rootDirectory,
                                              isInitialVertix: false)

                // Local vertices are allowed to have local / remote references
                // Remote vertices are only allowed to have remote references
                if vertix.originatesFromRemote && !referencedVertix.originatesFromRemote {
                    throw ConfigurationError.generic("Remote configs are not allowed to reference local configs.")
                } else {
                    let existingVertix = findPossiblyExistingVertix(sameAs: referencedVertix)
                    let existingVertixCopy = existingVertix.map { $0.copy(withNewRootDirectory: rootDirectory) }

                    edges.insert(
                        type == .childConfig
                            ? Edge(parent: vertix, child: existingVertixCopy ?? referencedVertix)
                            : Edge(parent: existingVertixCopy ?? referencedVertix, child: vertix)
                    )

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

        private func findPossiblyExistingVertix(sameAs vertix: Vertix) -> Vertix? {
            return vertices.first {
                $0.originalRemoteString != nil && $0.originalRemoteString == vertix.originalRemoteString
            } ?? vertices.first { $0.filePath == vertix.filePath }
        }

        // MARK: Validating
        /// Validates the Graph and throws failures
        /// If successful, returns array of configuration dicts that represents the graph
        private func validate() throws -> [(configurationDict: [String: Any], rootDirectory: String)] {
            // Detect cycles via back-edge detection during DFS
            func walkDown(stack: [Vertix]) throws {
                // Please note that the equality check (`==`), not the identity check (`===`) is used
                let children = edges.filter { $0.parent == stack.last }.map { $0.child! }
                if stack.contains(where: children.contains) {
                    throw ConfigurationError.generic("There's a cycle of child / parent config references. "
                        + "Please check the hierarchy of configuration files passed via the command line "
                        + "and the childConfig / parentConfig entries within them.")
                }
                try children.forEach { try walkDown(stack: stack + [$0]) }
            }

            try vertices.forEach { try walkDown(stack: [$0]) }

            // Detect ambiguities
            if (edges.contains { edge in edges.filter { $0.parent == edge.parent }.count > 1 }) {
                throw ConfigurationError.generic("There's an ambiguity in the child / parent configuration tree: "
                    + "More than one parent is declared for a specific configuration, "
                    + "where there should only be exactly one.")
            }

            if (edges.contains { edge in edges.filter { $0.child == edge.child }.count > 1 }) {
                throw ConfigurationError.generic("There's an ambiguity in the child / parent configuration tree: "
                    + "More than one child is declared for a specific configuration, "
                    + "where there should only be exactly one.")
            }

            // The graph should be like an array if validation passed -> return that array
            guard
                let startingVertix = (vertices.first { vertix in !edges.contains { $0.child == vertix } })
            else {
                guard vertices.isEmpty else {
                    throw ConfigurationError.generic("Unknown Configuration Error")
                }

                return []
            }

            var verticesToMerge = [startingVertix]
            while let vertix = (edges.first { $0.parent == verticesToMerge.last }?.child) {
                guard !verticesToMerge.contains(vertix) else {
                    // This shouldn't happen on a cycle free graph but let's safeguard
                    throw ConfigurationError.generic("Unknown Configuration Error")
                }

                verticesToMerge.append(vertix)
            }

            return verticesToMerge.map {
                return (
                    configurationDict: $0.configurationDict,
                    rootDirectory: $0.rootDirectory
                )
            }
        }

        // MARK: Merging
        private func merged(
            configurationData: [(configurationDict: [String: Any], rootDirectory: String)],
            enableAllRules: Bool,
            cachePath: String?
        ) throws -> Configuration {
            // Split into first & remainder; use empty dict for first if the array is empty
            let firstConfigurationData = configurationData.first ?? (configurationDict: [:], rootDirectory: "")
            let configurationData = Array(configurationData.dropFirst())

            // Build first configuration
            var firstConfiguration = try Configuration(
                dict: firstConfigurationData.configurationDict,
                enableAllRules: enableAllRules,
                cachePath: cachePath
            )

            // Set the config's rootDirectory to rootDirectory (+ adjust included / excluded paths that relate to it).
            // firstConfigurationData.rootDirectory may be different from rootDirectory,
            // e. g. when ../file.yml is passed as the first config
            firstConfiguration.fileGraph = Self(rootDirectory: rootDirectory)
            firstConfiguration.makeIncludedAndExcludedPaths(
                relativeTo: rootDirectory,
                previousBasePath: firstConfigurationData.rootDirectory
            )

            // Build succeeding configurations
            return try configurationData.reduce(firstConfiguration) {
                var childConfiguration = try Configuration(
                    dict: $1.configurationDict,
                    enableAllRules: enableAllRules,
                    cachePath: cachePath
                )
                childConfiguration.fileGraph = Self(rootDirectory: $1.rootDirectory)

                return $0.merged(withChild: childConfiguration, rootDirectory: rootDirectory)
            }
        }
    }
}
