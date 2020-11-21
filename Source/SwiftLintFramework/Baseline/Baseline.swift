import Foundation

public class Baseline {
    private let baselinePath: String
    private var baselineViolations = [BaselineViolation]()

    public init(baselinePath: String) {
        self.baselinePath = baselinePath
    }

    public func isInBaseline(violation: StyleViolation) -> Bool {
        let baselineViolation = BaselineViolation(
                ruleIdentifier: violation.ruleIdentifier,
                location: violation.location.description,
                reason: violation.reason
        )
        let contains = baselineViolations.contains(baselineViolation)
        return contains
    }

    public func saveBaseline(violations: [StyleViolation]) {
        let fileContent = violations.map(generateForSingleViolation).joined(separator: "\n")
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: baselinePath) {
            fileManager.createFile(atPath: baselinePath, contents: fileContent.data(using: .utf8))
        }
    }

    public func readBaseline() {
        let fileManager = FileManager.default
        guard let fileContent = fileManager.contents(atPath: baselinePath),
              let stringContent = String(data: fileContent, encoding: .utf8) else {
            return
        }
        stringContent.enumerateLines { [weak self] line, _ in
            guard let self = self else { return }
            let violation = self.parseLine(line: line)
            self.baselineViolations.append(violation)
        }
    }

    private func parseLine(line: String) -> BaselineViolation {
        let components = line.components(separatedBy: ";")
        let location = components[0]
        let reason = components[1]
        let ruleIdentifier = components[2]

        return BaselineViolation(
                ruleIdentifier: ruleIdentifier,
                location: location,
                reason: reason
        )
    }

    private func generateForSingleViolation(_ violation: StyleViolation) -> String {
        return "\(violation.location);\(violation.reason);\(violation.ruleIdentifier)"
    }
}
