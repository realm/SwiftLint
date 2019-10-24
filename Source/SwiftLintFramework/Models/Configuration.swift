import Foundation
import SourceKittenFramework

// TODO: What happens if child/parent_config is specified multiple times in a single file?
// TODO: Don't include child/parent_config again as nested config
// TODO: Remote Config Cache Versioning
// TODO: Tests
// TODO: Docs
public struct Configuration {
    // MARK: - Properties: Static
    public static let `default` = Configuration()
    public static let fileName = ".swiftlint.yml"

    // MARK: Public Instance
    /// The rules to be linted
    public var rules: [Rule] {
        return rulesWrapper.resultingRules
    }

    /// The root directory of the files used for this Configuration, if some
    public var rootDirectory: String? {
        return fileGraph?.rootDirectory
    }

    /// The paths that should be included when linting
    public let includedPaths: [String]

    /// The paths that should be excluded when linting
    public let excludedPaths: [String]

    /// Style to use when indenting
    public let indentation: IndentationStyle

    /// The warning treshold, if some
    public let warningThreshold: Int?

    /// The reporter (xcode, json, csv, checkstyle)
    public let reporter: String

    /// The cache path, if some
    public let cachePath: String? // TODO: Is this needed ?!

    // MARK: Internal Instance
    internal var computedCacheDescription: String?
    internal var fileGraph: FileGraph?
    internal var rulesWrapper: RulesWrapper

    // MARK: - Initializers: Internal
    /// Initialize with all properties
    internal init(
        rulesWrapper: RulesWrapper,
        fileGraph: FileGraph?,
        includedPaths: [String],
        excludedPaths: [String],
        indentation: IndentationStyle,
        warningThreshold: Int?,
        reporter: String,
        cachePath: String?
    ) {
        self.rulesWrapper = rulesWrapper
        self.fileGraph = fileGraph
        self.includedPaths = includedPaths
        self.excludedPaths = excludedPaths
        self.indentation = indentation
        self.warningThreshold = warningThreshold
        self.reporter = reporter
        self.cachePath = cachePath
    }

    /// Initialize by copying a given configuration
    internal init(copying configuration: Configuration) {
        rulesWrapper = configuration.rulesWrapper
        fileGraph = configuration.fileGraph
        includedPaths = configuration.includedPaths
        excludedPaths = configuration.excludedPaths
        indentation = configuration.indentation
        warningThreshold = configuration.warningThreshold
        reporter = configuration.reporter
        cachePath = configuration.cachePath
    }

    /// Initialize with all properties,
    /// except that rules are still to be synthesized from rulesMode, ruleList & allRulesWithConfigurations
    /// and a check against the pinnedVersion is performed if given.
    internal init(
        rulesMode: RulesMode = .default(disabled: [], optIn: []),
        ruleList: RuleList = masterRuleList,
        allRulesWithConfigurations: [Rule]? = nil,
        fileGraph: FileGraph? = nil,
        includedPaths: [String] = [],
        excludedPaths: [String] = [],
        indentation: IndentationStyle = .default,
        warningThreshold: Int? = nil,
        reporter: String = XcodeReporter.identifier,
        cachePath: String? = nil,
        pinnedVersion: String? = nil
    ) {
        if let pinnedVersion = pinnedVersion, pinnedVersion != Version.current.value {
            queuedPrintError(
                "Currently running SwiftLint \(Version.current.value) but " +
                "configuration specified version \(pinnedVersion)."
            )
            exit(2)
        }

        self.init(
            rulesWrapper: RulesWrapper(
                mode: rulesMode,
                allRulesWithConfigurations: allRulesWithConfigurations ?? (try? ruleList.allRules()) ?? [],
                aliasResolver: { ruleList.identifier(for: $0) ?? $0 }
            ),
            fileGraph: fileGraph,
            includedPaths: includedPaths,
            excludedPaths: excludedPaths,
            indentation: indentation,
            warningThreshold: warningThreshold,
            reporter: reporter,
            cachePath: cachePath
        )
    }

    // MARK: Public
    /// Initialize with configuration files
    public init(
        configurationFiles: [String],
        rootPath: String? = nil,
        optional: Bool = true,
        quiet: Bool = false,
        enableAllRules: Bool = false,
        cachePath: String? = nil,
        ignoreParentAndChildConfigs: Bool = false
    ) {
        func rootDirectory(from rootPath: String?) -> String {
            var isDirectory: ObjCBool = false
            guard
                let rootPath = rootPath,
                FileManager.default.fileExists(atPath: rootPath, isDirectory: &isDirectory)
            else {
                return FileManager.default.currentDirectoryPath.bridge().standardizingPath
            }

            return isDirectory.boolValue ? rootPath : rootPath.bridge().deletingLastPathComponent
        }

        let rootDir = rootDirectory(from: rootPath)
        let rulesMode: RulesMode = enableAllRules ? .allEnabled : .default(disabled: [], optIn: [])
        let cacheIdentifier = "\(rootDir) - \(configurationFiles)"

        if let cachedConfig = Configuration.getCached(forIdentifier: cacheIdentifier) {
            self.init(copying: cachedConfig)
        }

        do {
            var fileGraph = FileGraph(
                commandLineChildConfigs: configurationFiles,
                rootDirectory: rootDir,
                ignoreParentAndChildConfigs: ignoreParentAndChildConfigs
            )
            let resultingConfiguration = try fileGraph.resultingConfiguration(
                configurationFactory: {
                    try Configuration(dict: $0, enableAllRules: enableAllRules, cachePath: cachePath)
                },
                remoteConfigLoadingTimeout: 2,
                remoteConfigLoadingTimeoutIfCached: 1
            )

            self.init(copying: resultingConfiguration)
            self.fileGraph = fileGraph
            setCached(forIdentifier: cacheIdentifier)
        } catch {
            let errorString: String
            switch error {
            case let ConfigurationError.generic(message):
                errorString = "SwiftLint Configuration Error: \(message)"

            case let YamlParserError.yamlParsing(message):
                errorString = "YML Parsing Error: \(message)"

            default:
                errorString = "Unknown Error"
            }

            guard optional else {
                queuedPrintError("error: \(errorString)")
                queuedFatalError("Could not read configuration")
            }

            // Fallback to default config (with custom rules mode)
            queuedPrintError("warning: \(errorString) – Falling back to default Configuration")
            self.init(rulesMode: rulesMode, cachePath: cachePath)
        }
    }
}

// MARK: - Hashable
extension Configuration: Hashable { // TODO
    public func hash(into hasher: inout Hasher) {
        hasher.combine(cachePath)
        hasher.combine(includedPaths)
        hasher.combine(excludedPaths)
        hasher.combine(reporter)
        hasher.combine(fileGraph)
    }

    public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        return lhs.warningThreshold == rhs.warningThreshold &&
            lhs.reporter == rhs.reporter &&
            lhs.cachePath == rhs.cachePath &&
            lhs.includedPaths == rhs.includedPaths &&
            lhs.excludedPaths == rhs.excludedPaths &&
            lhs.rules == rhs.rules &&
            lhs.indentation == rhs.indentation &&
            lhs.fileGraph == rhs.fileGraph
    }
}

// MARK: - CustomStringConvertible
extension Configuration: CustomStringConvertible {
    public var description: String {
        return "Configuration: \n"
            + "- Indentation Style: \(indentation)\n"
            + "- Included: \(includedPaths)\n"
            + "- Excluded: \(excludedPaths)\n"
            + "- Warning Treshold: \(warningThreshold as Optional)\n"
            + "- Root Directory: \(rootDirectory as Optional)\n"
            + "- Reporter: \(reporter)\n"
            + "- Cache Path: \(cachePath as Optional)\n"
            + "- Computed Cache Description: \(computedCacheDescription as Optional)\n"
            + "- Rules: \(rules.map { type(of: $0).description.identifier })"
    }
}
