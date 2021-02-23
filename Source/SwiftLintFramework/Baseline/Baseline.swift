import Foundation

/// A snapshot record of violations at a given time that future linting operations can compare against.
public class Baseline {
    private let baselinePath: String
    private var baselineViolations = [BaselineViolation]()

    // MARK: - Public

    /// Create a baseline container at the specified path.

    /// - parameter baselinePath: Path on disk where the baseline will be read from and written to.
    public init(baselinePath: String) {
        self.baselinePath = baselinePath
    }

    /// Checks if the specified style violation is in the baseline record.
    ///
    /// - parameter violation: The style violation to check for membership in the baseline.
    ///
    /// - returns: If the violation is in the baseline.
    public func isInBaseline(violation: StyleViolation) -> Bool {
        let baselineViolation = BaselineViolation(
            ruleIdentifier: violation.ruleIdentifier,
            location: violation.location.description,
            reason: violation.reason
        )
        return baselineViolations.contains(baselineViolation)
    }

    /// Saves the violations in the baseline file if the file does not yet exist.
    ///
    /// - parameter violations: The style violations to record in the baseline.
    public func saveBaseline(violations: [StyleViolation]) {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: baselinePath) {
            let fileContent = violations.map(generateForSingleViolation).joined(separator: "\n")
            fileManager.createFile(atPath: baselinePath, contents: fileContent.data(using: .utf8))
        }
    }

    /// Reads the contents of the baseline file if it exists, applying the results to the current baseline container.
    public func readBaseline() {
        let fileManager = FileManager.default
        guard let fileContent = fileManager.contents(atPath: baselinePath),
              let stringContent = String(data: fileContent, encoding: .utf8) else {
            return
        }
        stringContent.enumerateLines { [unowned self] line, _ in
            let violation = self.parseLine(line: line)
            self.baselineViolations.append(violation)
        }
    }

    // MARK: - Private

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
