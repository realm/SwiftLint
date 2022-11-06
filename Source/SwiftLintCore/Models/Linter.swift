import Foundation
import SourceKittenFramework

private let warnSourceKitFailedOnceImpl: Void = {
    queuedPrintError("SourceKit-based rules will be skipped because sourcekitd has failed.")
}()

private func warnSourceKitFailedOnce() {
    _ = warnSourceKitFailedOnceImpl
}

private struct LintResult {
    let violations: [StyleViolation]
    let ruleTime: (id: String, time: Double)?
    let deprecatedToValidIDPairs: [(String, String)]
}

private extension Rule {
    static func superfluousDisableCommandViolations(regions: [Region],
                                                    superfluousDisableCommandRule: SuperfluousDisableCommandRule?,
                                                    allViolations: [StyleViolation]) -> [StyleViolation] {
        guard regions.isNotEmpty, let superfluousDisableCommandRule = superfluousDisableCommandRule else {
            return []
        }

        let regionsDisablingCurrentRule = regions.filter { region in
            return region.isRuleDisabled(self.init())
        }
        let regionsDisablingSuperfluousDisableRule = regions.filter { region in
            return region.isRuleDisabled(superfluousDisableCommandRule)
        }

        return regionsDisablingCurrentRule.compactMap { region -> StyleViolation? in
            let isSuperfluousRuleDisabled = regionsDisablingSuperfluousDisableRule.contains {
                $0.contains(region.start)
            }

            guard !isSuperfluousRuleDisabled else {
                return nil
            }

            let noViolationsInDisabledRegion = !allViolations.contains { violation in
                return region.contains(violation.location)
            }
            guard noViolationsInDisabledRegion else {
                return nil
            }

            return StyleViolation(
                ruleDescription: type(of: superfluousDisableCommandRule).description,
                severity: superfluousDisableCommandRule.configuration.severity,
                location: region.start,
                reason: superfluousDisableCommandRule.reason(for: self)
            )
        }
    }

    // As we need the configuration to get custom identifiers.
    // swiftlint:disable:next function_parameter_count
    func lint(file: SwiftLintFile, regions: [Region], benchmark: Bool,
              storage: RuleStorage,
              configuration: Configuration,
              superfluousDisableCommandRule: SuperfluousDisableCommandRule?,
              compilerArguments: [String]) -> LintResult? {
        // Empty files shouldn't trigger violations
        guard !file.isEmpty, SwiftVersion.current >= Self.description.minSwiftVersion else {
            return nil
        }

        if !(self is SourceKitFreeRule) && file.sourcekitdFailed {
            warnSourceKitFailedOnce()
            return nil
        }

        let ruleID = Self.description.identifier

        let violations: [StyleViolation]
        let ruleTime: (String, Double)?
        if benchmark {
            let start = Date()
            violations = validate(file: file, using: storage, compilerArguments: compilerArguments)
            ruleTime = (ruleID, -start.timeIntervalSinceNow)
        } else {
            violations = validate(file: file, using: storage, compilerArguments: compilerArguments)
            ruleTime = nil
        }

        let (disabledViolationsAndRegions, enabledViolationsAndRegions) = violations.map { violation in
            return (violation, regions.first { $0.contains(violation.location) })
        }.partitioned { _, region in
            return region?.isRuleEnabled(self) ?? true
        }

        let ruleIDs = Self.description.allIdentifiers +
            (superfluousDisableCommandRule.map({ type(of: $0) })?.description.allIdentifiers ?? []) +
            [RuleIdentifier.all.stringRepresentation]
        let ruleIdentifiers = Set(ruleIDs.map { RuleIdentifier($0) })

        let superfluousDisableCommandViolations = Self.superfluousDisableCommandViolations(
            regions: regions.count > 1 ? file.regions(restrictingRuleIdentifiers: ruleIdentifiers) : regions,
            superfluousDisableCommandRule: superfluousDisableCommandRule,
            allViolations: violations
        )

        let enabledViolations: [StyleViolation]
        if file.contents.hasPrefix("#!") { // if a violation happens on the same line as a shebang, ignore it
            enabledViolations = enabledViolationsAndRegions.compactMap { violation, _ in
                if violation.location.line == 1 { return nil }
                return violation
            }
        } else {
            enabledViolations = enabledViolationsAndRegions.map { $0.0 }
        }
        let deprecatedToValidIDPairs = disabledViolationsAndRegions.flatMap { _, region -> [(String, String)] in
            let identifiers = region?.deprecatedAliasesDisabling(rule: self) ?? []
            return identifiers.map { ($0, ruleID) }
        }

        return LintResult(violations: enabledViolations + superfluousDisableCommandViolations,
                          ruleTime: ruleTime,
                          deprecatedToValidIDPairs: deprecatedToValidIDPairs)
    }
}

/// Represents a file that can be linted for style violations and corrections after being collected.
public struct Linter {
    /// The file to lint with this linter.
    public let file: SwiftLintFile
    /// Whether or not this linter will be used to collect information from several files.
    public var isCollecting: Bool
    fileprivate let rules: [Rule]
    fileprivate let cache: LinterCache?
    fileprivate let configuration: Configuration
    fileprivate let compilerArguments: [String]

    /// Creates a `Linter` by specifying its properties directly.
    ///
    /// - parameter file:              The file to lint with this linter.
    /// - parameter configuration:     The SwiftLint configuration to apply to this linter.
    /// - parameter cache:             The persisted cache to use for this linter.
    /// - parameter compilerArguments: The compiler arguments to use for this linter if it is to execute analyzer rules.
    public init(file: SwiftLintFile, configuration: Configuration = Configuration.default, cache: LinterCache? = nil,
                compilerArguments: [String] = []) {
        self.file = file
        self.cache = cache
        self.configuration = configuration
        self.compilerArguments = compilerArguments
        let rules = configuration.rules.filter { rule in
            if compilerArguments.isEmpty {
                return !(rule is AnalyzerRule)
            } else {
                return rule is AnalyzerRule
            }
        }
        self.rules = rules
        self.isCollecting = rules.contains(where: { $0 is AnyCollectingRule })
    }

    /// Returns a linter capable of checking for violations after running each rule's collection step.
    ///
    /// - parameter storage: The storage object where collected info should be saved.
    ///
    /// - returns: A linter capable of checking for violations after running each rule's collection step.
    public func collect(into storage: RuleStorage) -> CollectedLinter {
        DispatchQueue.concurrentPerform(iterations: rules.count) { idx in
            rules[idx].collectInfo(for: file, into: storage, compilerArguments: compilerArguments)
        }
        return CollectedLinter(from: self)
    }
}

/// Represents a file that can compute style violations and corrections for a list of rules.
///
/// A `CollectedLinter` is only created after a `Linter` has run its collection steps in `Linter.collect(into:)`.
public struct CollectedLinter {
    /// The file to lint with this linter.
    public let file: SwiftLintFile
    private let rules: [Rule]
    private let cache: LinterCache?
    private let configuration: Configuration
    private let compilerArguments: [String]

    fileprivate init(from linter: Linter) {
        file = linter.file
        rules = linter.rules
        cache = linter.cache
        configuration = linter.configuration
        compilerArguments = linter.compilerArguments
    }

    /// Computes or retrieves style violations.
    ///
    /// - parameter storage: The storage object containing all collected info.
    ///
    /// - returns: All style violations found by this linter.
    public func styleViolations(using storage: RuleStorage) -> [StyleViolation] {
        return getStyleViolations(using: storage).0
    }

    /// Computes or retrieves style violations and the time spent executing each rule.
    ///
    /// - parameter storage: The storage object containing all collected info.
    ///
    /// - returns: All style violations found by this linter, and the time spent executing each rule.
    public func styleViolationsAndRuleTimes(using storage: RuleStorage)
        -> ([StyleViolation], [(id: String, time: Double)]) {
            return getStyleViolations(using: storage, benchmark: true)
    }

    private func getStyleViolations(using storage: RuleStorage,
                                    benchmark: Bool = false) -> ([StyleViolation], [(id: String, time: Double)]) {
        guard !file.isEmpty else {
            // Empty files shouldn't trigger violations
            return ([], [])
        }

        if let cached = cachedStyleViolations(benchmark: benchmark) {
            return cached
        }

        let regions = file.regions()
        let superfluousDisableCommandRule = rules.first(where: {
            $0 is SuperfluousDisableCommandRule
        }) as? SuperfluousDisableCommandRule
        let validationResults = rules.parallelCompactMap {
            $0.lint(file: self.file, regions: regions, benchmark: benchmark,
                    storage: storage,
                    configuration: self.configuration,
                    superfluousDisableCommandRule: superfluousDisableCommandRule,
                    compilerArguments: self.compilerArguments)
        }
        let undefinedSuperfluousCommandViolations = self.undefinedSuperfluousCommandViolations(
            regions: regions, configuration: configuration,
            superfluousDisableCommandRule: superfluousDisableCommandRule)

        let violations = validationResults.flatMap { $0.violations } + undefinedSuperfluousCommandViolations
        let ruleTimes = validationResults.compactMap { $0.ruleTime }
        var deprecatedToValidIdentifier = [String: String]()
        for (key, value) in validationResults.flatMap({ $0.deprecatedToValidIDPairs }) {
            deprecatedToValidIdentifier[key] = value
        }

        if let cache = cache, let path = file.path {
            cache.cache(violations: violations, forFile: path, configuration: configuration)
        }

        for (deprecatedIdentifier, identifier) in deprecatedToValidIdentifier {
            queuedPrintError("'\(deprecatedIdentifier)' rule has been renamed to '\(identifier)' and will be " +
                "completely removed in a future release.")
        }

        // Free some memory used for this file's caches. They shouldn't be needed after this point.
        file.invalidateCache()

        return (violations, ruleTimes)
    }

    private func cachedStyleViolations(benchmark: Bool = false) -> ([StyleViolation], [(id: String, time: Double)])? {
        let start: Date! = benchmark ? Date() : nil
        guard let cache = cache, let file = file.path,
            let cachedViolations = cache.violations(forFile: file, configuration: configuration) else {
            return nil
        }

        var ruleTimes = [(id: String, time: Double)]()
        if benchmark {
            // let's assume that all rules should have the same duration and split the duration among them
            let totalTime = -start.timeIntervalSinceNow
            let fractionedTime = totalTime / TimeInterval(rules.count)
            ruleTimes = rules.compactMap { rule in
                let id = type(of: rule).description.identifier
                return (id, fractionedTime)
            }
        }

        return (cachedViolations, ruleTimes)
    }

    /// Applies corrections for all rules to this file, returning performed corrections.
    ///
    /// - parameter storage: The storage object containing all collected info.
    ///
    /// - returns: All corrections that were applied.
    public func correct(using storage: RuleStorage) -> [Correction] {
        if let violations = cachedStyleViolations()?.0, violations.isEmpty {
            return []
        }

        if let parserDiagnostics = file.parserDiagnostics, parserDiagnostics.isNotEmpty {
            queuedPrintError(
                "Skipping correcting file because it produced Swift parser errors: \(file.path ?? "<nopath>")"
            )
            queuedPrintError(toJSON(["diagnostics": parserDiagnostics]))
            return []
        }

        var corrections = [Correction]()
        for rule in rules.compactMap({ $0 as? CorrectableRule }) {
            let newCorrections = rule.correct(file: file, using: storage, compilerArguments: compilerArguments)
            corrections += newCorrections
            if newCorrections.isNotEmpty, !file.isVirtual {
                file.invalidateCache()
            }
        }
        return corrections
    }

    /// Formats the file associated with this linter.
    ///
    /// - parameter useTabs:     Should the file be formatted using tabs?
    /// - parameter indentWidth: How many spaces should be used per indentation level.
    public func format(useTabs: Bool, indentWidth: Int) {
        let formattedContents = try? file.file.format(trimmingTrailingWhitespace: true,
                                                      useTabs: useTabs,
                                                      indentWidth: indentWidth)
        if let formattedContents = formattedContents {
            file.write(formattedContents)
        }
    }

    private func undefinedSuperfluousCommandViolations(regions: [Region],
                                                       configuration: Configuration,
                                                       superfluousDisableCommandRule: SuperfluousDisableCommandRule?
        ) -> [StyleViolation] {
        guard regions.isNotEmpty, let superfluousDisableCommandRule = superfluousDisableCommandRule else {
            return []
        }

        let allCustomIdentifiers =
            (configuration.rules.first { $0 is CustomRules } as? CustomRules)?
            .configuration.customRuleConfigurations.map { RuleIdentifier($0.identifier) } ?? []
        let allRuleIdentifiers = RuleRegistry.shared.list.allValidIdentifiers().map { RuleIdentifier($0) }
        let allValidIdentifiers = Set(allCustomIdentifiers + allRuleIdentifiers + [.all])

        return regions.flatMap { region in
            region.disabledRuleIdentifiers.filter({ !allValidIdentifiers.contains($0) }).map { id in
                return StyleViolation(
                    ruleDescription: type(of: superfluousDisableCommandRule).description,
                    severity: superfluousDisableCommandRule.configuration.severity,
                    location: region.start,
                    reason: superfluousDisableCommandRule.reason(forNonExistentRule: id.stringRepresentation)
                )
            }
        }
    }
}

private extension SwiftLintFile {
    var isEmpty: Bool {
        contents.isEmpty || contents == "\n"
    }
}
