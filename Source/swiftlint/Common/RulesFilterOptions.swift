import ArgumentParser
import SwiftLintFramework

enum RuleEnablementOptions: String, EnumerableFlag {
    case enabled, disabled

    static func name(for _: Self) -> NameSpecification {
        .shortAndLong
    }

    static func help(for value: Self) -> ArgumentHelp? {
        "Only show \(value.rawValue) rules"
    }
}

struct RulesFilterOptions: ParsableArguments {
    @Flag(exclusivity: .exclusive)
    var ruleEnablement: RuleEnablementOptions?
    @Flag(name: .shortAndLong, help: "Only display correctable rules")
    var correctable = false

    var excludingOptions: RulesFilter.ExcludingOptions {
        var excludingOptions: RulesFilter.ExcludingOptions = []

        switch ruleEnablement {
        case .enabled:
            excludingOptions.insert(.disabled)
        case .disabled:
            excludingOptions.insert(.enabled)
        case .none:
            break
        }

        if correctable {
            excludingOptions.insert(.uncorrectable)
        }

        return excludingOptions
    }
}
