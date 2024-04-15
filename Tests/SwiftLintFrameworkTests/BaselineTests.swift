@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
import XCTest

private var temporaryFilePath: String {
    let result = URL(
        fileURLWithPath: NSTemporaryDirectory(),
        isDirectory: true
    ).appendingPathComponent(UUID().uuidString).path

#if os(macOS)
    return "/private" + result
#else
    return result
#endif
}

private var sourceFilePath: String = {
    temporaryFilePath + ".swift"
}()

final class BaselineTests: XCTestCase {
    private static let example = """
                                 import Foundation
                                 import SwiftLintFramework

                                 class Example: NSObject {
                                     private var foo: Int
                                     private var bar: String

                                     init(foo: Int, bar: String) {
                                         self.foo = foo
                                         self.bar = bar
                                     } // init
                                     func someFunction() -> Int {
                                         foo * 10
                                     } // someFunction
                                     func someOtherFunction() -> String {
                                         bar
                                     } // someOtherFunction
                                     func yetAnotherFunction() -> (Int, String) {
                                         (foo, bar)
                                     } // yetAnotherFunction
                                 }
                                 """

    private static let violations = [
        ArrayInitRule.description,
        BlockBasedKVORule.description,
        ClosingBraceRule.description,
        DirectReturnRule.description
    ].violations

    private static let baseline = Baseline(violations: violations)

    private var currentDirectoryPath: String?

    override func setUpWithError() throws {
        try super.setUpWithError()
        currentDirectoryPath = FileManager.default.currentDirectoryPath
        let testDirectoryPath = sourceFilePath.bridge().deletingLastPathComponent
        XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(testDirectoryPath))
    }

    override func tearDownWithError() throws {
        if let currentDirectoryPath {
            XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(currentDirectoryPath))
            self.currentDirectoryPath = nil
        }
        try super.tearDownWithError()
    }

    func testWritingAndReading() throws {
        try testBlock {
            let baselinePath = temporaryFilePath
            try Baseline(violations: Self.violations).write(toPath: baselinePath)
            defer {
                try? FileManager.default.removeItem(atPath: baselinePath)
            }
            let newBaseline = try Baseline(fromPath: baselinePath)
            XCTAssertEqual(newBaseline, Self.baseline)
        }
    }

    func testUnchangedViolations() throws {
        try testBlock { XCTAssertEqual(Self.baseline.filter(Self.violations), []) }
    }

    func testShiftedViolations() throws {
        try testBlock {
            XCTAssertEqual(Self.baseline.filter(try Self.violations.lineShifted(by: 2, path: sourceFilePath)), [])
        }
    }

    func testNewViolation() throws {
        try testViolationDetection(
            violations: Self.violations,
            newViolationRuleDescription: EmptyCollectionLiteralRule.description,
            insertionIndex: 2
        )
    }

    func testViolationsWithNoFile() throws {
        try testViolationDetection(
            violations: Self.violations.map { $0.with(location: Location(file: nil)) },
            lineShift: 0,
            newViolationRuleDescription: ArrayInitRule.description,
            insertionIndex: 2
        )
    }

    func testViolationDetection() throws {
        let violations = [
            ArrayInitRule.description,
            BlockBasedKVORule.description,
            ArrayInitRule.description,
            ClosingBraceRule.description,
            ClosingBraceRule.description,
            ClosingBraceRule.description,
            BlockBasedKVORule.description,
            DirectReturnRule.description,
            ArrayInitRule.description,
            ClosingBraceRule.description
        ].violations

        let ruleDescriptions = [
            ArrayInitRule.description,
            BlockBasedKVORule.description,
            ClosingBraceRule.description,
            DirectReturnRule.description
        ]

        for ruleDescription in ruleDescriptions {
            for insertionIndex in 0..<violations.count {
                try testViolationDetection(
                    violations: violations,
                    newViolationRuleDescription: ruleDescription,
                    insertionIndex: insertionIndex
                )
            }
            break
        }
    }

    func testCompare() throws {
        try testBlock {
            let oldViolations = Array(Self.violations.dropFirst())
            let newViolations = Array(Self.violations.dropLast())
            let oldBaseline = Baseline(violations: oldViolations)
            let newBaseline = Baseline(violations: newViolations)
            XCTAssertEqual(oldBaseline.compare(newBaseline), [Self.violations.first])
            XCTAssertEqual(newBaseline.compare(oldBaseline), [Self.violations.last])
        }
    }

    private func testViolationDetection(
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
        guard let data = Self.example.data(using: .utf8) else {
            XCTFail("Could not convert example code to data using utf8 encoding")
            return
        }
        try data.write(to: URL(fileURLWithPath: sourceFilePath))
        defer {
            try? FileManager.default.removeItem(atPath: sourceFilePath)
        }
        try block()
    }
}

private extension [StyleViolation] {
    func lineShifted(by shift: Int, path: String) throws -> [StyleViolation] {
        guard let file = first?.location.file else {
            XCTFail("Cannot shift non-existent file")
            return self
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
                line: $0.location.line != nil ? $0.location.line! + shift : nil,
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
