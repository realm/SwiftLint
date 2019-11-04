@testable import SwiftLintFramework
import XCTest

class ExpiringTodoRuleTests: XCTestCase {
    private let config = makeConfig(nil, ExpiringTodoRule.description.identifier)!

    func testExpiringTodo() {
        verifyRule(ExpiringTodoRule.description, commentDoesntViolate: false)
    }

    func testExpiredTodo() {
        let string = "fatalError() // TODO: [\(dateString(for: .expired))] Implement"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODO/FIXME has expired and must be resolved.")
    }

    func testExpiredFixMe() {
        let string = "fatalError() // FIXME: [\(dateString(for: .expired))] Implement"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODO/FIXME has expired and must be resolved.")
    }

    func testApproachingExpiryTodo() {
        let string = "fatalError() // TODO: [\(dateString(for: .approachingExpiry))] Implement"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODO/FIXME is approaching its expiry and should be resolved soon.")
    }

    func testNonExpiredTodo() {
        let string = "fatalError() // TODO: [\(dateString(for: nil))] Implement"
        XCTAssertEqual(violations(string).count, 0)
    }

    private func violations(_ string: String) -> [StyleViolation] {
        return SwiftLintFrameworkTests.violations(string, config: config)
    }

    private func dateString(for status: ExpiringTodoRule.ExpiryViolationLevel?) -> String {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "MM/dd/yyyy"

        return formatter.string(from: date(for: status))
    }

    private func date(for status: ExpiringTodoRule.ExpiryViolationLevel?) -> Date {
        // swiftlint:disable:next force_cast
        let rule = config.rules.first(where: { $0 is ExpiringTodoRule }) as! ExpiringTodoRule

        let daysToAdvance: Int

        switch status {
        case .approachingExpiry?:
            daysToAdvance = rule.configuration.approachingExpiryThreshold
        case .expired?:
            daysToAdvance = 0
        case nil:
            daysToAdvance = rule.configuration.approachingExpiryThreshold + 1
        }

        return Calendar.current
            .date(
                byAdding: .day,
                value: daysToAdvance,
                to: .init()
            )!
    }
}
