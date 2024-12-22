import Foundation

struct Coverage {
    private let numberOfEnabledRules: Int
    private let totalNumberOfRules: Int
    private var numberOfLinesOfCode = 0
    private var coverageRulesProduct = 0
    private var enabledRulesCoverage: Double {
        coverage(forNumberOfRules: numberOfEnabledRules)
    }
    private var allRulesCoverage: Double {
        coverage(forNumberOfRules: totalNumberOfRules)
    }

    var report: String {
        """
        Enabled rules coverage: \(enabledRulesCoverage.rounded(toNearestPlaces: 3))
            All rules coverage: \(allRulesCoverage.rounded(toNearestPlaces: 3))
        """
    }

    init(numberOfEnabledRules: Int, totalNumberOfRules: Int) {
        self.numberOfEnabledRules = numberOfEnabledRules
        self.totalNumberOfRules = totalNumberOfRules
    }

    mutating func addCoverage(for file: SwiftLintFile, rules: [any Rule]) {
        let numberOfLinesInFile = file.lines.count
        numberOfLinesOfCode += numberOfLinesInFile
        let ruleIdentifiers = Set(rules.flatMap { type(of: $0).description.allIdentifiers })
        var maxProduct = numberOfLinesInFile * rules.count
        for region in file.regions() {
            if region.disabledRuleIdentifiers.contains(.all) {
                // All rules are disabled
                let numberOfLines = region.numberOfLines(numberOfLinesInFile: numberOfLinesInFile)
                maxProduct -= (numberOfLines * rules.count)
            } else {
                // number of disabled rules that are disabled by the region
                let disabledRuleIdentifiers = Set(region.disabledRuleIdentifiers.map { $0.stringRepresentation })
                let numberOfActiveDisabledRules = disabledRuleIdentifiers.intersection(ruleIdentifiers).count
                let numberOfLines = region.numberOfLines(numberOfLinesInFile: numberOfLinesInFile)
                maxProduct -= numberOfLines * numberOfActiveDisabledRules
            }
        }
        coverageRulesProduct += maxProduct
    }

    private func coverage(forNumberOfRules numberOfRules: Int) -> Double {
        let denominator = numberOfLinesOfCode * numberOfRules
        return denominator == 0 ? 0.0 : (Double(coverageRulesProduct) / Double(denominator))
    }
}

private extension Region {
    func numberOfLines(numberOfLinesInFile: Int) -> Int {
        end.line == .max ?
            numberOfLinesInFile - (start.line ?? numberOfLinesInFile) :
            max((end.line ?? 0) - (start.line ?? 0), 1)
    }
}

private extension Double {
    func rounded(toNearestPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return ((self * divisor) + 0.5).rounded() / divisor
    }
}
