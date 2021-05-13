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

    private static func groupViolations(_ violations: [StyleViolation],
                                        WithViolationsSeverity severity: ViolationSeverity) -> [[StyleViolation]] {
        
        let groupedBySeverity = Dictionary(grouping: violations) { $0.severity }
        var groupedArrays = [[StyleViolation]]()
        
        if let errorViolations = groupedBySeverity[severity] {
            let groupedErrorViolations = Dictionary(grouping: errorViolations) { $0.ruleIdentifier }
            for key in groupedErrorViolations.keys {
                if let violations = groupedErrorViolations[key] {
                    groupedArrays.append(violations)
                }
            }
        }
        
        groupedArrays.sort { (array0, array1) -> Bool in
            return array0.count > array1.count
        }
        return groupedArrays
    }
    
    public static func generateReport(_ violations: [StyleViolation]) -> String {
        var report = ""
        
        let errorsCount = violations.filter{ $0.severity == .error }.count
        let warningsCount = violations.filter{ $0.severity == .warning }.count
        
        let groupedErrors = groupViolations(violations, WithViolationsSeverity: .error)
        let groupdeWarnings = groupViolations(violations, WithViolationsSeverity: .warning)
        
        report.append("--------------------------------------------\n")
        report.append("Errors: \(errorsCount)\n")
        report.append("--------------------------------------------\n")
        
        for errorsArray in groupedErrors {
            if let errorInstance = errorsArray.first {
                report.append("\(errorsArray.count): \(errorInstance.ruleIdentifier) \n")
            }
        }
        
        report.append("--------------------------------------------\n")
        report.append("Warnings: \(warningsCount)\n")
        report.append("--------------------------------------------\n")
        
        for warningsArray in groupdeWarnings {
            if let warningInstance = warningsArray.first {
                report.append("\(warningsArray.count): \(warningInstance.ruleIdentifier) \n")
            }
        }
        
        return report
    }
}
