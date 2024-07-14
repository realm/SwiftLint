import ArgumentParser

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
}
