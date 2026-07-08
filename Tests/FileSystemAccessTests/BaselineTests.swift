import Foundation
import SourceKittenFramework
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore

// swiftlint:disable:next blanket_disable_command
// swiftlint:disable contains_over_filter_is_empty

@Suite(.rulesRegistered)
struct BaselineTests {
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

    private static func violations(for filePath: URL?) -> [StyleViolation] {
        ruleDescriptions.violations(for: filePath)
    }

    private static func baseline(for filePath: URL) -> Baseline {
        Baseline(violations: ruleDescriptions.violations(for: filePath))
    }

    @Test(.temporaryDirectory)
    func writingAndReading() throws {
        try withExampleFileCreated { sourceFilePath in
            let baselinePath = URL.cwd.appending(path: UUID().uuidString)
            try Baseline(violations: Self.violations(for: sourceFilePath)).write(toPath: baselinePath)
            let newBaseline = try Baseline(fromPath: baselinePath)
            #expect(newBaseline == Self.baseline(for: sourceFilePath))
        }
    }

    @Test(.temporaryDirectory)
    func writingUsesRelativeFilePaths() throws {
        try withExampleFileCreated { sourceFilePath in
            try FileManager.default.createDirectory(
                at: URL.cwd.appending(path: "folder", directoryHint: .isDirectory),
                withIntermediateDirectories: true
            )
            let otherSourceFilePath = URL.cwd
                .appending(path: "folder", directoryHint: .isDirectory)
                .appending(path: "\(UUID().uuidString).swift", directoryHint: .notDirectory)
            try Self.example.write(to: otherSourceFilePath, atomically: true, encoding: .utf8)

            let baselinePath = URL.cwd.appending(path: UUID().uuidString)
            let violations = Self.violations(for: sourceFilePath) + Self.violations(for: otherSourceFilePath)
            try Baseline(violations: violations).write(toPath: baselinePath)

            let json = try String(contentsOf: baselinePath, encoding: .utf8)
            #expect(!json.contains(sourceFilePath.path))
            #expect(!json.contains(otherSourceFilePath.path))
            #expect(!json.contains("file://"))
            #expect(!json.contains("/var/"))

            #expect(json.contains("\"\(sourceFilePath.lastPathComponent)\""))
            #expect(json.contains("\"folder\\/\(otherSourceFilePath.lastPathComponent)\""))
        }
    }

    @Test(.temporaryDirectory)
    func unchangedViolations() throws {
        try withExampleFileCreated { sourceFilePath in
            #expect(Self.baseline(for: sourceFilePath).filter(Self.violations(for: sourceFilePath)).isEmpty)
        }
    }

    @Test(.temporaryDirectory)
    func shiftedViolations() throws {
        try withExampleFileCreated { sourceFilePath in
            let baseline = Self.baseline(for: sourceFilePath)
            let violations = try Self.violations(for: sourceFilePath).lineShifted(by: 2, path: sourceFilePath)
            #expect(baseline.filter(violations).isEmpty)
        }
    }

    @Test(.temporaryDirectory)
    func newViolation() throws {
        try testViolationDetection(
            violationRuleDescriptions: Self.ruleDescriptions,
            newViolationRuleDescription: EmptyCollectionLiteralRule.description,
            insertionIndex: 2
        )
    }

    @Test(
        .temporaryDirectory,
        arguments: [
            ArrayInitRule.description,
            BlockBasedKVORule.description,
            ClosingBraceRule.description,
            DirectReturnRule.description,
        ]
    )
    func violationDetection(_ ruleDescription: RuleDescription) throws {
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

        for insertionIndex in 0..<violationRuleDescriptions.count {
            try testViolationDetection(
                violationRuleDescriptions: violationRuleDescriptions,
                newViolationRuleDescription: ruleDescription,
                insertionIndex: insertionIndex
            )
        }
    }

    @Test(.temporaryDirectory)
    func compare() throws {
        try withExampleFileCreated { sourceFilePath in
            let ruleDescriptions = Self.ruleDescriptions + Self.ruleDescriptions
            let violations = ruleDescriptions.violations(for: sourceFilePath)
            let numberOfViolationsToDrop = 3
            let oldBaseline = Baseline(
                violations: Array(violations.dropFirst(numberOfViolationsToDrop)).reversed()
            )
            let newViolations = Array(
                try violations.lineShifted(by: 2, path: sourceFilePath).dropLast(numberOfViolationsToDrop)
            )
            let newBaseline = Baseline(violations: newViolations.reversed())
            #expect(oldBaseline.compare(newBaseline) == Array(newViolations.prefix(numberOfViolationsToDrop)))
            #expect(newBaseline.compare(oldBaseline) == Array(violations.suffix(numberOfViolationsToDrop)))
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
            #expect(baseline.filter(newViolations) == [violation])
        }
    }

    private func withExampleFileCreated(_ block: (URL) throws -> Void) throws {
        let sourceFilePath = URL.cwd.appending(
            path: "\(UUID().uuidString).swift",
            directoryHint: .notDirectory
        )
        try Self.example.write(to: sourceFilePath, atomically: true, encoding: .utf8)
        try block(sourceFilePath)
    }
}

private extension [StyleViolation] {
    func lineShifted(by shift: Int, path: URL) throws -> [StyleViolation] {
        guard shift > 0 else {
            Issue.record("Shift must be positive")
            return self
        }
        var lines = SwiftLintFile(path: path)?.lines.map(\.content) ?? []
        lines = [String](repeating: "", count: shift) + lines
        if let data = lines.joined(separator: "\n").data(using: .utf8) {
            try data.write(to: path)
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
    func violations(for filePath: URL?) -> [StyleViolation] {
        enumerated().map { index, ruleDescription in
            StyleViolation(
                ruleDescription: ruleDescription,
                location: Location(file: filePath, line: (index + 1) * 2, character: 1)
            )
        }
    }
}
