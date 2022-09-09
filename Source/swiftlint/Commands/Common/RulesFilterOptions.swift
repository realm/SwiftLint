import ArgumentParser
import Foundation

enum RuleEnablementOptions: String, EnumerableFlag {
    case enabled, disabled

    static func name(for value: RuleEnablementOptions) -> NameSpecification {
        return .shortAndLong
    }

    static func help(for value: RuleEnablementOptions) -> ArgumentHelp? {
        return "Only show \(value.rawValue) rules"
    }
}

struct RulesFilterOptions: ParsableArguments {
    @Flag(exclusivity: .exclusive)
    var ruleEnablement: RuleEnablementOptions?
    @Flag(name: .shortAndLong, help: "Only display correctable rules")
    var correctable = false
}
