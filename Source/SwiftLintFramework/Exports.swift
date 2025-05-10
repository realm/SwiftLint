@_exported import SwiftLintBuiltInRules
@_exported import SwiftLintCore
import SwiftLintExtraRules

private let _registerAllRulesOnceImpl: Void = {
    RuleRegistry.shared.register(rules: builtInRules + coreRules + extraRules())
}()

package extension RuleRegistry {
    /// Register all rules. Should only be called once before any SwiftLint code is executed.
    static func registerAllRulesOnce() {
        _ = _registerAllRulesOnceImpl
    }
}
