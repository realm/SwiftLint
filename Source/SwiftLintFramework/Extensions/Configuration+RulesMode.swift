public extension Configuration {
    enum RulesMode {
        case `default`(disabled: Set<String>, optIn: Set<String>)
        case whitelisted(Set<String>)
        case allEnabled

        init(
            enableAllRules: Bool,
            whitelistRules: [String],
            optInRules: [String],
            disabledRules: [String],
            analyzerRules: [String]
        ) throws {
            func warnAboutDuplicates(in identifiers: [String]) {
                if Set(identifiers).count != identifiers.count {
                    let duplicateRules = identifiers.reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
                        .filter { $0.1 > 1 }
                    for duplicateRule in duplicateRules {
                        queuedPrintError("warning: '\(duplicateRule.0)' is listed \(duplicateRule.1) times")
                    }
                }
            }

            if enableAllRules {
                self = .allEnabled
            } else if !whitelistRules.isEmpty {
                if !disabledRules.isEmpty || !optInRules.isEmpty {
                    throw ConfigurationError.generic(
                        "'\(Configuration.Key.disabledRules.rawValue)' or " +
                            "'\(Configuration.Key.optInRules.rawValue)' cannot be used in combination " +
                        "with '\(Configuration.Key.whitelistRules.rawValue)'"
                    )
                }

                warnAboutDuplicates(in: whitelistRules + analyzerRules)
                self = .whitelisted(Set(whitelistRules + analyzerRules))
            } else {
                warnAboutDuplicates(in: disabledRules)
                warnAboutDuplicates(in: optInRules + analyzerRules)
                self = .default(disabled: Set(disabledRules), optIn: Set(optInRules + analyzerRules))
            }
        }

        func applied(aliasResolver: (String) -> String) -> RulesMode {
            switch self {
            case let .default(disabled, optIn):
                return .default(
                    disabled: Set(disabled.map(aliasResolver)),
                    optIn: Set(optIn.map(aliasResolver))
                )

            case let .whitelisted(whitelisted):
                return .whitelisted(Set(whitelisted.map(aliasResolver)))

            case .allEnabled:
                return .allEnabled
            }
        }
    }
}
