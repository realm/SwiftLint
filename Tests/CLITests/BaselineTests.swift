@testable import swiftlint
@testable import SwiftLintBuiltInRules
import SwiftLintFramework
import XCTest

private var temporaryFilePath: String {
//    FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
    URL(fileURLWithPath: "/private/tmp/").appendingPathComponent(UUID().uuidString).path
}

private var sourceFilePath: String = {
    temporaryFilePath
}()

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
        let baselinePath = temporaryFilePath
        try FileManager.default.copyItem(atPath: #file, toPath: sourceFilePath)
        let baseline = baseline
        try Baseline.write(violations, toPath: baselinePath)
        let newBaseline = try Baseline(fromPath: baselinePath)
        try FileManager.default.removeItem(atPath: baselinePath)
        try FileManager.default.removeItem(atPath: sourceFilePath)
        XCTAssertEqual(newBaseline, baseline)
    }

    func testUnchangedViolations() throws {
        XCTAssertEqual(baseline.filter(violations), [])
    }

    func testShiftedViolations() throws {
        try FileManager.default.copyItem(atPath: #file, toPath: sourceFilePath)
        let currentDirectoryPath = FileManager.default.currentDirectoryPath
        // swiftlint:disable:next legacy_objc_type
        let testDirectoryPath = (sourceFilePath as NSString).deletingLastPathComponent
        XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(testDirectoryPath))
        XCTAssertEqual(baseline.filter(try violations.lineShifted(by: 2, path: sourceFilePath)), [])
        try FileManager.default.removeItem(atPath: sourceFilePath)
        XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(currentDirectoryPath))
    }

    func testNewViolations() throws {
        try testNewViolation(
            violations: violations,
            newViolationRuleDescription: BlanketDisableCommandRule.description,
            insertionIndex: 2
        )
    }

    func testNewIdenticalViolationAtStart() throws {
        try FileManager.default.copyItem(atPath: #file, toPath: sourceFilePath)
        defer {
            try? FileManager.default.removeItem(atPath: sourceFilePath)
        }
        let currentDirectoryPath = FileManager.default.currentDirectoryPath
        // swiftlint:disable:next legacy_objc_type
        let testDirectoryPath = (sourceFilePath as NSString).deletingLastPathComponent
        XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(testDirectoryPath))
        defer {
            XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(currentDirectoryPath))
        }

        let baseline = baseline
        var newViolations = try violations.lineShifted(by: 1, path: sourceFilePath)
        let violation = StyleViolation(
            ruleDescription: ArrayInitRule.description,
            location: Location(file: sourceFilePath, line: 1, character: 1)
        )
        newViolations.insert(violation, at: 0)
        XCTAssertEqual(baseline.filter(newViolations), [violation])
    }

    func testNewViolationsAtStart() throws {
        try testNewViolation(
            violations: violations,
            newViolationRuleDescription: BlanketDisableCommandRule.description,
            insertionIndex: 0
        )
    }

    func testNewViolationsInTheMiddle() throws {
        try testNewViolation(
            violations: violations,
            newViolationRuleDescription: ArrayInitRule.description,
            insertionIndex: 2
        )
    }

    func testLongerViolations() throws {
        for insertionIndex in 0..<10 {
            try testLongerViolations(ruleDescription: ArrayInitRule.description, insertionIndex: insertionIndex)
        }
    }

    private func testLongerViolations(ruleDescription: RuleDescription, insertionIndex: Int) throws {
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
        ].violations.shuffled()

        try testNewViolation(
            violations: violations,
            newViolationRuleDescription: ruleDescription,
            insertionIndex: insertionIndex
        )
    }

    private func testNewViolation(
        violations: [StyleViolation],
        lineShift: Int = 1,
        newViolationRuleDescription: RuleDescription,
        insertionIndex: Int
    ) throws {
        try FileManager.default.copyItem(atPath: #file, toPath: sourceFilePath)
        defer {
            try? FileManager.default.removeItem(atPath: sourceFilePath)
        }
        let currentDirectoryPath = FileManager.default.currentDirectoryPath
        // swiftlint:disable:next legacy_objc_type
        let testDirectoryPath = (sourceFilePath as NSString).deletingLastPathComponent
        XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(testDirectoryPath))
        defer {
            XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(currentDirectoryPath))
        }

        let baseline = Baseline(violations: violations)
        var newViolations = lineShift != 0 ?
            try violations.lineShifted(by: lineShift, path: sourceFilePath) : violations
        let line = ((insertionIndex + 1) * 5) - 2
        let violation = StyleViolation(
            ruleDescription: newViolationRuleDescription,
            location: Location(file: sourceFilePath, line: line, character: 1)
        )
        newViolations.insert(violation, at: insertionIndex)
        XCTAssertEqual(baseline.filter(newViolations), [violation])
    }
}

private extension [StyleViolation] {
    func lineShifted(by shift: Int, path: String) throws -> [StyleViolation] {
        guard let file = first?.location.file else {
            XCTFail("Cannot shift non-existent file")
            return []
        }
        guard shift > 0 else {
            XCTFail("Shift must be positive")
            return self
        }
        var lines = SwiftLintFile(path: file)?.lines.map({ $0.content }) ?? []
        var blankLines: [String] = []
        for _ in 0..<shift {
            blankLines.append("")
        }
//        let blankLines = Array(repeating: "", count: shift)
        lines = blankLines + lines
        if let data = lines.joined(separator: "\n").data(using: .utf8) {
            try data.write(to: URL(fileURLWithPath: path))
        }
        return map {
            let shiftedLocation = Location(
                file: path,
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
                location: Location(file: sourceFilePath, line: (index + 1) * 5, character: 1)
            )
        }
    }
}
