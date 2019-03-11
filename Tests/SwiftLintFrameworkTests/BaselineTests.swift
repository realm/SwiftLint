@testable import SwiftLintFramework
import XCTest

class BaselineTests: XCTestCase {
    private let fileManager = FileManager.default
    private var baseline: Baseline!

    private var outputPath: String {
        return testResourcesPath
    }

    private var baselinePath: String {
        return outputPath + "/.swiftlint_baseline"
    }

    private let mockViolation = StyleViolation(
            ruleDescription: LineLengthRule.description,
            location: Location(file: "/Mock/Test/MockFile.swift", line: 5, character: 2),
            reason: "Violation Reason.")

    override func setUp() {
        super.setUp()
        baseline = Baseline(rootPath: outputPath)
    }

    override func tearDown() {
        super.tearDown()
        try? fileManager.removeItem(atPath: baselinePath)
    }

    func testSaveBaseline() {
        baseline.saveBaseline(violations: [mockViolation])
        XCTAssertTrue(fileManager.isReadableFile(atPath: baselinePath))
    }

    func testReadBaseline() {
        baseline.saveBaseline(violations: [mockViolation])
        baseline.readBaseline()
        let mockBaselineViolation = BaselineViolation(ruleIdentifier: mockViolation.ruleDescription.identifier,
                                                      location: mockViolation.location.description,
                                                      reason: mockViolation.reason)
        XCTAssertEqual(baseline.baselineViolations, [mockBaselineViolation])
    }

    func testReadBaselineWithoutFile() {
        baseline.readBaseline()
        XCTAssertEqual(baseline.baselineViolations, [])
    }

    func testIsInBaseline() {
        baseline.saveBaseline(violations: [mockViolation])
        baseline.readBaseline()
        XCTAssertTrue(baseline.isInBaseline(violation: mockViolation))
    }

    func testIsInBaselineWithoutFile() {
        baseline.readBaseline()
        XCTAssertFalse(baseline.isInBaseline(violation: mockViolation))
    }

    func testChangingSourcePath() {
        let changedRootPath = "\(outputPath)/Second"
        let violation = StyleViolation(
                ruleDescription: LineLengthRule.description,
                location: Location(
                        file: "\(outputPath)/MockFile.swift",
                        line: 5,
                        character: 2
                ),
                reason: "Violation Reason."
        )
        let secondViolation = StyleViolation(
                ruleDescription: LineLengthRule.description,
                location: Location(
                        file: "\(changedRootPath)/MockFile.swift",
                        line: 5,
                        character: 2
                ),
                reason: "Violation Reason."
        )

        baseline.saveBaseline(violations: [violation])
        baseline.readBaseline()
        // swiftlint:disable force_try
        // Move baseline file and change root directory
        try! fileManager.createDirectory(atPath: changedRootPath, withIntermediateDirectories: true, attributes: nil)
        print("Created directory at \(changedRootPath)")
        try! fileManager.moveItem(atPath: baselinePath, toPath: changedRootPath + "/.swiftlint_baseline")
        print("Moved file to path: \(changedRootPath + "/.swiftlint_baseline")")
        baseline = Baseline(rootPath: changedRootPath)
        baseline.readBaseline()

        XCTAssertTrue(baseline.isInBaseline(violation: secondViolation))
        try! fileManager.removeItem(atPath: changedRootPath)
        print("Removed file at path: \(changedRootPath + "/.swiftlint_baseline")")
    }
    // swiftlint:enable force_try

    func testTwoFilesWithSameName() {
        let changedRootPath = "\(outputPath)/Second"
        let violation = StyleViolation(
                ruleDescription: LineLengthRule.description,
                location: Location(
                        file: "\(outputPath)/MockFile.swift",
                        line: 5,
                        character: 2
                ),
                reason: "Violation Reason."
        )
        let secondViolation = StyleViolation(
                ruleDescription: LineLengthRule.description,
                location: Location(
                        file: "\(changedRootPath)/New/MockFile.swift",
                        line: 5,
                        character: 2
                ),
                reason: "Violation Reason."
        )

        baseline.saveBaseline(violations: [violation])
        baseline.readBaseline()

        // Move baseline file and change root directory
        try? fileManager.createDirectory(atPath: changedRootPath, withIntermediateDirectories: true, attributes: nil)
        try? fileManager.moveItem(atPath: baselinePath, toPath: changedRootPath + "/.swiftlint_baseline")
        baseline = Baseline(rootPath: changedRootPath)
        baseline.readBaseline()

        XCTAssertFalse(baseline.isInBaseline(violation: secondViolation))
        try? fileManager.removeItem(atPath: changedRootPath)
    }
}
