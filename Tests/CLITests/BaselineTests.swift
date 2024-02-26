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
            ArrayInitRule.description,
            BlanketDisableCommandRule.description,
            ClosingBraceRule.description,
            DirectReturnRule.description
        ].enumerated().map { index, ruleDescription in
            StyleViolation(
                ruleDescription: ruleDescription,
                location: Location(file: path, line: (index + 1) * 5, character: 1)
            )
        }
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
        XCTAssertEqual(baseline, newBaseline)
    }

    func testUnchangedViolations() throws {
        XCTAssertEqual([], baseline.filter(violations))
    }

    func testShiftedViolations() throws {
        XCTAssertEqual([], baseline.filter(violations.lineShifted(by: 2)))
    }

    func testNewViolations() {
        var newViolations = violations
        let violation = StyleViolation(
            ruleDescription: BlanketDisableCommandRule.description,
            location: Location(file: path, line: 12, character: 1)
        )
        newViolations.insert(violation, at: 2)
        XCTAssertEqual([violation], baseline.filter(newViolations))
    }

    func testNewIdenticalViolationAtStart() {
        var newViolations = violations.lineShifted(by: 1)
        let violation = StyleViolation(
            ruleDescription: ArrayInitRule.description,
            location: Location(file: path, line: 1, character: 1)
        )
        newViolations.insert(violation, at: 0)
        // This is the wrong answer. We really want the first violation
        XCTAssertEqual([newViolations[1]], baseline.filter(newViolations))
    }

    func testNewViolationsAtStart() {
        var newViolations = violations.lineShifted(by: 1)
        let violation = StyleViolation(
            ruleDescription: BlanketDisableCommandRule.description,
            location: Location(file: path, line: 1, character: 1)
        )
        newViolations.insert(violation, at: 0)
        XCTAssertEqual([violation], baseline.filter(newViolations))
    }
}

private extension Sequence where Element == StyleViolation {
    func lineShifted(by shift: Int) -> [StyleViolation] {
        map { $0.with(locationLineShiftedBy: 1)
            let shiftedLocation = Location(
                file: $0.location.file,
                line: ($0.location.line ?? 0) + shift,
                character: $0.location.character
            )
            return $0.with(location: shiftedLocation)
        }
    }
}

