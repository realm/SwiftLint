@testable import SwiftLintFramework
import XCTest

class BaselineTests: XCTestCase {
    private let fileManager = FileManager.default
    var outputPath: String! {
        didSet {
            try? fileManager.removeItem(atPath: outputPath)
        }
    }

    private let mockViolation = StyleViolation(
            ruleDescription: LineLengthRule.description,
            location: Location(file: "/Mock/Test/MockFile.swift", line: 5, character: 2),
            reason: "Violation Reason.")

    override func tearDown() {
        super.tearDown()
        try? fileManager.removeItem(atPath: outputPath)
    }

    func testSaveBaseline() {
        outputPath = testResourcesPath + "/testSaveBaseline"
        let baselinePath = outputPath + "/\(Baseline.kBaselineFileName)"
        let baseline = Baseline(rootPath: outputPath)

        XCTAssertFalse(fileManager.isReadableFile(atPath: baselinePath))

        baseline.saveBaseline(violations: [mockViolation])
        XCTAssertTrue(fileManager.isReadableFile(atPath: baselinePath))
    }

    func testReadBaseline() {
        outputPath = testResourcesPath + "/testReadBaseline"
        let baseline = Baseline(rootPath: outputPath)

        baseline.saveBaseline(violations: [mockViolation])
        baseline.readBaseline()
        let mockBaselineViolation = BaselineViolation(ruleIdentifier: mockViolation.ruleDescription.identifier,
                                                      location: mockViolation.location.description,
                                                      reason: mockViolation.reason)

        XCTAssertEqual(baseline.baselineViolations, [mockBaselineViolation])
        try? fileManager.removeItem(atPath: outputPath)
    }

    func testReadBaselineWithoutFile() {
        outputPath = testResourcesPath + "/testReadBaselineWithoutFile"
        let baseline = Baseline(rootPath: outputPath)

        baseline.readBaseline()

        XCTAssertEqual(baseline.baselineViolations, [])
        try? fileManager.removeItem(atPath: outputPath)
    }

    func testIsInBaseline() {
        outputPath = testResourcesPath + "/testIsInBaseline"
        let baseline = Baseline(rootPath: outputPath)

        baseline.saveBaseline(violations: [mockViolation])
        baseline.readBaseline()

        XCTAssertTrue(baseline.isInBaseline(violation: mockViolation))
        try? fileManager.removeItem(atPath: outputPath)
    }

    func testIsInBaselineWithoutFile() {
        outputPath = testResourcesPath + "/testIsInBaselineWithoutFile"
        let baselinePath = outputPath + "/\(Baseline.kBaselineFileName)"
        let baseline = Baseline(rootPath: outputPath)

        baseline.readBaseline()

        XCTAssertFalse(fileManager.isReadableFile(atPath: baselinePath))
        XCTAssertFalse(baseline.isInBaseline(violation: mockViolation))
        try? fileManager.removeItem(atPath: outputPath)
    }

    func testChangingSourcePath() {
        outputPath = testResourcesPath + "/testChangingSourcePath"
        let baselinePath = outputPath + "/\(Baseline.kBaselineFileName)"
        var baseline = Baseline(rootPath: outputPath)
        let changedRootPath = outputPath + "/Second"
        let violation = StyleViolation(
                ruleDescription: LineLengthRule.description,
                location: Location(
                        file: outputPath + "/MockFile.swift",
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

        try? fileManager.removeItem(atPath: changedRootPath)
        baseline.saveBaseline(violations: [violation])
        baseline.readBaseline()
        // Move baseline file and change root directory
        try? fileManager.createDirectory(atPath: changedRootPath, withIntermediateDirectories: true, attributes: nil)
        try? fileManager.moveItem(atPath: baselinePath, toPath: changedRootPath + "/.swiftlint_baseline")
        baseline = Baseline(rootPath: changedRootPath)
        baseline.readBaseline()

        XCTAssertTrue(baseline.isInBaseline(violation: secondViolation))
        try? fileManager.removeItem(atPath: outputPath)
    }

    func testTwoFilesWithSameName() {
        outputPath = testResourcesPath + "/testTwoFilesWithSameName"
        let baselinePath = outputPath + "/\(Baseline.kBaselineFileName)"
        var baseline = Baseline(rootPath: outputPath)

        let changedRootPath = outputPath + "/Second"
        let violation = StyleViolation(
                ruleDescription: LineLengthRule.description,
                location: Location(
                        file: outputPath + "/MockFile.swift",
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

        try? fileManager.removeItem(atPath: changedRootPath)
        baseline.saveBaseline(violations: [violation])
        baseline.readBaseline()

        // Move baseline file and change root directory
        try? fileManager.createDirectory(atPath: changedRootPath, withIntermediateDirectories: true, attributes: nil)
        try? fileManager.moveItem(atPath: baselinePath, toPath: changedRootPath + "/.swiftlint_baseline")
        baseline = Baseline(rootPath: changedRootPath)
        baseline.readBaseline()

        XCTAssertFalse(baseline.isInBaseline(violation: secondViolation))
        try? fileManager.removeItem(atPath: outputPath)
    }
}
