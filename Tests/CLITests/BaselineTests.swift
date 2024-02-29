@testable import swiftlint
@testable import SwiftLintBuiltInRules
import SwiftLintFramework
import XCTest

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
        let baseline = baseline
        try Baseline.write(violations, toPath: baselinePath)
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
        testNewViolation(
            violations: violations,
            newViolationRuleDescription: BlanketDisableCommandRule.description,
            insertionIndex: 2
        )
    }

    func testNewIdenticalViolationAtStart() {
        var newViolations = violations.lineShifted(by: 1)
        let violation = StyleViolation(
            ruleDescription: ArrayInitRule.description,
            location: Location(file: #file, line: 1, character: 1)
        )
        newViolations.insert(violation, at: 0)
        // This is the wrong answer. We really want the first violation
        XCTAssertEqual(baseline.filter(newViolations), [newViolations[1]])
    }

    func testNewViolationsAtStart() {
        testNewViolation(
            violations: violations,
            newViolationRuleDescription: BlanketDisableCommandRule.description,
            insertionIndex: 0
        )
    }

    func testNewViolationsInTheMiddle() {
        testNewViolation(
            violations: violations,
            newViolationRuleDescription: ArrayInitRule.description,
            insertionIndex: 2
        )
    }

//    func testLongerViolations() {
//        for i in 0..<10 {
//            testLongerViolations(ruleDescription: ArrayInitRule.description, insertionIndex: i)
//        }
//    }

    func testLongerViolations(ruleDescription: RuleDescription, insertionIndex: Int) {
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

        testNewViolation(
            violations: violations,
            newViolationRuleDescription: ArrayInitRule.description,
            insertionIndex: insertionIndex
        )
    }

    private func testNewViolation(
        violations: [StyleViolation],
        lineShift: Int = 1,
        newViolationRuleDescription: RuleDescription,
        insertionIndex: Int
    ) {
        let baseline = Baseline(violations: violations)
        var newViolations = lineShift != 0 ? violations.lineShifted(by: lineShift) : violations
        let line = ((insertionIndex + 1) * 5) - 2
        let violation = StyleViolation(
            ruleDescription: newViolationRuleDescription,
            location: Location(file: #file, line: line, character: 1)
        )
        newViolations.insert(violation, at: insertionIndex)
        XCTAssertEqual(baseline.filter(newViolations), [violation])
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
                location: Location(file: #file, line: (index + 1) * 5, character: 1)
            )
        }
    }
}
