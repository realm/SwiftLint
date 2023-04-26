import Foundation

/// Utility to measure the time spent in each custom rule.
public final class CustomRuleTimer {
    private let lock = NSLock()
    private var ruleIDForTimes = [String: [TimeInterval]]()
    private var shouldRecord = false

    /// Singleton.
    public static let shared = CustomRuleTimer()

    /// Tell the timer it should record time spent in rules.
    public func activate() {
        shouldRecord = true
    }

    /// Return all time spent for each custom rule, keyed by rule ID.
    public func dump() -> [String: TimeInterval] {
        ruleIDForTimes.mapValues { $0.reduce(0, +) }
    }

    /// Register time spent evaluating a rule with the specified ID.
    ///
    /// - parameter time:   The time interval spent evaluating this rule ID.
    /// - parameter ruleID: The ID of the rule that was evaluated.
    func register(time: TimeInterval, forRuleID ruleID: String) {
        guard shouldRecord else { return }

        lock.lock()
        defer { lock.unlock() }
        ruleIDForTimes[ruleID, default: []].append(time)
    }
}
