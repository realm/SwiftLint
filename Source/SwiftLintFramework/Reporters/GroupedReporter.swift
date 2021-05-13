import Foundation
import SourceKittenFramework

/// Reports how numerous violations for each rule violated is.
class ViolationTally: CustomStringConvertible {
    let ruleIdentifier: String
    var count: Int
    var styleViolations: [StyleViolation]
    var description: String {
        get{
            return ""
        }
    }
    
    init(ruleIdentifier: String, count: Int, styleViolations: [StyleViolation]) {
        self.ruleIdentifier = ruleIdentifier
        self.count = count
        self.styleViolations = styleViolations
    }
}

public struct GroupedReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "grouped"
    public static let isRealtime = false

    public var description: String {
        return "Reports how many times certain violations are broken."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        var report = ""
        let groupedBySeverity = Dictionary(grouping: violations) { $0.severity }
        var groupedErrorsArray = [[StyleViolation]]()
        var groupdeWarningsArray = [[StyleViolation]]()
        
        
        if let errorViolations = groupedBySeverity[.error] {
            report = report + "\(errorViolations.count) Errors found:\n"
            let groupedErrorViolations = Dictionary(grouping: errorViolations) { $0.ruleIdentifier }
            for key in groupedErrorViolations.keys {
                if let violations = groupedErrorViolations[key] {
                    groupedErrorsArray.append(violations)
                }
            }
        } else {
            report = report + "No Errors found\n"
        }
        
        groupedErrorsArray.sort { (array0, array1) -> Bool in
            return array0.count > array1.count
        }
        
        for errorsArray in groupedErrorsArray {
            if let errorInstance = errorsArray.first {
                report = report + "\(errorsArray.count): \(errorInstance.ruleIdentifier) \n"
            }
        }
        
        if let warningViolations = groupedBySeverity[.warning] {
            report = report + "\(warningViolations.count) Warnings found:\n"
            let groupedWarningViolations = Dictionary(grouping: warningViolations) { $0.ruleIdentifier }
            for key in groupedWarningViolations.keys {
                if let violations = groupedWarningViolations[key] {
                    groupdeWarningsArray.append(violations)
                }
            }
        } else {
            report = report + "No Warnings found\n"
        }
        
        groupdeWarningsArray.sort { (array0, array1) -> Bool in
            return array0.count > array1.count
        }
        
        for warningsArray in groupdeWarningsArray {
            if let warningInstance = warningsArray.first {
                report = report + "\(warningsArray.count): \(warningInstance.ruleIdentifier) \n"
            }
        }
        
        return report
    }
}
