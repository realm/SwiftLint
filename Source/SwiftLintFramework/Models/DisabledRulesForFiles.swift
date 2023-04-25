import Foundation

/// Simple data structure containing the names of rules, as keys, and lists of regular expressions.
/// If any of those regular expressions matches a filename, then the rule is NOT applied to the file
public typealias DisabledRulesForFiles = [String: [NSRegularExpression]]

public extension DisabledRulesForFiles {
    /// Empty value, used when no rules have been provided in our config YML file
    static let empty: DisabledRulesForFiles = [:]

    /// Given a rule identifier and a file, returns true if this rule should NOT be applied to the file,
    /// because it has been disabled in our `disabled_rules_for_files` declaration
    func isDisabled(ruleIdentifier: String, file: SwiftLintFile) -> Bool {
        if let disabledFileRegexps = self[ruleIdentifier],
           disabledFileRegexps.contains(where: {
               return $0.matches(in: file.file.path ?? "",
                                 options: [],
                                 range: NSRange(location: 0,
                                                length: file.file.path?.count ?? 0)
               ).isNotEmpty
           }) {
            return true
        }

        return false
    }
}
