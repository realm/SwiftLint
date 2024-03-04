import Foundation

package extension Configuration {
    struct FileGraph: Hashable {
        // MARK: - Properties
        private static let defaultRemoteConfigTimeout: TimeInterval = 2
        private static let defaultRemoteConfigTimeoutIfCached: TimeInterval = 1

        internal let rootDirectory: String

        private let ignoreParentAndChildConfigs: Bool

        private var vertices: Set<Vertex>
        private var edges: Set<Edge>

        private var isBuilt = false

        // MARK: - Initializers
        internal init(commandLineChildConfigs: [String], rootDirectory: String, ignoreParentAndChildConfigs: Bool) {
            let verticesArray = commandLineChildConfigs.map { config in
                Vertex(string: config, rootDirectory: rootDirectory, isInitialVertex: true)
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
            onlyRule: [String],
            cachePath: String?
        ) throws -> Configuration {
            // Build if needed
            if !isBuilt {
                try build()
            }

            return try merged(
                configurationData: try validate(),
                enableAllRules: enableAllRules,
                onlyRule: onlyRule,
                cachePath: cachePath
            )
        }

        internal func includesFile(atPath path: String) -> Bool {
            guard isBuilt else { return false }

            return vertices.contains { vertex in
                if case let .existing(filePath) = vertex.filePath {
                    return path == filePath
                }

                return false
            }
        }

        // MARK: Building
        private mutating func build() throws {
            for vertex in vertices {
                try process(vertex: vertex)
            }

            isBuilt = true
        }

        private mutating func process(
            vertex: Vertex,
            remoteConfigTimeoutOverride: TimeInterval? = nil,
            remoteConfigTimeoutIfCachedOverride: TimeInterval? = nil
        ) throws {
            try vertex.build(
                remoteConfigTimeout: remoteConfigTimeoutOverride ?? Configuration.FileGraph.defaultRemoteConfigTimeout,
                remoteConfigTimeoutIfCached: remoteConfigTimeoutIfCachedOverride
                    ?? remoteConfigTimeoutOverride ?? Configuration.FileGraph.defaultRemoteConfigTimeoutIfCached
            )

            if !ignoreParentAndChildConfigs {
                try processPossibleReferenceIgnoringFileAbsence(
                    ofType: .childConfig,
                    from: vertex,
                    remoteConfigTimeoutOverride: remoteConfigTimeoutOverride,
                    remoteConfigTimeoutIfCachedOverride: remoteConfigTimeoutIfCachedOverride)

                try processPossibleReferenceIgnoringFileAbsence(
                    ofType: .parentConfig,
                    from: vertex,
                    remoteConfigTimeoutOverride: remoteConfigTimeoutOverride,
                    remoteConfigTimeoutIfCachedOverride: remoteConfigTimeoutIfCachedOverride)
            }
        }

        private mutating func processPossibleReferenceIgnoringFileAbsence(
            ofType type: EdgeType,
            from vertex: Vertex,
            remoteConfigTimeoutOverride: TimeInterval?,
            remoteConfigTimeoutIfCachedOverride: TimeInterval?
        ) throws {
            do {
                try processPossibleReference(
                    ofType: type,
                    from: vertex,
                    remoteConfigTimeoutOverride: remoteConfigTimeoutOverride,
                    remoteConfigTimeoutIfCachedOverride: remoteConfigTimeoutIfCachedOverride
                )
            } catch {
                // If a child or parent config file doesn't exist, do not fail the rest of the config tree.
                // Instead, just ignore this leaf of the config. Otherwise, rethrow the error.
                guard case let Issue.fileNotFound(path) = error else {
                    throw error
                }
                queuedPrintError("""
                    A local configuration at \(path) was not found. \
                    Ignoring this part of the configuration.
                    """
                )
            }
        }

        private mutating func processPossibleReference(
            ofType type: EdgeType,
            from vertex: Vertex,
            remoteConfigTimeoutOverride: TimeInterval?,
            remoteConfigTimeoutIfCachedOverride: TimeInterval?
        ) throws {
            let key = type == .childConfig ? Configuration.Key.childConfig.rawValue
                : Configuration.Key.parentConfig.rawValue

            if let reference = vertex.configurationDict[key] as? String {
                let referencedVertex = Vertex(string: reference, rootDirectory: vertex.rootDirectory,
                                              isInitialVertex: false)

                // Local vertices are allowed to have local / remote references
                // Remote vertices are only allowed to have remote references
                if vertex.originatesFromRemote && !referencedVertex.originatesFromRemote {
                    throw Issue.genericWarning("Remote configs are not allowed to reference local configs.")
                }
                let existingVertex = findPossiblyExistingVertex(sameAs: referencedVertex)
                let existingVertexCopy = existingVertex.map { $0.copy(withNewRootDirectory: rootDirectory) }

                edges.insert(
                    type == .childConfig
                        ? Edge(parent: vertex, child: existingVertexCopy ?? referencedVertex)
                        : Edge(parent: existingVertexCopy ?? referencedVertex, child: vertex)
                )

                if existingVertex == nil {
                    vertices.insert(referencedVertex)

                    // Use timeout config from vertex / parent of vertex if some
                    let remoteConfigTimeout =
                        vertex.configurationDict[Configuration.Key.remoteConfigTimeout.rawValue]
                            as? TimeInterval
                            ?? remoteConfigTimeoutOverride // from vertex parent
                    let remoteConfigTimeoutIfCached =
                        vertex.configurationDict[Configuration.Key.remoteConfigTimeoutIfCached.rawValue]
                            as? TimeInterval
                            ?? remoteConfigTimeoutIfCachedOverride // from vertex parent

                    try process(
                        vertex: referencedVertex,
                        remoteConfigTimeoutOverride: remoteConfigTimeout,
                        remoteConfigTimeoutIfCachedOverride: remoteConfigTimeoutIfCached
                    )
                }
            }
        }

        private func findPossiblyExistingVertex(sameAs vertex: Vertex) -> Vertex? {
            vertices.first {
                $0.originalRemoteString != nil && $0.originalRemoteString == vertex.originalRemoteString
            } ?? vertices.first { $0.filePath == vertex.filePath }
        }

        // MARK: Validating
        /// Validates the Graph and throws failures
        /// If successful, returns array of configuration dicts that represents the graph
        private func validate() throws -> [(configurationDict: [String: Any], rootDirectory: String)] {
            // Detect cycles via back-edge detection during DFS
            func walkDown(stack: [Vertex]) throws {
                // Please note that the equality check (`==`), not the identity check (`===`) is used
                let children = edges.filter { $0.parent == stack.last }.map { $0.child! }
                if stack.contains(where: children.contains) {
                    throw Issue.genericWarning("There's a cycle of child / parent config references. "
                        + "Please check the hierarchy of configuration files passed via the command line "
                        + "and the childConfig / parentConfig entries within them.")
                }
                try children.forEach { try walkDown(stack: stack + [$0]) }
            }

            try vertices.forEach { try walkDown(stack: [$0]) }

            // Detect ambiguities
            if (edges.contains { edge in edges.filter { $0.parent == edge.parent }.count > 1 }) {
                throw Issue.genericWarning("There's an ambiguity in the child / parent configuration tree: "
                    + "More than one parent is declared for a specific configuration, "
                    + "where there should only be exactly one.")
            }

            if (edges.contains { edge in edges.filter { $0.child == edge.child }.count > 1 }) {
                throw Issue.genericWarning("There's an ambiguity in the child / parent configuration tree: "
                    + "More than one child is declared for a specific configuration, "
                    + "where there should only be exactly one.")
            }

            // The graph should be like an array if validation passed -> return that array
            guard
                let startingVertex = (vertices.first { vertex in !edges.contains { $0.child == vertex } })
            else {
                guard vertices.isEmpty else {
                    throw Issue.genericWarning("Unknown Configuration Error")
                }

                return []
            }

            var verticesToMerge = [startingVertex]
            while let vertex = (edges.first { $0.parent == verticesToMerge.last }?.child) {
                guard !verticesToMerge.contains(vertex) else {
                    // This shouldn't happen on a cycle free graph but let's safeguard
                    throw Issue.genericWarning("Unknown Configuration Error")
                }

                verticesToMerge.append(vertex)
            }

            return verticesToMerge.map {
                (
                    configurationDict: $0.configurationDict,
                    rootDirectory: $0.rootDirectory
                )
            }
        }

        // MARK: Merging
        private func merged(
            configurationData: [(configurationDict: [String: Any], rootDirectory: String)],
            enableAllRules: Bool,
            onlyRule: [String],
            cachePath: String?
        ) throws -> Configuration {
            // Split into first & remainder; use empty dict for first if the array is empty
            let firstConfigurationData = configurationData.first ?? (configurationDict: [:], rootDirectory: "")
            let configurationData = Array(configurationData.dropFirst())

            // Build first configuration
            var firstConfiguration = try Configuration(
                dict: firstConfigurationData.configurationDict,
                enableAllRules: enableAllRules,
                onlyRule: onlyRule,
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
                    parentConfiguration: $0,
                    dict: $1.configurationDict,
                    enableAllRules: enableAllRules,
                    onlyRule: onlyRule,
                    cachePath: cachePath
                )
                childConfiguration.fileGraph = Self(rootDirectory: $1.rootDirectory)

                return $0.merged(withChild: childConfiguration, rootDirectory: rootDirectory)
            }
        }
    }
}
