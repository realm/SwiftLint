import Foundation

extension RulesFilter.ExcludingOptions {
    static func excludingOptions(byCommandLineOptions rulesFilterOptions: RulesFilterOptions) -> Self {
        var excludingOptions: Self = []

        switch rulesFilterOptions.ruleEnablement {
        case .enabled:
            excludingOptions.insert(.disabled)
        case .disabled:
            excludingOptions.insert(.enabled)
        case .none:
            break
        }

        if rulesFilterOptions.correctable {
            excludingOptions.insert(.uncorrectable)
        }

        return excludingOptions
    }
}
