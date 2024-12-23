import Foundation

struct Coverage {
    private let totalNumberOfRules: Int
    private var numberOfLinesOfCode = 0
    private var maximumCoverage = 0
    private var observedCoverage = 0
    var enabledRulesCoverage: Double {
        coverage(denominator: maximumCoverage)
    }
    var allRulesCoverage: Double {
        coverage(denominator: numberOfLinesOfCode * totalNumberOfRules)
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

    mutating func addCoverage(for file: SwiftLintFile, rules: [any Rule]) {
        let numberOfLinesInFile = file.lines.count
        let ruleIdentifiers = Set(rules.flatMap { type(of: $0).description.allIdentifiers })
        let maxProduct = numberOfLinesInFile * rules.count
        var observedProduct = maxProduct
        for region in file.regions() {
            if region.disabledRuleIdentifiers.contains(.all) {
                // All rules are disabled
                let numberOfLines = region.numberOfLines(numberOfLinesInFile: numberOfLinesInFile)
                observedProduct -= (numberOfLines * rules.count)
            } else {
                // number of disabled rules that are disabled by the region
                let disabledRuleIdentifiers = Set(region.disabledRuleIdentifiers.map { $0.stringRepresentation })
                let numberOfActiveDisabledRules = disabledRuleIdentifiers.intersection(ruleIdentifiers).count
                let numberOfLines = region.numberOfLines(numberOfLinesInFile: numberOfLinesInFile)
                observedProduct -= numberOfLines * numberOfActiveDisabledRules
            }
        }

        numberOfLinesOfCode += numberOfLinesInFile
        maximumCoverage += maxProduct
        observedCoverage += observedProduct
    }

    private func coverage(denominator: Int) -> Double {
        denominator == 0 ? 0.0 : (Double(observedCoverage) / Double(denominator))
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
        return (self * divisor).rounded() / divisor
    }
}
