@testable import SwiftLintFramework

// swiftlint:disable:next blanket_disable_command
// swiftlint:disable nesting identifier_name

internal extension ConfigurationTests {
    enum Mock {
        // MARK: Test Resources Path
        static let testResourcesPath: String = TestResources.path

        // MARK: Directory Paths
        enum Dir {
            static var level0: String { testResourcesPath.stringByAppendingPathComponent("ProjectMock") }
            static var level1: String { level0.stringByAppendingPathComponent("Level1") }
            static var level2: String { level1.stringByAppendingPathComponent("Level2") }
            static var level3: String { level2.stringByAppendingPathComponent("Level3") }
            static var nested: String { level0.stringByAppendingPathComponent("NestedConfig/Test") }
            static var nestedSub: String { nested.stringByAppendingPathComponent("Sub") }
            static var childConfigTest1: String { level0.stringByAppendingPathComponent("ChildConfig/Test1/Main") }
            static var childConfigTest2: String { level0.stringByAppendingPathComponent("ChildConfig/Test2") }
            static var childConfigCycle1: String { level0.stringByAppendingPathComponent("ChildConfig/Cycle1") }
            static var childConfigCycle2: String { level0.stringByAppendingPathComponent("ChildConfig/Cycle2") }
            static var childConfigCycle3: String { level0.stringByAppendingPathComponent("ChildConfig/Cycle3/Main") }
            static var childConfigCycle4: String { level0.stringByAppendingPathComponent("ChildConfig/Cycle4") }
            static var parentConfigTest1: String { level0.stringByAppendingPathComponent("ParentConfig/Test1") }
            static var parentConfigTest2: String { level0.stringByAppendingPathComponent("ParentConfig/Test2") }
            static var parentConfigCycle1: String { level0.stringByAppendingPathComponent("ParentConfig/Cycle1") }
            static var parentConfigCycle2: String { level0.stringByAppendingPathComponent("ParentConfig/Cycle2") }
            static var parentConfigCycle3: String { level0.stringByAppendingPathComponent("ParentConfig/Cycle3") }
            static var remoteConfigChild: String { level0.stringByAppendingPathComponent("RemoteConfig/Child") }
            static var remoteConfigParent: String { level0.stringByAppendingPathComponent("RemoteConfig/Parent") }
            static var remoteConfigLocalRef: String { level0.stringByAppendingPathComponent("RemoteConfig/LocalRef") }
            static var remoteConfigCycle: String { level0.stringByAppendingPathComponent("RemoteConfig/Cycle") }
            static var emptyFolder: String { level0.stringByAppendingPathComponent("EmptyFolder") }
        }

        // MARK: YAML File Paths
        enum Yml {
            static var _0: String { Dir.level0.stringByAppendingPathComponent(Configuration.defaultFileName) }
            static var _0Custom: String { Dir.level0.stringByAppendingPathComponent("custom.yml") }
            static var _0CustomRules: String { Dir.level0.stringByAppendingPathComponent("custom_rules.yml") }
            static var _0CustomRulesOnly: String { Dir.level0.stringByAppendingPathComponent("custom_rules_only.yml") }
            static var _2: String { Dir.level2.stringByAppendingPathComponent(Configuration.defaultFileName) }
            static var _2CustomRules: String { Dir.level2.stringByAppendingPathComponent("custom_rules.yml") }
            static var _2CustomRulesOnly: String { Dir.level2.stringByAppendingPathComponent("custom_rules_only.yml") }
            static var _2CustomRulesDisabled: String {
                Dir.level2.stringByAppendingPathComponent("custom_rules_disabled.yml")
            }
            static var _2CustomRulesReconfig: String {
                Dir.level2.stringByAppendingPathComponent("custom_rules_reconfig.yml")
            }
            static var _3: String { Dir.level3.stringByAppendingPathComponent(Configuration.defaultFileName) }
            static var nested: String { Dir.nested.stringByAppendingPathComponent(Configuration.defaultFileName) }
        }

        // MARK: Swift File Paths
        enum Swift {
            static var _0: String { Dir.level0.stringByAppendingPathComponent("Level0.swift") }
            static var _1: String { Dir.level1.stringByAppendingPathComponent("Level1.swift") }
            static var _2: String { Dir.level2.stringByAppendingPathComponent("Level2.swift") }
            static var _3: String { Dir.level3.stringByAppendingPathComponent("Level3.swift") }
            static var nestedSub: String { Dir.nestedSub.stringByAppendingPathComponent("Sub.swift") }
        }

        // MARK: Configurations
        enum Config {
            static var _0: Configuration { Configuration(configurationFiles: []) }
            static var _0Custom: Configuration { Configuration(configurationFiles: [Yml._0Custom]) }
            static var _0CustomRules: Configuration { Configuration(configurationFiles: [Yml._0CustomRules]) }
            static var _0CustomRulesOnly: Configuration { Configuration(configurationFiles: [Yml._0CustomRulesOnly]) }
            static var _2: Configuration { Configuration(configurationFiles: [Yml._2]) }
            static var _2CustomRules: Configuration { Configuration(configurationFiles: [Yml._2CustomRules]) }
            static var _2CustomRulesOnly: Configuration { Configuration(configurationFiles: [Yml._2CustomRulesOnly]) }
            static var _2CustomRulesDisabled: Configuration {
                Configuration(configurationFiles: [Yml._2CustomRulesDisabled])
            }
            static var _2CustomRulesReconfig: Configuration {
                Configuration(configurationFiles: [Yml._2CustomRulesReconfig])
            }
            static var _3: Configuration { Configuration(configurationFiles: [Yml._3]) }
            static var nested: Configuration { Configuration(configurationFiles: [Yml.nested]) }
        }
    }
}
