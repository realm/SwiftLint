@testable import SwiftLintFramework
import XCTest

class ExpiringTodoRuleTests: XCTestCase {
    private lazy var config: Configuration = makeConfiguration()

    override func setUp() {
        super.setUp()

        config = makeConfiguration()
    }

    func testExpiringTodo() {
        verifyRule(ExpiringTodoRule.description, commentDoesntViolate: false)
    }

    func testExpiredTodo() {
        let example = Example("fatalError() // TODO: [\(dateString(for: .expired))] Implement")
        let violations = self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODO/FIXME has expired and must be resolved")
    }

    func testExpiredFixMe() {
        let example = Example("fatalError() // FIXME: [\(dateString(for: .expired))] Implement")
        let violations = self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODO/FIXME has expired and must be resolved")
    }

    func testApproachingExpiryTodo() {
        let example = Example("fatalError() // TODO: [\(dateString(for: .approachingExpiry))] Implement")
        let violations = self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODO/FIXME is approaching its expiry and should be resolved soon")
    }

    func testNonExpiredTodo() {
        let example = Example("fatalError() // TODO: [\(dateString(for: nil))] Implement")
        XCTAssertEqual(violations(example).count, 0)
    }

    func testExpiredCustomDelimiters() {
        let ruleConfig: ExpiringTodoConfiguration = .init(
            dateDelimiters: .init(opening: "<", closing: ">")
        )
        config = makeConfiguration(with: ruleConfig)

        let example = Example("fatalError() // TODO: <\(dateString(for: .expired))> Implement")
        let violations = self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODO/FIXME has expired and must be resolved")
    }

    func testExpiredCustomSeparator() {
        let ruleConfig: ExpiringTodoConfiguration = .init(
            dateFormat: "MM-dd-yyyy",
            dateSeparator: "-"
        )
        config = makeConfiguration(with: ruleConfig)

        let example = Example("fatalError() // TODO: [\(dateString(for: .expired))] Implement")
        let violations = self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODO/FIXME has expired and must be resolved")
    }

    func testExpiredCustomFormat() {
        let ruleConfig: ExpiringTodoConfiguration = .init(
            dateFormat: "yyyy/MM/dd"
        )
        config = makeConfiguration(with: ruleConfig)

        let example = Example("fatalError() // TODO: [\(dateString(for: .expired))] Implement")
        let violations = self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODO/FIXME has expired and must be resolved")
    }

    func testMultipleExpiredTodos() {
        let example = Example(
            """
            fatalError() // TODO: [\(dateString(for: .expired))] Implement one
            fatalError() // TODO: Implement two by [\(dateString(for: .expired))]
            """
        )
        let violations = self.violations(example)
        XCTAssertEqual(violations.count, 2)
        XCTAssertEqual(violations[0].reason, "TODO/FIXME has expired and must be resolved")
        XCTAssertEqual(violations[0].location.line, 1)
        XCTAssertEqual(violations[1].reason, "TODO/FIXME has expired and must be resolved")
        XCTAssertEqual(violations[1].location.line, 2)
    }

    func testTodoAndExpiredTodo() {
        let example = Example(
            """
            // TODO: Implement one - without deadline
            fatalError()
            // TODO: Implement two by [\(dateString(for: .expired))]
            """
        )
        let violations = self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations[0].reason, "TODO/FIXME has expired and must be resolved")
        XCTAssertEqual(violations[0].location.line, 3)
    }

    func testMultilineExpiredTodo() {
        let example = Example(
            """
            // TODO: Multi-line task
            //       for: @MATODOLU
            //       deadline: [\(dateString(for: .expired))]
            //       severity: fatal
            """
        )
        let violations = self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations[0].reason, "TODO/FIXME has expired and must be resolved")
        XCTAssertEqual(violations[0].location.line, 3)
    }

    func testTodoFunctionAndExpiredTodo() {
        let example = Example(
            """
            TODO()
            // TODO: Implement two by [\(dateString(for: .expired))]
            """
        )
        let violations = self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations[0].reason, "TODO/FIXME has expired and must be resolved")
        XCTAssertEqual(violations[0].location.line, 2)
    }

    func testBadExpiryTodoFormat() throws {
        let ruleConfig: ExpiringTodoConfiguration = .init(
            dateFormat: "dd/yyyy/MM"
        )
        config = makeConfiguration(with: ruleConfig)

        let example = Example("fatalError() // TODO: [31/01/2020] Implement")
        let violations = self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Expiring TODO/FIXME is incorrectly formatted")
    }

    private func violations(_ example: Example) -> [StyleViolation] {
        return SwiftLintFrameworkTests.violations(example, config: config)
    }

    private func dateString(for status: ExpiringTodoRule.ExpiryViolationLevel?) -> String {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = config.ruleConfiguration.dateFormat

        return formatter.string(from: date(for: status))
    }

    private func date(for status: ExpiringTodoRule.ExpiryViolationLevel?) -> Date {
        let ruleConfiguration = config.ruleConfiguration

        let daysToAdvance: Int

        switch status {
        case .approachingExpiry?:
            daysToAdvance = ruleConfiguration.approachingExpiryThreshold
        case .expired?:
            daysToAdvance = 0
        case .badFormatting?, nil:
            daysToAdvance = ruleConfiguration.approachingExpiryThreshold + 1
        }

        return Calendar.current
            .date(
                byAdding: .day,
                value: daysToAdvance,
                to: .init()
            )!
    }

    private func makeConfiguration(with ruleConfiguration: ExpiringTodoConfiguration? = nil) -> Configuration {
        var serializedConfig: [String: Any]?

        if let config = ruleConfiguration {
            serializedConfig = [
                "expired_severity": config.expiredSeverity.severity.rawValue,
                "approaching_expiry_severity": config.approachingExpirySeverity.severity.rawValue,
                "bad_formatting_severity": config.badFormattingSeverity.severity.rawValue,
                "approaching_expiry_threshold": config.approachingExpiryThreshold,
                "date_format": config.dateFormat,
                "date_delimiters": [
                    "opening": config.dateDelimiters.opening,
                    "closing": config.dateDelimiters.closing
                ],
                "date_separator": config.dateSeparator
            ]
        }

        return makeConfig(serializedConfig, ExpiringTodoRule.description.identifier)!
    }
}

fileprivate extension Configuration {
    var ruleConfiguration: ExpiringTodoConfiguration {
        // swiftlint:disable:next force_cast
        return (rules.first(where: { $0 is ExpiringTodoRule }) as! ExpiringTodoRule).configuration
    }
}
