import Foundation

public extension Configuration {
    struct Graph: Hashable {
        // MARK: - Subtypes
        public class Vertix: Hashable { // swiftlint:disable:this nesting
            private(set) var filePath: String = ""
            private(set) var configurationString: String = ""
            private(set) var configurationDict: [String: Any] = [:]

            init(string: String, rootPath: String?) throws {
                // Get file path
                if string.contains("remote:") {
                    // Download from remote...
                    filePath = "todo" // TODO
                } else {
                    filePath = string
                }

                // Get contents
                configurationString = try read(at: filePath, rootPath: rootPath)
                configurationDict = try YamlParser.parse(configurationString)
            }

            private func read(at path: String, rootPath: String?) throws -> String {
                let fullPath: String
                var isDir: ObjCBool = false
                if
                    let rootPath = rootPath,
                    FileManager.default.fileExists(atPath: rootPath, isDirectory: &isDir) && isDir.boolValue
                {
                    // rootPath is Directory
                    fullPath = path.bridge().absolutePathRepresentation(rootDirectory: rootPath)
                } else {
                    fullPath = path.bridge().absolutePathRepresentation()
                }

                guard !path.isEmpty && FileManager.default.fileExists(atPath: fullPath) else {
                    throw ConfigurationError.generic("File \(path) can't be found.")
                }

                return try String(contentsOfFile: fullPath, encoding: .utf8)
            }

            public static func == (lhs: Vertix, rhs: Vertix) -> Bool {
                return lhs.filePath == rhs.filePath
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(filePath)
            }
        }

        public struct Edge: Hashable { // swiftlint:disable:this nesting
            var edgeType: EdgeType
            unowned var origin: Vertix!
            unowned var target: Vertix!

            public static func == (lhs: Edge, rhs: Edge) -> Bool {
                return lhs.edgeType == rhs.edgeType &&
                    lhs.origin == rhs.origin &&
                    lhs.target == rhs.target
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(edgeType)
                hasher.combine(origin)
                hasher.combine(target)
            }
        }

        public enum EdgeType: Hashable { // swiftlint:disable:this nesting
            case childConfig
            case parentConfig
            case commandLineChildConfig
        }

        // MARK: - Properties
        private(set) var vertices: Set<Vertix>
        private(set) var edges: Set<Edge>
        private(set) var rootPath: String?
        private var isBuiltAndValidated: Bool = false

        // MARK: - Initializers
        public init(commandLineChildConfigs: [String], rootPath: String?) throws {
            vertices = Set(try commandLineChildConfigs.map { try Vertix(string: $0, rootPath: rootPath) })
            edges = Set(zip(vertices, vertices.dropFirst()).map {
                Edge(edgeType: .commandLineChildConfig, origin: $0.0, target: $0.1)
            })

            self.rootPath = rootPath
        }

        public init(singleConfig: String, rootPath: String?) throws {
            vertices = [try Vertix(string: singleConfig, rootPath: rootPath)]
            edges = []
            self.rootPath = rootPath
        }

        public init(rootPath: String?) {
            self.rootPath = rootPath
            vertices = []
            edges = []
        }

        // MARK: - Methods
        public mutating func getResultingConfiguration(configurationFactory: (([String: Any]) throws -> Configuration)) throws -> Configuration {
            if !isBuiltAndValidated {
                try build()
                try validate()
                isBuiltAndValidated = true
            }

            return try merged(configurationFactory: configurationFactory)
        }

        // MARK: Private
        private mutating func build() throws {
            func process(vertix: Vertix) throws {
                if let childConfigReference =
                    vertix.configurationDict[Configuration.Key.childConfig.rawValue] as? String {
                    let childVertix = try Vertix(string: childConfigReference, rootPath: rootPath)
                    vertices.insert(childVertix)
                    let childEdge = Edge(edgeType: .childConfig, origin: vertix, target: childVertix)
                    edges.insert(childEdge)
                    try process(vertix: childVertix)
                }

                if let parentConfigReference
                    = vertix.configurationDict[Configuration.Key.parentConfig.rawValue] as? String {
                    let parentVertix = try Vertix(string: parentConfigReference, rootPath: rootPath)
                    vertices.insert(parentVertix)
                    let parentEdge = Edge(edgeType: .parentConfig, origin: parentVertix, target: vertix)
                    edges.insert(parentEdge)
                    try process(vertix: parentVertix)
                }
            }

            for vertix in vertices {
                try process(vertix: vertix)
            }
        }

        private func validate() throws {
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
        }

        private func merged(configurationFactory: (([String: Any]) throws -> Configuration)) throws -> Configuration {
            // Get starting vertix (that isn't the target of any edge)
            var verticesToMerge = [vertices.first { vertix in !edges.contains { $0.target == vertix } }!]

            // Get array of vertices (the graph should be like an array if validation passed)
            while let vertix = (edges.first { $0.origin == verticesToMerge.last }?.origin) {
                verticesToMerge.append(vertix)
            }

            // Merge all these configurations into on Configuration
            let configuration = try configurationFactory(verticesToMerge.first!.configurationDict)
            verticesToMerge = Array(verticesToMerge.dropFirst())
            return try verticesToMerge.reduce(configuration) {
                $0.merged(with: try configurationFactory($1.configurationDict))
            }
        }
    }
}
