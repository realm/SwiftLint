/// Type-erased protocol used to check whether a rule is collectable.
public protocol AnyCollectingRule: Rule { }

/// A rule that requires knowledge of all other files being linted.
public protocol CollectingRule: AnyCollectingRule {
    /// The kind of information to collect for each file being linted for this rule.
    associatedtype FileInfo

    /// Collects information for the specified file, to be analyzed by a `CollectedLinter`.
    ///
    /// - parameter file:              The file for which to collect info.
    /// - parameter compilerArguments: The compiler arguments needed to compile this file.
    ///
    /// - returns: The collected file information.
    func collectInfo(for file: SwiftLintFile, compilerArguments: [String]) -> FileInfo

    /// Collects information for the specified file, to be analyzed by a `CollectedLinter`.
    ///
    /// - parameter file: The file for which to collect info.
    ///
    /// - returns: The collected file information.
    func collectInfo(for file: SwiftLintFile) -> FileInfo

    /// Executes the rule on a file after collecting file info for all files and returns any violations to the rule's
    /// expectations.
    ///
    /// - parameter file:              The file for which to execute the rule.
    /// - parameter collectedInfo:     All collected info for all files.
    /// - parameter compilerArguments: The compiler arguments needed to compile this file.
    ///
    /// - returns: All style violations to the rule's expectations.
    func validate(file: SwiftLintFile,
                  collectedInfo: [SwiftLintFile: FileInfo],
                  compilerArguments: [String]) -> [StyleViolation]

    /// Executes the rule on a file after collecting file info for all files and returns any violations to the rule's
    /// expectations.
    ///
    /// - parameter file:          The file for which to execute the rule.
    /// - parameter collectedInfo: All collected info for all files.
    ///
    /// - returns: All style violations to the rule's expectations.
    func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: FileInfo]) -> [StyleViolation]
}

// MARK: - == Implementations

public extension CollectingRule {
    func collectInfo(for file: SwiftLintFile, into storage: RuleStorage, compilerArguments: [String]) {
        storage.collect(info: collectInfo(for: file, compilerArguments: compilerArguments),
                        for: file, in: self)
    }
    func validate(file: SwiftLintFile, using storage: RuleStorage, compilerArguments: [String]) -> [StyleViolation] {
        guard let info = storage.collectedInfo(for: self) else {
            queuedFatalError("Attempt to validate a CollectingRule before collecting info for it")
        }
        return validate(file: file, collectedInfo: info, compilerArguments: compilerArguments)
    }
    func collectInfo(for file: SwiftLintFile, compilerArguments _: [String]) -> FileInfo {
        collectInfo(for: file)
    }

    func validate(file: SwiftLintFile,
                  collectedInfo: [SwiftLintFile: FileInfo],
                  compilerArguments _: [String]) -> [StyleViolation] {
        validate(file: file, collectedInfo: collectedInfo)
    }
    func validate(file _: SwiftLintFile) -> [StyleViolation] {
        queuedFatalError("Must call `validate(file:collectedInfo:)` for CollectingRule")
    }
    func validate(file _: SwiftLintFile, compilerArguments _: [String]) -> [StyleViolation] {
        queuedFatalError("Must call `validate(file:collectedInfo:compilerArguments:)` for CollectingRule")
    }
}

public extension CollectingRule where Self: AnalyzerRule {
    func collectInfo(for _: SwiftLintFile) -> FileInfo {
        queuedFatalError(
            "Must call `collect(infoFor:compilerArguments:)` for AnalyzerRule & CollectingRule"
        )
    }
    func validate(file _: SwiftLintFile) -> [StyleViolation] {
        queuedFatalError(
            "Must call `validate(file:collectedInfo:compilerArguments:)` for AnalyzerRule & CollectingRule"
        )
    }
    func validate(file _: SwiftLintFile, collectedInfo _: [SwiftLintFile: FileInfo]) -> [StyleViolation] {
        queuedFatalError(
            "Must call `validate(file:collectedInfo:compilerArguments:)` for AnalyzerRule & CollectingRule"
        )
    }
}

/// :nodoc:
public extension Array where Element == any Rule {
    static func == (lhs: Array, rhs: Array) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }
        return !zip(lhs, rhs).contains { pair in
            let first = pair.0, second = pair.1
            return !first.isEqualTo(second)
        }
    }
}
