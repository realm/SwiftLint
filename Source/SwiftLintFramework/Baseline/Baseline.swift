import Foundation

public class Baseline {
    private let kBaselineFileName = ".swiftlint_baseline"
    private let rootPath: String
    private var baselinePath: String {
        return "\(rootPath)/\(kBaselineFileName)"
    }
    private(set) var baselineViolations = [BaselineViolation]()

    public init(rootPath: String) {
        self.rootPath = rootPath
    }

    public func isInBaseline(violation: StyleViolation) -> Bool {
        let baselineViolation = BaselineViolation(
                ruleIdentifier: violation.ruleDescription.identifier,
                location: locationWithoutRoot(violation: violation),
                reason: violation.reason
        )
        let contains = baselineViolations.contains(baselineViolation)
        return contains
    }

    public func saveBaseline(violations: [StyleViolation]) {
        let fileContent = violations.map(generateForSingleViolation).joined(separator: "\n")
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: baselinePath) {
            let isFileCreated = fileManager.createFile(atPath: baselinePath, contents: fileContent.data(using: .utf8))
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

    private func locationWithoutRoot(violation: StyleViolation) -> String {
        guard let rootRange = violation.location.description.range(of: rootPath) else {
            return violation.location.description
        }
        let blah = String(violation.location.description[rootRange.upperBound...])
        return blah
    }

    private func generateForSingleViolation(_ violation: StyleViolation) -> String {
        let location = locationWithoutRoot(violation: violation)
        return "\(location);\(violation.reason);\(violation.ruleDescription.identifier)"
    }
}
