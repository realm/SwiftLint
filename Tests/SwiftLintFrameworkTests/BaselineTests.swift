@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
import XCTest

private var temporaryDirectoryPath: String {
    let result = URL(
        fileURLWithPath: NSTemporaryDirectory(),
        isDirectory: true
    ).path

#if os(macOS)
    return "/private" + result
#else
    return result
#endif
}

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

    private static let ruleDescriptions = [
        ArrayInitRule.description,
        BlockBasedKVORule.description,
        ClosingBraceRule.description,
        DirectReturnRule.description,
    ]

    private static var currentDirectoryPath: String?

    private static func violations(for filePath: String?) -> [StyleViolation] {
        ruleDescriptions.violations(for: filePath)
    }

    private static func baseline(for filePath: String) -> Baseline {
        Baseline(violations: ruleDescriptions.violations(for: filePath))
    }

    override static func setUp() {
        super.setUp()
        currentDirectoryPath = FileManager.default.currentDirectoryPath
        XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(temporaryDirectoryPath))
    }

    override static func tearDown() {
        if let currentDirectoryPath {
            XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(currentDirectoryPath))
            self.currentDirectoryPath = nil
        }
        super.tearDown()
    }

    func testWritingAndReading() throws {
        try withExampleFileCreated { sourceFilePath in
            let baselinePath = temporaryDirectoryPath.stringByAppendingPathComponent(UUID().uuidString)
            try Baseline(violations: Self.violations(for: sourceFilePath)).write(toPath: baselinePath)
            defer {
                try? FileManager.default.removeItem(atPath: baselinePath)
            }
            let newBaseline = try Baseline(fromPath: baselinePath)
            XCTAssertEqual(newBaseline, Self.baseline(for: sourceFilePath))
        }
    }

    func testUnchangedViolations() throws {
        try withExampleFileCreated { sourceFilePath in
            XCTAssertEqual(Self.baseline(for: sourceFilePath).filter(Self.violations(for: sourceFilePath)), [])
        }
    }

    func testShiftedViolations() throws {
        try withExampleFileCreated { sourceFilePath in
            let baseline = Self.baseline(for: sourceFilePath)
            let violations = try Self.violations(for: sourceFilePath).lineShifted(by: 2, path: sourceFilePath)
            XCTAssertEqual(baseline.filter(violations), [])
        }
    }

    func testNewViolation() throws {
        try testViolationDetection(
            violationRuleDescriptions: Self.ruleDescriptions,
            newViolationRuleDescription: EmptyCollectionLiteralRule.description,
            insertionIndex: 2
        )
    }

    func testViolationDetection() throws {
        let violationRuleDescriptions = [
            ArrayInitRule.description,
            BlockBasedKVORule.description,
            ArrayInitRule.description,
            ClosingBraceRule.description,
            ClosingBraceRule.description,
            ClosingBraceRule.description,
            BlockBasedKVORule.description,
            DirectReturnRule.description,
            ArrayInitRule.description,
            ClosingBraceRule.description,
        ]

        let ruleDescriptions = [
            ArrayInitRule.description,
            BlockBasedKVORule.description,
            ClosingBraceRule.description,
            DirectReturnRule.description,
        ]

        for ruleDescription in ruleDescriptions {
            for insertionIndex in 0..<violationRuleDescriptions.count {
                try testViolationDetection(
                    violationRuleDescriptions: violationRuleDescriptions,
                    newViolationRuleDescription: ruleDescription,
                    insertionIndex: insertionIndex
                )
            }
        }
    }

    func testCompare() throws {
        try withExampleFileCreated { sourceFilePath in
            let ruleDescriptions = Self.ruleDescriptions + Self.ruleDescriptions
            let violations = ruleDescriptions.violations(for: sourceFilePath)
            let numberofViolationsToDrop = 3
            let oldBaseline = Baseline(violations: Array(violations.dropFirst(numberofViolationsToDrop)).reversed())
            let newViolations = Array(
                try violations.lineShifted(by: 2, path: sourceFilePath).dropLast(numberofViolationsToDrop)
            )
            let newBaseline = Baseline(violations: newViolations.reversed())
            XCTAssertEqual(oldBaseline.compare(newBaseline), Array(newViolations.prefix(numberofViolationsToDrop)))
            XCTAssertEqual(newBaseline.compare(oldBaseline), Array(violations.suffix(numberofViolationsToDrop)))
        }
    }

    // MARK: - Private

    private func testViolationDetection(
        violationRuleDescriptions: [RuleDescription],
        lineShift: Int = 1,
        newViolationRuleDescription: RuleDescription,
        insertionIndex: Int
    ) throws {
        try withExampleFileCreated { sourceFilePath in
            let violations = violationRuleDescriptions.violations(for: sourceFilePath)
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

    private func withExampleFileCreated(_ block: (String) throws -> Void) throws {
        let sourceFilePath = temporaryDirectoryPath.stringByAppendingPathComponent("\(UUID().uuidString).swift")
        guard let data = Self.example.data(using: .utf8) else {
            XCTFail("Could not convert example code to data using UTF-8 encoding")
            return
        }
        try data.write(to: URL(fileURLWithPath: sourceFilePath))
        defer {
            try? FileManager.default.removeItem(atPath: sourceFilePath)
        }
        try block(sourceFilePath)
    }
}

private extension [StyleViolation] {
    func lineShifted(by shift: Int, path: String) throws -> [StyleViolation] {
        guard shift > 0 else {
            XCTFail("Shift must be positive")
            return self
        }
        var lines = SwiftLintFile(path: path)?.lines.map(\.content) ?? []
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
    func violations(for filePath: String?) -> [StyleViolation] {
        enumerated().map { index, ruleDescription in
            StyleViolation(
                ruleDescription: ruleDescription,
                location: Location(file: filePath, line: (index + 1) * 2, character: 1)
            )
        }
    }
}
