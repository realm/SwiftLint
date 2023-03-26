import Foundation
import SourceKittenFramework

/// The configuration struct for SwiftLint. User-defined in the `.swiftlint.yml` file, drives the behavior of SwiftLint.
public struct Configuration {
    // MARK: - Properties: Static
    /// The default Configuration resulting from an empty configuration file.
    public static var `default`: Configuration {
        // This is realized via a getter to account for differences of the current working directory
        Self()
    }

    /// The default file name to look for user-defined configurations.
    public static let defaultFileName = ".swiftlint.yml"

    // MARK: Public Instance
    /// The paths that should be included when linting
    public private(set) var includedPaths: [String]

    /// The paths that should be excluded when linting
    public private(set) var excludedPaths: [String]

    /// The style to use when indenting Swift source code.
    public let indentation: IndentationStyle

    /// The threshold for the number of warnings to tolerate before treating the lint as having failed.
    public let warningThreshold: Int?

    /// The identifier for the `Reporter` to use to report style violations.
    public let reporter: String

    /// The location of the persisted cache to use with this configuration.
    public let cachePath: String?

    /// Allow or disallow SwiftLint to exit successfully when passed only ignored or unlintable files.
    public let allowZeroLintableFiles: Bool

    /// This value is `true` iff the `--config` parameter was used to specify (a) configuration file(s)
    /// In particular, this means that the value is also `true` if the `--config` parameter
    /// was used to explicitly specify the default `.swiftlint.yml` as the configuration file
    public private(set) var basedOnCustomConfigurationFiles = false

    // MARK: Public Computed
    /// All rules enabled in this configuration
    public var rules: [Rule] { rulesWrapper.resultingRules }

    /// The root directory is the directory that included & excluded paths relate to.
    /// By default, the root directory is the current working directory,
    /// but during some merging algorithms it may be used differently.
    /// The rootDirectory also serves as the stopping point when searching for nested configs along the file hierarchy.
    public var rootDirectory: String { fileGraph.rootDirectory }

    /// The rules mode used for this configuration.
    public var rulesMode: RulesMode { rulesWrapper.mode }

    // MARK: Internal Instance
    internal var fileGraph: FileGraph
    internal private(set) var rulesWrapper: RulesWrapper
    internal var computedCacheDescription: String?

    // MARK: - Initializers: Internal
    /// Initialize with all properties
    internal init(
        rulesWrapper: RulesWrapper,
        fileGraph: FileGraph,
        includedPaths: [String],
        excludedPaths: [String],
        indentation: IndentationStyle,
        warningThreshold: Int?,
        reporter: String,
        cachePath: String?,
        allowZeroLintableFiles: Bool
    ) {
        self.rulesWrapper = rulesWrapper
        self.fileGraph = fileGraph
        self.includedPaths = includedPaths
        self.excludedPaths = excludedPaths
        self.indentation = indentation
        self.warningThreshold = warningThreshold
        self.reporter = reporter
        self.cachePath = cachePath
        self.allowZeroLintableFiles = allowZeroLintableFiles
    }

    /// Creates a Configuration by copying an existing configuration.
    ///
    /// - parameter copying:    The existing configuration to copy.
    internal init(copying configuration: Configuration) {
        rulesWrapper = configuration.rulesWrapper
        fileGraph = configuration.fileGraph
        includedPaths = configuration.includedPaths
        excludedPaths = configuration.excludedPaths
        indentation = configuration.indentation
        warningThreshold = configuration.warningThreshold
        reporter = configuration.reporter
        basedOnCustomConfigurationFiles = configuration.basedOnCustomConfigurationFiles
        cachePath = configuration.cachePath
        allowZeroLintableFiles = configuration.allowZeroLintableFiles
    }

    /// Creates a `Configuration` by specifying its properties directly,
    /// except that rules are still to be synthesized from rulesMode, ruleList & allRulesWrapped
    /// and a check against the pinnedVersion is performed if given.
    ///
    /// - parameter rulesMode:              The `RulesMode` for this configuration.
    /// - parameter allRulesWrapped:        The rules with their own configurations already applied.
    /// - parameter ruleList:               The list of all rules. Used for alias resolving and as a fallback
    ///                                     if `allRulesWrapped` is nil.
    /// - parameter filePath                The underlaying file graph. If `nil` is specified, a empty file graph
    ///                                     with the current working directory as the `rootDirectory` will be used
    /// - parameter includedPaths:          Included paths to lint.
    /// - parameter excludedPaths:          Excluded paths to not lint.
    /// - parameter indentation:            The style to use when indenting Swift source code.
    /// - parameter warningThreshold:       The threshold for the number of warnings to tolerate before treating the
    ///                                     lint as having failed.
    /// - parameter reporter:               The identifier for the `Reporter` to use to report style violations.
    /// - parameter cachePath:              The location of the persisted cache to use whith this configuration.
    /// - parameter pinnedVersion:          The SwiftLint version defined in this configuration.
    /// - parameter allowZeroLintableFiles: Allow SwiftLint to exit successfully when passed ignored or unlintable files
    @_spi(TestHelper)
    public init(
        rulesMode: RulesMode = .default(disabled: [], optIn: []),
        allRulesWrapped: [ConfigurationRuleWrapper]? = nil,
        ruleList: RuleList = primaryRuleList,
        fileGraph: FileGraph? = nil,
        includedPaths: [String] = [],
        excludedPaths: [String] = [],
        indentation: IndentationStyle = .default,
        warningThreshold: Int? = nil,
        reporter: String = XcodeReporter.identifier,
        cachePath: String? = nil,
        pinnedVersion: String? = nil,
        allowZeroLintableFiles: Bool = false
    ) {
        if let pinnedVersion, pinnedVersion != Version.current.value {
            queuedPrintError(
                "Currently running SwiftLint \(Version.current.value) but " +
                "configuration specified version \(pinnedVersion)."
            )
            exit(2)
        }

        self.init(
            rulesWrapper: RulesWrapper(
                mode: rulesMode,
                allRulesWrapped: allRulesWrapped ?? (try? ruleList.allRulesWrapped()) ?? [],
                aliasResolver: { ruleList.identifier(for: $0) ?? $0 }
            ),
            fileGraph: fileGraph ?? FileGraph(
                rootDirectory: FileManager.default.currentDirectoryPath.bridge().absolutePathStandardized()
            ),
            includedPaths: includedPaths,
            excludedPaths: excludedPaths,
            indentation: indentation,
            warningThreshold: warningThreshold,
            reporter: reporter,
            cachePath: cachePath,
            allowZeroLintableFiles: allowZeroLintableFiles
        )
    }

    // MARK: Public
    /// Creates a `Configuration` with convenience parameters.
    ///
    /// - parameter configurationFiles:         The path on disk to one or multiple configuration files. If this array
    ///                                         is empty, the default `.swiftlint.yml` file will be used.
    /// - parameter enableAllRules:             Enable all available rules.
    /// - parameter cachePath:                  The location of the persisted cache to use whith this configuration.
    /// - parameter ignoreParentAndChildConfigs:If `true`, child and parent config references will be ignored.
    /// - parameter mockedNetworkResults:       For testing purposes only. Instead of loading the specified urls,
    ///                                         the mocked value will be used. Example: ["http://mock.com": "content"]
    /// - parameter useDefaultConfigOnFailure:  If this value is specified, it will override the normal behavior.
    ///                                         This is only intended for tests checking whether invalid configs fail.
    public init(
        configurationFiles: [String], // No default value here to avoid ambiguous Configuration() initializer
        enableAllRules: Bool = false,
        cachePath: String? = nil,
        ignoreParentAndChildConfigs: Bool = false,
        mockedNetworkResults: [String: String] = [:],
        useDefaultConfigOnFailure: Bool? = nil // swiftlint:disable:this discouraged_optional_boolean
    ) {
        // Handle mocked network results if needed
        Self.FileGraph.FilePath.mockedNetworkResults = mockedNetworkResults
        defer {
            if !mockedNetworkResults.isEmpty {
                Self.FileGraph.FilePath.deleteGitignoreAndSwiftlintCache()
            }
        }

        // Store whether there are custom configuration files; use default config file name if there are none
        let hasCustomConfigurationFiles: Bool = configurationFiles.isNotEmpty
        let configurationFiles = configurationFiles.isEmpty ? [Self.defaultFileName] : configurationFiles
        defer { basedOnCustomConfigurationFiles = hasCustomConfigurationFiles }

        let currentWorkingDirectory = FileManager.default.currentDirectoryPath.bridge().absolutePathStandardized()
        let rulesMode: RulesMode = enableAllRules ? .allEnabled : .default(disabled: [], optIn: [])

        // Try obtaining cached config
        let cacheIdentifier = "\(currentWorkingDirectory) - \(configurationFiles)"
        if let cachedConfig = Self.getCached(forIdentifier: cacheIdentifier) {
            self.init(copying: cachedConfig)
            return
        }

        // Try building configuration via the file graph
        do {
            var fileGraph = FileGraph(
                commandLineChildConfigs: configurationFiles,
                rootDirectory: currentWorkingDirectory,
                ignoreParentAndChildConfigs: ignoreParentAndChildConfigs
            )
            let resultingConfiguration = try fileGraph.resultingConfiguration(
                enableAllRules: enableAllRules,
                cachePath: cachePath
            )

            self.init(copying: resultingConfiguration)
            self.fileGraph = fileGraph
            setCached(forIdentifier: cacheIdentifier)
        } catch {
            let errorString: String
            let initializationResult = FileGraphInitializationResult(
                error: error, hasCustomConfigurationFiles: hasCustomConfigurationFiles
            )
            switch initializationResult {
            case .initialImplicitFileNotFound:
                // Silently fall back to default
                self.init(rulesMode: rulesMode, cachePath: cachePath)
                return
            case .error(let message):
                errorString = message
            }

            if useDefaultConfigOnFailure ?? !hasCustomConfigurationFiles {
                // No files were explicitly specified, so maybe the user doesn't want a config at all -> warn
                queuedPrintError("warning: \(errorString) – Falling back to default configuration")
                self.init(rulesMode: rulesMode, cachePath: cachePath)
            } else {
                // Files that were explicitly specified could not be loaded -> fail
                queuedPrintError("error: \(errorString)")
                queuedFatalError("Could not read configuration")
            }
        }
    }

    // MARK: - Methods: Internal
    mutating func makeIncludedAndExcludedPaths(relativeTo newBasePath: String, previousBasePath: String) {
        includedPaths = includedPaths.map {
            $0.bridge().absolutePathRepresentation(rootDirectory: previousBasePath).path(relativeTo: newBasePath)
        }

        excludedPaths = excludedPaths.map {
            $0.bridge().absolutePathRepresentation(rootDirectory: previousBasePath).path(relativeTo: newBasePath)
        }
    }
}

// MARK: - FileGraphInitializationResult
private enum FileGraphInitializationResult {
    case initialImplicitFileNotFound
    case error(message: String)

    init(error: Error, hasCustomConfigurationFiles: Bool) {
        switch error {
        case let ConfigurationError.initialFileNotFound(path):
            if hasCustomConfigurationFiles {
                self = .error(message: "SwiftLint Configuration Error: Could not read file at path: \(path)")
            } else {
                // The initial configuration file wasn't found, but the user didn't explicitly specify one
                // -> don't handle as error
                self = .initialImplicitFileNotFound
            }
        case let ConfigurationError.generic(message):
            self = .error(message: "SwiftLint Configuration Error: \(message)")
        case let YamlParserError.yamlParsing(message):
            self = .error(message: "YML Parsing Error: \(message)")
        default:
            self = .error(message: error.localizedDescription)
        }
    }
}

// MARK: - Hashable
extension Configuration: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(includedPaths)
        hasher.combine(excludedPaths)
        hasher.combine(indentation)
        hasher.combine(warningThreshold)
        hasher.combine(reporter)
        hasher.combine(allowZeroLintableFiles)
        hasher.combine(basedOnCustomConfigurationFiles)
        hasher.combine(cachePath)
        hasher.combine(rules.map { type(of: $0).description.identifier })
        hasher.combine(fileGraph)
    }

    public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        return lhs.includedPaths == rhs.includedPaths &&
            lhs.excludedPaths == rhs.excludedPaths &&
            lhs.indentation == rhs.indentation &&
            lhs.warningThreshold == rhs.warningThreshold &&
            lhs.reporter == rhs.reporter &&
            lhs.basedOnCustomConfigurationFiles == rhs.basedOnCustomConfigurationFiles &&
            lhs.cachePath == rhs.cachePath &&
            lhs.rules == rhs.rules &&
            lhs.fileGraph == rhs.fileGraph &&
            lhs.allowZeroLintableFiles == rhs.allowZeroLintableFiles
    }
}

// MARK: - CustomStringConvertible
extension Configuration: CustomStringConvertible {
    public var description: String {
        return "Configuration: \n"
            + "- Indentation Style: \(indentation)\n"
            + "- Included Paths: \(includedPaths)\n"
            + "- Excluded Paths: \(excludedPaths)\n"
            + "- Warning Threshold: \(warningThreshold as Optional)\n"
            + "- Root Directory: \(rootDirectory as Optional)\n"
            + "- Reporter: \(reporter)\n"
            + "- Cache Path: \(cachePath as Optional)\n"
            + "- Computed Cache Description: \(computedCacheDescription as Optional)\n"
            + "- Rules: \(rules.map { type(of: $0).description.identifier })"
    }
}
