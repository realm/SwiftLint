@testable import swiftlint
@testable import SwiftLintBuiltInRules
import SwiftLintFramework
import XCTest

final class BaselineTests: XCTestCase {
    private var path: String {
        "/Some/path.swift"
    }
    private var violations: [StyleViolation] {
        [
            StyleViolation(
                ruleDescription: ArrayInitRule.description,
                location: Location(file: path, line: 1, character: 1)
            ),
            StyleViolation(
                ruleDescription: BlanketDisableCommandRule.description,
                location: Location(file: path, line: 5, character: 1)
            ),
            StyleViolation(
                ruleDescription: ClosingBraceRule.description,
                location: Location(file: path, line: 10, character: 1)
            ),
            StyleViolation(
                ruleDescription: DirectReturnRule.description,
                location: Location(file: path, line: 15, character: 1)
            )
        ]
    }

    private var baseline: Baseline {
        return Baseline(violations: violations)
    }

    func testWritingAndReading() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let baselinePath = temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        let baseline = self.baseline
        try baseline.write(toPath: baselinePath)
        let newBaseline = try Baseline(fromPath: baselinePath)
        try FileManager.default.removeItem(atPath: baselinePath)
        XCTAssertEqual(baseline, newBaseline)
    }

    func testUnchangedViolations() throws {
        XCTAssertEqual([], baseline.filter(violations))
    }

    func testShiftedViolations() throws {
        XCTAssertEqual([], baseline.filter(violations.map { $0.with(locationLineShiftedBy: 2) }))
    }

    func testNewViolations() {
        var newViolations = violations
        let violation = StyleViolation(
            ruleDescription: BlanketDisableCommandRule.description,
            location: Location(file: path, line: 7, character: 1)
        )
        newViolations.insert(violation, at: 2)
        XCTAssertEqual([violation], baseline.filter(newViolations))
    }
}

private extension StyleViolation {
    func with(locationLineShiftedBy shift: Int) -> StyleViolation {
        with(location: Location(file: location.file, line: location.line ?? 0 + shift, character: location.character))
    }
}
