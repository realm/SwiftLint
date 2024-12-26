import Foundation

/// Collects and reports coverage statistics.
///
/// Coverage is defined as the sum of the number of rules applied to each line of input, divided by the product of the
/// number of input lines and the total number of rules.
///
/// If all rules are applied to every input line, then coverage would be `1` (or 100%). If half the rules are applied
/// to all input lines, or if all the rules are applied to half of the input lines, then coverage would be `0.5`, and
/// if no rules are enabled, or there is no input, then coverage would be zero.
///
/// No distinction is made between actual lines of Swift source, versus blank lines or comments, as SwiftLint may
/// apply rules to those as well. Coverage is only calculated over input files, so if you exclude files in your
/// configuration, they will be ignored.
///
/// "All rules" can be defined either as *all enabled rules*, **or** *all available rules, enabled or not*, resulting
/// in two different coverage metrics:
///
/// * "Enabled rules coverage" measures how frequently enabled rules are being disabled by `swiftlint:disable`
///   commands.
/// * "All rules coverage" measures how many of all possible rules are actually being applied.
///
/// Typically, enabled rules coverage will be close to `1`,  as `swiftlint:disable` is used sparingly. All rules
/// coverage will generally be much lower, as some rules are contradictory, and many rules are optin. With no opt-in
/// rules enabled, all rules coverage will be about `0.4`, rising to `0.8` or more if many opt-in rules are enabled.
///
/// When calculating all rules coverage `swiftlint:disable` commands are still accounted for, but only for enabled
/// rules.
///
/// Coverage figures will be different for linting and analyzing as these use different sets of rules.
///
/// The number of enabled rules is determined on a per-file basis, so child and local configurations will be accounted
/// for.
///
/// Custom rules, if enabled and defined, will be counted as first class rules for both enabled and all rules coverage.
/// If not enabled, `custom_rules` will be counted as a single rule, even if a configuration exists for it.
///
/// When calculating enabled rules coverage, the custom rules in the configuration for each input file (e.g. including
/// child configurations) will be taken into account. When calculating all rules coverage, only the main configurations
/// custom rules settings will be used.
///
struct Coverage {
    struct Coverage: Equatable {
        var numberOfLinesOfCode = 0
        var observedCoverage = 0
        var maximumCoverage = 0

        mutating func add(_ coverage: Self) {
            numberOfLinesOfCode += coverage.numberOfLinesOfCode
            observedCoverage += coverage.observedCoverage
            maximumCoverage += coverage.maximumCoverage
        }
    }

    private let totalNumberOfRules: Int
    var coverage = Self.Coverage()

    var enabledRulesCoverage: Double {
        coverage(denominator: coverage.maximumCoverage)
    }
    var allRulesCoverage: Double {
        coverage(denominator: coverage.numberOfLinesOfCode * totalNumberOfRules)
    }
    var report: String {
        """
        Enabled rules coverage: \(enabledRulesCoverage.rounded(toNearestPlaces: 3))
            All rules coverage: \(allRulesCoverage.rounded(toNearestPlaces: 3))
        """
    }

    init(totalNumberOfRules: Int) {
        self.totalNumberOfRules = totalNumberOfRules
    }

    init(mode: LintOrAnalyzeMode, configuration: Configuration) {
        let totalNumberOfRules: Int = if mode == .lint {
            configuration.numberOfLinterRules()
        } else {
            RuleRegistry.shared.numberOfAnalyzerRules
        }
        self.init(totalNumberOfRules: totalNumberOfRules)
    }

    mutating func addCoverage(for linter: CollectedLinter) {
        coverage.add(linter.file.coverage(for: linter.rules))
    }

    private func coverage(denominator: Int) -> Double {
        denominator == 0 ? 0.0 : (Double(coverage.observedCoverage) / Double(denominator))
    }
}

private extension SwiftLintFile {
    func coverage(for rules: [any Rule]) -> Coverage.Coverage {
        guard !isEmpty else {
            return Coverage.Coverage()
        }
        let numberOfLinesInFile = lines.count
        let ruleIdentifiers = Set(rules.ruleIdentifiers)
        let maximumCoverage = numberOfLinesInFile * rules.numberOfRulesIncludingCustomRules
        var observedCoverage = maximumCoverage
        for region in regions {
            observedCoverage -= region.reducesCoverageBy(
                numberOfLinesInFile: numberOfLinesInFile,
                rules: rules,
                ruleIdentifiers: ruleIdentifiers
            )
        }

        return Coverage.Coverage(
            numberOfLinesOfCode: numberOfLinesInFile,
            observedCoverage: observedCoverage,
            maximumCoverage: maximumCoverage
        )
    }
}

private extension Region {
    func reducesCoverageBy(numberOfLinesInFile: Int, rules: [any Rule], ruleIdentifiers: Set<String>) -> Int {
        guard disabledRuleIdentifiers.isNotEmpty else {
            return 0
        }

        let numberOfLinesInRegion = numberOfLines(numberOfLinesInFile: numberOfLinesInFile)
        if disabledRuleIdentifiers.contains(.all) {
            return numberOfLinesInRegion * rules.numberOfRulesIncludingCustomRules
        }

        let disabledRuleIdentifiers = Set(disabledRuleIdentifiers.map { $0.stringRepresentation })
        let numberOfDisabledRules: Int = if disabledRuleIdentifiers.contains(CustomRules.identifier) {
            disabledRuleIdentifiers.subtracting(
                Set(rules.customRuleIdentifiers + [CustomRules.identifier])
            ).numberOfDisabledRules(from: ruleIdentifiers, rules: rules) + rules.customRuleIdentifiers.count
        } else {
            disabledRuleIdentifiers.numberOfDisabledRules(from: ruleIdentifiers, rules: rules)
        }
        return numberOfLinesInRegion * numberOfDisabledRules
    }

    private func numberOfLines(numberOfLinesInFile: Int) -> Int {
        end.line == .max ?
            numberOfLinesInFile - (start.line ?? numberOfLinesInFile) :
            max((end.line ?? 0) - (start.line ?? 0), 1)
    }
}

private extension Set<String> {
    func numberOfDisabledRules(from ruleIdentifiers: Self, rules: [any Rule]) -> Int {
        var remainingDisabledIdentifiers = intersection(ruleIdentifiers)

        // Check whether there is more than one match, or more ruleIdentifiers than there are rules
        // We do not need to worry about `custom_rules` being used to disable all custom rules
        // as that is taken care of by the caller.
        guard remainingDisabledIdentifiers.count > 1, ruleIdentifiers.count > rules.count else {
            return remainingDisabledIdentifiers.count
        }
        // Have all possible identifiers been specified?
        guard remainingDisabledIdentifiers.count < ruleIdentifiers.count else {
            return rules.count
        }
        // We need to handle aliases and custom rules specially.
        var numberOfDisabledRules = 0
        for rule in rules {
            let allRuleIdentifiers = type(of: rule).description.allIdentifiers + [rule].customRuleIdentifiers
            if !remainingDisabledIdentifiers.isDisjoint(with: allRuleIdentifiers) {
                if rule is CustomRules {
                    numberOfDisabledRules += remainingDisabledIdentifiers.intersection(allRuleIdentifiers).count
                } else {
                    numberOfDisabledRules += 1
                }
                remainingDisabledIdentifiers.subtract(allRuleIdentifiers)

                // If there is only one identifier left, it must match one rule.
                if remainingDisabledIdentifiers.count == 1 {
                    return numberOfDisabledRules + 1
                }
                if remainingDisabledIdentifiers.isEmpty {
                    return numberOfDisabledRules
                }
            }
        }
        return numberOfDisabledRules
    }
}

private extension Configuration {
    func numberOfLinterRules() -> Int {
        RuleRegistry.shared.numberOfLinterRules + max(rules.customRuleIdentifiers.count - 1, 0)
    }
}

private extension RuleRegistry {
    var numberOfLinterRules: Int {
        RuleRegistry.shared.list.list.filter({ !($1 is any AnalyzerRule.Type) }).count
    }
    var numberOfAnalyzerRules: Int {
        RuleRegistry.shared.list.list.filter({ $1 is any AnalyzerRule.Type }).count
    }
}

private extension [any Rule] {
    var ruleIdentifiers: [String] {
        Set(flatMap { type(of: $0).description.allIdentifiers }) + customRuleIdentifiers
    }
    var customRuleIdentifiers: [String] {
        (first { $0 is CustomRules } as? CustomRules)?.customRuleIdentifiers ?? []
    }
    var numberOfRulesIncludingCustomRules: Int {
        count + Swift.max(customRuleIdentifiers.count - 1, 0)
    }
}

private extension Double {
    func rounded(toNearestPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
