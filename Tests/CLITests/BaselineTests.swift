@testable import swiftlint
@testable import SwiftLintBuiltInRules
import XCTest

private var temporaryFilePath: String {
    // FileManager currentDirectoryPath prepends "/private" to the temporary directory path
    "/private" + FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path + ".swift"
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
        try testBlock {
            let baselinePath = temporaryFilePath
            let baseline = baseline
            try Baseline.write(violations, toPath: baselinePath)
            defer {
                try? FileManager.default.removeItem(atPath: baselinePath)
            }
            let newBaseline = try Baseline(fromPath: baselinePath)
            XCTAssertEqual(newBaseline, baseline)
        }
    }

    func testUnchangedViolations() throws {
        try testBlock { XCTAssertEqual(baseline.filter(violations), []) }
    }

    func testShiftedViolations() throws {
        try testBlock {
            XCTAssertEqual(baseline.filter(try violations.lineShifted(by: 2, path: sourceFilePath)), [])
        }
    }

    func testNewViolations() throws {
        try testNewViolation(
            violations: violations,
            newViolationRuleDescription: BlanketDisableCommandRule.description,
            insertionIndex: 2
        )
    }

    func testNewIdenticalViolationAtStart() throws {
        try testBlock {
            let baseline = baseline
            var newViolations = try violations.lineShifted(by: 1, path: sourceFilePath)
            let violation = StyleViolation(
                ruleDescription: ArrayInitRule.description,
                location: Location(file: sourceFilePath, line: 2, character: 1)
            )
            newViolations.insert(violation, at: 0)
            XCTAssertEqual(baseline.filter(newViolations), [violation])
        }
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
        ].violations

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
        try testBlock {
            let baseline = Baseline(violations: violations)
            var newViolations = lineShift != 0
                ? try violations.lineShifted(by: lineShift, path: sourceFilePath)
                : violations
            let line = ((insertionIndex + 1) * 2) - 1 + lineShift
            let violation = StyleViolation(
                ruleDescription: newViolationRuleDescription,
                location: Location(file: sourceFilePath, line: line, character: 1)
            )
            newViolations.insert(violation, at: insertionIndex)
            XCTAssertEqual(baseline.filter(newViolations), [violation])
        }
    }

    private func testBlock(_ block: () throws -> Void) throws {
        let fixturesDirectory = "\(TestResources.path)/BaselineFixtures"
        let filePath = fixturesDirectory.bridge().appendingPathComponent("Example.swift")

        try FileManager.default.copyItem(atPath: filePath, toPath: sourceFilePath)
        defer {
            try? FileManager.default.removeItem(atPath: sourceFilePath)
        }
        let currentDirectoryPath = FileManager.default.currentDirectoryPath
        let testDirectoryPath = sourceFilePath.bridge().deletingLastPathComponent
        XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(testDirectoryPath))
        defer {
            XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(currentDirectoryPath))
        }
        try block()
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
        lines = [String](repeating: "", count: shift) + lines
        if let data = lines.joined(separator: "\n").data(using: .utf8) {
            try data.write(to: URL(fileURLWithPath: path))
        }
        return map {
            let shiftedLocation = Location(
                file: path,
                line: $0.location.line != nil ? ($0.location.line ?? 0) + shift : nil,
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
                location: Location(file: sourceFilePath, line: (index + 1) * 2, character: 1)
            )
        }
    }
}

private enum TestResources {
    static var path: String {
        if let rootProjectDirectory = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"] {
            return "\(rootProjectDirectory)/Tests/CLITests/Resources"
        }

        return URL(fileURLWithPath: #file, isDirectory: false)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .path
            .absolutePathStandardized()
    }
}
