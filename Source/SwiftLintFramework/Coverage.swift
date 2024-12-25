import Foundation

/// Coverage is the total of the number of rules that are applied to each line of each input file, as a proportion
/// of the total number of rules that could have been applied.
///
/// For example, if all rules are applied to every single line, then coverage would be 1. If half the rules are applied
/// to all input lines, or if all the rules are applied to half of the input lines, then coverage would be 0.5, and if
/// no rules are enabled, or there are no input lines, then coverage would be zero.
///
/// No distinction is made between actual lines of Swift source, versus blank lines or comments, as SwiftLint may
/// apply rules to those as well.
///
/// Two coverage metrics are calculated, based on different sets of rules:
///
/// * "Enabled rules coverage" is based on the enabled rules only, and measures how frequently these are being
///   disabled by `swiftlint:disable` commands.
/// * "All rules coverage" is based on all of the rules, and measures the coverage that's being achieved, compared
///   to what could be achieved if all rules were enabled.
///
/// When calculating `allRulesCoverage`, we only take acount of disable commands for enabled rules, so
/// if there are any disable commands for non-enabled rules, then `allRulesCoverage` will slightly underestimate
/// actual coverage (as if those rules were enabled, they would not apply to every line).
///
/// Linter and analyzer rules will be counted separately, so coverage will be different for each.
///
/// The number of enabled rules is determined on a per-file basis, so child and local configurations will be accounted
/// for.
///
/// Rules defined by `CustomRules`, if enabled, will be counted as first class rules in both enabled and all rules
/// coverage. If not enabled, `CustomRules` will be counted as a single rule, even if a configuration exists for it.
/// When calculating enabled rules coverage, the custom rules in the configuration for each file (e.g. including
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

    var coverage = Coverage() // swiftlint:disable:this prefer_self_in_static_references

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
        addCoverage(for: linter.file, rules: linter.rules)
    }

    mutating func addCoverage(for file: SwiftLintFile, rules: [any Rule]) {
        coverage.add(file.coverage(for: rules))
    }

    private func coverage(denominator: Int) -> Double {
        denominator == 0 ? 0.0 : (Double(coverage.observedCoverage) / Double(denominator))
    }
}

private extension SwiftLintFile {
    func coverage(for rules: [any Rule]) -> Coverage.Coverage {
        guard !contents.isEmpty else {
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
        let numberOfMatchingIdentifiers = intersection(ruleIdentifiers).count
        // Check whether there is more than one match, or more ruleIdentifiers than there are rules
        // We do not need to worry about `custom_rules` being used to disable all custom rules
        // as that is taken care of by the caller.
        guard numberOfMatchingIdentifiers > 1, ruleIdentifiers.count > rules.count else {
            return numberOfMatchingIdentifiers
        }
        // All possible identifiers have been specified.
        guard numberOfMatchingIdentifiers < ruleIdentifiers.count else {
            return rules.count
        }
        // Finally we need to look at the actual identifiers. Iterate over the rules,
        // and work out which rules are actually disabled - this is complicated by aliases and
        // custom rules.
        var remainingDisabledIdentifiers = self
        var numberOfDisabledRules = 0
        for rule in rules {
            let customRules = rule as? CustomRules
            let allRuleIdentifiers = type(of: rule).description.allIdentifiers + (customRules?.customRuleIdentifiers ?? [])

            if !remainingDisabledIdentifiers.isDisjoint(with: allRuleIdentifiers) {
                if customRules != nil {
                    numberOfDisabledRules += remainingDisabledIdentifiers.intersection(allRuleIdentifiers).count
                } else {
                    numberOfDisabledRules += 1
                }
                remainingDisabledIdentifiers.subtract(allRuleIdentifiers)

                // If there is only one identifier left, it must match one rule. `custom_rules` will have
                // been dealt already by the caller
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
