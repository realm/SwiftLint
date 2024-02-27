@testable import swiftlint
@testable import SwiftLintBuiltInRules
import SwiftLintFramework
import XCTest

private var path: String {
    "/Some/path.swift"
}

final class BaselineTests: XCTestCase {
    private var violations: [StyleViolation] {
        [
            ArrayInitRule.description,
            BlanketDisableCommandRule.description,
            ClosingBraceRule.description,
            DirectReturnRule.description
        ].violations
    }

    private var baseline: Baseline {
        Baseline(violations: violations)
    }

    func testWritingAndReading() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let baselinePath = temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        let baseline = self.baseline
        try baseline.write(toPath: baselinePath)
        let newBaseline = try Baseline(fromPath: baselinePath)
        try FileManager.default.removeItem(atPath: baselinePath)
        XCTAssertEqual(newBaseline, baseline)
    }

    func testUnchangedViolations() throws {
        XCTAssertEqual(baseline.filter(violations), [])
    }

    func testShiftedViolations() throws {
        XCTAssertEqual(baseline.filter(violations.lineShifted(by: 2)), [])
    }

    func testNewViolations() {
        var newViolations = violations
        let violation = StyleViolation(
            ruleDescription: BlanketDisableCommandRule.description,
            location: Location(file: path, line: 12, character: 1)
        )
        newViolations.insert(violation, at: 2)
        XCTAssertEqual(baseline.filter(newViolations), [violation])
    }

    func testNewIdenticalViolationAtStart() {
        var newViolations = violations.lineShifted(by: 1)
        let violation = StyleViolation(
            ruleDescription: ArrayInitRule.description,
            location: Location(file: path, line: 1, character: 1)
        )
        newViolations.insert(violation, at: 0)
        // This is the wrong answer. We really want the first violation
        XCTAssertEqual(baseline.filter(newViolations), [newViolations[1]])
    }

    func testNewViolationsAtStart() {
        var newViolations = violations.lineShifted(by: 1)
        let violation = StyleViolation(
            ruleDescription: BlanketDisableCommandRule.description,
            location: Location(file: path, line: 1, character: 1)
        )
        newViolations.insert(violation, at: 0)
        XCTAssertEqual(baseline.filter(newViolations), [violation])
    }

    func testNewViolationsInTheMiddle() {
        var newViolations = violations.lineShifted(by: 1)
        let violation = StyleViolation(
            ruleDescription: ArrayInitRule.description,
            location: Location(file: path, line: 12, character: 1)
        )
        newViolations.insert(violation, at: 2)
        XCTAssertEqual(baseline.filter(newViolations), [violation])
    }

    func testShuffledViolations() throws {
        try XCTSkipIf(true)
        var newViolations = violations.lineShifted(by: 1)
        let violation = StyleViolation(
            ruleDescription: BlanketDisableCommandRule.description,
            location: Location(file: path, line: 1, character: 1)
        )
        newViolations.insert(violation, at: 0)
        let filteredViolations = baseline.filter(newViolations.shuffled())
//        XCTAssertEqual(filteredViolations.count, 1)
//        XCTAssertEqual(filteredViolations.first?.ruleIdentifier, violation.ruleIdentifier)
        XCTAssertEqual(filteredViolations, [violation])
    }

    func testLongerViolations() {
        let violations = [
            ArrayInitRule.description,
            BlanketDisableCommandRule.description,
            ArrayInitRule.description,
            ClosingBraceRule.description,
            ClosingBraceRule.description,
            ClosingBraceRule.description,
            BlanketDisableCommandRule.description,
            DirectReturnRule.description,
            ArrayInitRule.description,
            ClosingBraceRule.description
        ].violations

        let baseline = Baseline(violations: violations)
        var newViolations = violations.lineShifted(by: 1)
        let violation = StyleViolation(
            ruleDescription: ArrayInitRule.description,
            location: Location(file: path, line: 22, character: 1)
        )
        newViolations.insert(violation, at: 4)
        XCTAssertEqual(baseline.filter(newViolations), [violation])
    }

    private func testNewViolation(violations: [StyleViolation], lineShift: Int, newViolation: StyleViolation, expectedViolations: ) {

    }
}

private extension Sequence where Element == StyleViolation {
    func lineShifted(by shift: Int) -> [StyleViolation] {
        map {
            let shiftedLocation = Location(
                file: $0.location.file,
                line: ($0.location.line ?? 0) + shift,
                character: $0.location.character
            )
            return $0.with(location: shiftedLocation)
        }
    }
}

private extension Sequence where Element == RuleDescription {
    var violations: [StyleViolation] {
        enumerated().map { index, ruleDescription in
            StyleViolation(
                ruleDescription: ruleDescription,
                location: Location(file: path, line: (index + 1) * 5, character: 1)
            )
        }
    }
}
