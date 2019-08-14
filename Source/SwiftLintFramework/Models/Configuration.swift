import Foundation
import SourceKittenFramework

public struct Configuration: Hashable {
    // MARK: - Properties
    public static let fileName = ".swiftlint.yml"

    public let indentation: IndentationStyle           // style to use when indenting
    public let included: [String]                      // included
    public let excluded: [String]                      // excluded
    public let reporter: String                        // reporter (xcode, json, csv, checkstyle)
    public let warningThreshold: Int?                  // warning threshold
    public private(set) var rootPath: String?          // the root path to search for nested configurations
    public private(set) var configurationPath: String? // if successfully loaded from a path
    public let cachePath: String?

    internal var computedCacheDescription: String?

    class ConfigurationWrapper { var wrapped: Configuration? }
    private var unmergedSubConfig = ConfigurationWrapper()

    // MARK: Rules Properties
    public var rulesStorage: RulesStorage

    /// Shortcut for rulesStorage.resultingRules
    public var rules: [Rule] { return rulesStorage.resultingRules }

    // MARK: - Initializers
    /// Initialize with all properties.
    internal init(
        rulesStorage: RulesStorage,
        included: [String],
        excluded: [String],
        warningThreshold: Int?,
        reporter: String,
        cachePath: String?,
        rootPath: String?,
        indentation: IndentationStyle
    ) {
        self.rulesStorage = rulesStorage
        self.included = included
        self.excluded = excluded
        self.warningThreshold = warningThreshold
        self.reporter = reporter
        self.cachePath = cachePath
        self.rootPath = rootPath
        self.indentation = indentation
    }

    /// Initialize by copying a given configuration
    private init(copying configuration: Configuration) {
        rulesStorage = configuration.rulesStorage
        included = configuration.included
        excluded = configuration.excluded
        warningThreshold = configuration.warningThreshold
        reporter = configuration.reporter
        cachePath = configuration.cachePath
        rootPath = configuration.rootPath
        indentation = configuration.indentation
    }

    /// Initialize with all properties,
    /// except that rulesStorage is still to be synthesized from rulesMode, ruleList & allRulesWithConfigurations
    /// and a check against the pinnedVersion is performed if given.
    public init(
        rulesMode: RulesStorage.Mode = .default(disabled: [], optIn: []),
        ruleList: RuleList = masterRuleList,
        allRulesWithConfigurations: [Rule]? = nil,
        pinnedVersion: String? = nil,
        included: [String] = [],
        excluded: [String] = [],
        warningThreshold: Int? = nil,
        reporter: String = XcodeReporter.identifier,
        cachePath: String? = nil,
        rootPath: String? = nil,
        indentation: IndentationStyle = .default
    ) {
        if let pinnedVersion = pinnedVersion, pinnedVersion != Version.current.value {
            queuedPrintError("Currently running SwiftLint \(Version.current.value) but " +
                "configuration specified version \(pinnedVersion).")
            exit(2)
        }

        let rulesStorage = RulesStorage(
            mode: rulesMode,
            allRulesWithConfigurations: allRulesWithConfigurations ?? (try? ruleList.allRules()) ?? [],
            aliasResolver: { ruleList.identifier(for: $0) ?? $0 }
        )

        self.init(
            rulesStorage: rulesStorage,
            included: included,
            excluded: excluded,
            warningThreshold: warningThreshold,
            reporter: reporter,
            cachePath: cachePath,
            rootPath: rootPath,
            indentation: indentation
        )
    }

    /// Initialize based on a path to a configuration file.
    public init(
        path: String, // This does not have a default value, so that Configuration() isn't confused with this init
        rootPath: String? = nil,
        optional: Bool = true,
        quiet: Bool = false,
        enableAllRules: Bool = false,
        cachePath: String? = nil,
        isSubConfig: Bool = false,
        subConfigPreviousPaths: [String] = []
    ) {
        let fullPath: String
        if let rootPath = rootPath, rootPath.isDirectory() {
            fullPath = path.bridge().absolutePathRepresentation(rootDirectory: rootPath)
        } else {
            fullPath = path.bridge().absolutePathRepresentation()
        }

        if let cachedConfig = Configuration.getCached(atPath: fullPath) {
            self.init(copying: cachedConfig)
            configurationPath = fullPath
            return
        }

        let fail = { (msg: String) in
            queuedPrintError("\(fullPath):\(msg)")
            queuedFatalError("Could not read configuration file at path '\(fullPath)'")
        }
        let rulesMode: RulesStorage.Mode = enableAllRules ? .allEnabled : .default(disabled: [], optIn: [])
        if path.isEmpty || !FileManager.default.fileExists(atPath: fullPath) {
            if !optional { fail("File not found.") }
            self.init(rulesMode: rulesMode, cachePath: cachePath)
            self.rootPath = rootPath
            return
        }
        do {
            let yamlContents = try String(contentsOfFile: fullPath, encoding: .utf8)
            let dict = try YamlParser.parse(yamlContents)
            if !quiet {
                queuedPrintError("Loading configuration from '\(path)'")
            }
            self.init(dict: dict, enableAllRules: enableAllRules,
                      cachePath: cachePath)!

            // Merge sub config if needed
            if let subConfigFile = dict[Key.subConfig.rawValue] as? String {
                merge(
                    subConfigFile: subConfigFile, currentFilePath: fullPath, quiet: quiet,
                    isSubConfig: isSubConfig, subConfigPreviousPaths: subConfigPreviousPaths
                )
            }

            configurationPath = fullPath
            self.rootPath = rootPath
            setCached(atPath: fullPath)
            return
        } catch YamlParserError.yamlParsing(let message) {
            fail(message)
        } catch {
            fail("\(error)")
        }
        self.init(rulesMode: rulesMode, cachePath: cachePath)
        setCached(atPath: fullPath)
    }

    // MARK: - Methods
    public func hash(into hasher: inout Hasher) {
        if let configurationPath = configurationPath {
            hasher.combine(configurationPath)
        } else if let rootPath = rootPath {
            hasher.combine(rootPath)
        } else if let cachePath = cachePath {
            hasher.combine(cachePath)
        } else {
            hasher.combine(included)
            hasher.combine(excluded)
            hasher.combine(reporter)
        }
    }

    private mutating func merge(
        subConfigFile: String,
        currentFilePath: String,
        quiet: Bool,
        isSubConfig: Bool,
        subConfigPreviousPaths: [String]
    ) {
        let fail = { (message: String, severity: ViolationSeverity) in
            var overallMessage: String
            if let firstSubConfigFilePath = subConfigPreviousPaths.first {
                // Print entire stack of config file references
                overallMessage = "\(severity.rawValue): Issue reading `sub_config` file ('\(currentFilePath)')"
                    + subConfigPreviousPaths.dropFirst().reversed().reduce("") {
                        $0 + " originating from `sub_config` file ('\($1)')"
                    }
                    + " originating from main config file ('\(firstSubConfigFilePath)')"
            } else {
                overallMessage = "\(severity.rawValue): Issue reading configuration file ('\(currentFilePath))')"
            }

            overallMessage += ": \(message)"

            if severity == .error {
                queuedFatalError(overallMessage)
            } else {
                queuedPrintError(overallMessage)
            }
        }

        let subConfigPath = currentFilePath.bridge().deletingLastPathComponent
            .bridge().appendingPathComponent(subConfigFile)

        if subConfigFile.contains("/") {
            return fail("The file specified as `sub_config` must be on the same level as the base config file", .error)
        } else if !FileManager.default.fileExists(atPath: subConfigPath) {
            fail("Unable to find file specified as `sub_config` (\(subConfigPath))", .warning)
        } else if subConfigPreviousPaths.contains(subConfigPath) { // Avoid cyclomatic references
            let cycleDescription = (subConfigPreviousPaths + [currentFilePath, subConfigPath]).map {
                $0.bridge().lastPathComponent
            }.reduce("") { $0 + " => " + $1 }.dropFirst(4)
            return fail("Invalid cycle of `sub_config` references: \(cycleDescription)", .error)
        } else {
            unmergedSubConfig.wrapped = Configuration(
                path: subConfigPath,
                rootPath: rootPath,
                optional: false,
                quiet: quiet,
                isSubConfig: true,
                subConfigPreviousPaths: subConfigPreviousPaths + [currentFilePath]
            )
        }

        // Let the topmost configuration do the merging in the end
        // This results in a semantically correct ((A <- B) <- C) merge, instead of a wrong (A <- (B <- C)) merge
        if !isSubConfig {
            func mergeUnmergedSubconfigs(of subConfig: Configuration, into primaryConfig: inout Configuration) {
                if let unmergedSubConfig = subConfig.unmergedSubConfig.wrapped {
                    subConfig.unmergedSubConfig.wrapped = nil
                    primaryConfig = primaryConfig.merged(with: unmergedSubConfig)
                    mergeUnmergedSubconfigs(of: unmergedSubConfig, into: &primaryConfig)
                }
            }

            mergeUnmergedSubconfigs(of: self, into: &self)
        }
    }

    // MARK: Equatable
    public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        return (lhs.warningThreshold == rhs.warningThreshold) &&
            (lhs.reporter == rhs.reporter) &&
            (lhs.rootPath == rhs.rootPath) &&
            (lhs.configurationPath == rhs.configurationPath) &&
            (lhs.cachePath == rhs.cachePath) &&
            (lhs.included == rhs.included) &&
            (lhs.excluded == rhs.excluded) &&
            (lhs.rules == rhs.rules) &&
            (lhs.indentation == rhs.indentation)
    }
}

private extension String {
    func isDirectory() -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: self, isDirectory: &isDir) {
            return isDir.boolValue
        }

        return false
    }
}

extension Configuration: CustomStringConvertible {
    public var description: String {
        return "Configuration: \n"
            + "- Indentation Style: \(indentation)\n"
            + "- Included: \(included)\n"
            + "- Excluded: \(excluded)\n"
            + "- Warning Treshold: \(warningThreshold as Optional)\n"
            + "- Root Path: \(rootPath as Optional)\n"
            + "- Configuration Path: \(configurationPath as Optional)\n"
            + "- Reporter: \(reporter)\n"
            + "- Cache Path: \(cachePath as Optional)\n"
            + "- Computed Cache Description: \(computedCacheDescription as Optional)\n"
            + "- Rules: \(rules.map { type(of: $0).description.identifier })"
    }
}
