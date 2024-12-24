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
    struct Coverage {
        let numberOfLinesOfCode: Int
        let observedCoverage: Int
        let maximumCoverage: Int

        static func + (left: Self, right: Self) -> Self {
            Self(
                numberOfLinesOfCode: left.numberOfLinesOfCode + right.numberOfLinesOfCode,
                observedCoverage: left.observedCoverage + right.observedCoverage,
                maximumCoverage: left.maximumCoverage + right.maximumCoverage
            )
        }
    }

    private let totalNumberOfRules: Int
    private var coverage = Coverage()

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
        coverage = coverage + file.coverage(for: rules)
    }

    private func coverage(denominator: Int) -> Double {
        denominator == 0 ? 0.0 : (Double(coverage.observedCoverage) / Double(denominator))
    }
}

extension Coverage.Coverage {
    init() {
        self.init(numberOfLinesOfCode: 0, observedCoverage: 0, maximumCoverage: 0)
    }
}

private extension SwiftLintFile {
    func coverage(for rules: [any Rule]) -> Coverage.Coverage {
        guard !contents.isEmpty else {
            return Coverage.Coverage()
        }
        let numberOfLinesInFile = lines.count
        let ruleIdentifiers = rules.ruleIdentifiers
        let maxProduct = numberOfLinesInFile * rules.numberOfRulesIncludingCustom
        var observedProduct = maxProduct
        for region in regions {
            let numberOfLinesInRegion = region.numberOfLines(numberOfLinesInFile: numberOfLinesInFile)
            if region.disabledRuleIdentifiers.contains(.all) {
                observedProduct -= numberOfLinesInRegion * rules.numberOfRulesIncludingCustom
            } else {
                let disabledRuleIdentifiers = Set(region.disabledRuleIdentifiers.map { $0.stringRepresentation })
                let numberOfDisabledRules: Int = if disabledRuleIdentifiers.contains(CustomRules.identifier) {
                    disabledRuleIdentifiers.subtracting(
                        Set(rules.customRuleIdentifiers + [CustomRules.identifier])
                    ).intersection(ruleIdentifiers).count + rules.customRuleIdentifiers.count
                } else {
                    disabledRuleIdentifiers.intersection(ruleIdentifiers).count
                }
                observedProduct -= numberOfLinesInRegion * numberOfDisabledRules
            }
        }

        return Coverage.Coverage(
            numberOfLinesOfCode: numberOfLinesInFile,
            observedCoverage: observedProduct,
            maximumCoverage: maxProduct
        )
    }
}

private extension Region {
    func numberOfLines(numberOfLinesInFile: Int) -> Int {
        end.line == .max ?
            numberOfLinesInFile - (start.line ?? numberOfLinesInFile) :
            max((end.line ?? 0) - (start.line ?? 0), 1)
    }
}

private extension Configuration {
    var customRuleIdentifiers: [String] { rules.customRuleIdentifiers }

    func numberOfLinterRules() -> Int {
        var numberOfLinterRules = RuleRegistry.shared.numberOfLinterRules
        let customRuleIdentifiers = customRuleIdentifiers
        if customRuleIdentifiers.isNotEmpty {
            numberOfLinterRules += customRuleIdentifiers.count - 1
        }
        return numberOfLinterRules
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
        customRules?.customRuleIdentifiers ?? []
    }
    var numberOfRulesIncludingCustom: Int {
        count + Swift.max(customRuleIdentifiers.count - 1, 0)
    }
    private var customRules: CustomRules? {
        first { $0 is CustomRules } as? CustomRules
    }
}

private extension Double {
    func rounded(toNearestPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
