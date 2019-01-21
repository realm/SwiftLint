import Foundation

public class BaselineSaver {

    public static func saveBaseline(violations: [StyleViolation], baselinePath: String) {
        let fileContent = violations.map(generateForSingleViolation).joined(separator: "\n")

        print("Saving to file: \(baselinePath)")

        let fileManager = FileManager.default
        do {
            if fileManager.fileExists(atPath: baselinePath) {
                try fileManager.removeItem(atPath: baselinePath)
            }
            fileManager.createFile(atPath: baselinePath, contents: fileContent.data(using: .utf8))
            print("Saved to file: \(baselinePath)")
        } catch {
            print("Error while saving baseline file: \(error)")
        }
    }

    private static func generateForSingleViolation(_ violation: StyleViolation) -> String {
        return "\(violation.location): \(violation.reason),(\(violation.ruleDescription.identifier))"
    }
}
