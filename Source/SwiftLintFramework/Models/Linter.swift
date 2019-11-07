import Foundation
import SourceKittenFramework

private struct LintResult {
    let violations: [StyleViolation]
    let ruleTime: (id: String, time: Double)?
    let deprecatedToValidIDPairs: [(String, String)]
}

private extension Rule {
    static func superfluousDisableCommandViolations(regions: [Region],
                                                    superfluousDisableCommandRule: SuperfluousDisableCommandRule?,
                                                    allViolations: [StyleViolation]) -> [StyleViolation] {
        guard !regions.isEmpty, let superfluousDisableCommandRule = superfluousDisableCommandRule else {
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
        if !(self is SourceKitFreeRule) && file.sourcekitdFailed {
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
    public let file: SwiftLintFile
    public var isCollecting: Bool
    fileprivate let rules: [Rule]
    fileprivate let cache: LinterCache?
    fileprivate let configuration: Configuration
    fileprivate let compilerArguments: [String]

    public init(file: SwiftLintFile, configuration: Configuration = Configuration()!, cache: LinterCache? = nil,
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

    public func styleViolations(using storage: RuleStorage) -> [StyleViolation] {
        return getStyleViolations(using: storage).0
    }

    public func styleViolationsAndRuleTimes(using storage: RuleStorage)
        -> ([StyleViolation], [(id: String, time: Double)]) {
            return getStyleViolations(using: storage, benchmark: true)
    }

    private func getStyleViolations(using storage: RuleStorage,
                                    benchmark: Bool = false) -> ([StyleViolation], [(id: String, time: Double)]) {
        if let cached = cachedStyleViolations(benchmark: benchmark) {
            return cached
        }

        if file.sourcekitdFailed {
            queuedPrintError("Most rules will be skipped because sourcekitd has failed.")
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

    public func correct(using storage: RuleStorage) -> [Correction] {
        if let violations = cachedStyleViolations()?.0, violations.isEmpty {
            return []
        }

        var corrections = [Correction]()
        for rule in rules.compactMap({ $0 as? CorrectableRule }) {
            let newCorrections = rule.correct(file: file, using: storage, compilerArguments: compilerArguments)
            corrections += newCorrections
            if !newCorrections.isEmpty {
                file.invalidateCache()
            }
        }
        return corrections
    }

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
        guard !regions.isEmpty, let superfluousDisableCommandRule = superfluousDisableCommandRule else {
            return []
        }
        let allCustomIdentifiers = configuration.customRuleIdentifiers.map { RuleIdentifier($0) }
        let allRuleIdentifiers = masterRuleList.allValidIdentifiers().map { RuleIdentifier($0) }
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
