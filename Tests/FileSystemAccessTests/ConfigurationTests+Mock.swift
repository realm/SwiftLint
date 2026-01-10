import Foundation
import SwiftLintFramework
import TestHelpers

// swiftlint:disable:next blanket_disable_command
// swiftlint:disable identifier_name

enum Mock {
    // MARK: Test Resources Path
    static let testResourcesPath = TestResources.path()

    // MARK: Directory Paths
    enum Dir {
        static var level0: URL { testResourcesPath.appending(path: "ProjectMock/") }
        static var level1: URL { level0.appending(path: "Level1/") }
        static var level2: URL { level1.appending(path: "Level2/") }
        static var level3: URL { level2.appending(path: "Level3/") }
        static var nested: URL { level0.appending(path: "NestedConfig/Test/") }
        static var nestedSub: URL { nested.appending(path: "Sub/") }
        static var childConfigTest1: URL { level0.appending(path: "ChildConfig/Test1/Main/") }
        static var childConfigTest2: URL { level0.appending(path: "ChildConfig/Test2/") }
        static var childConfigCycle1: URL { level0.appending(path: "ChildConfig/Cycle1/") }
        static var childConfigCycle2: URL { level0.appending(path: "ChildConfig/Cycle2/") }
        static var childConfigCycle3: URL { level0.appending(path: "ChildConfig/Cycle3/Main/") }
        static var childConfigCycle4: URL { level0.appending(path: "ChildConfig/Cycle4/") }
        static var parentConfigTest1: URL { level0.appending(path: "ParentConfig/Test1/") }
        static var parentConfigTest2: URL { level0.appending(path: "ParentConfig/Test2/") }
        static var parentConfigCycle1: URL { level0.appending(path: "ParentConfig/Cycle1/") }
        static var parentConfigCycle2: URL { level0.appending(path: "ParentConfig/Cycle2/") }
        static var parentConfigCycle3: URL { level0.appending(path: "ParentConfig/Cycle3/") }
        static var remoteConfigChild: URL { level0.appending(path: "RemoteConfig/Child/") }
        static var remoteConfigParent: URL { level0.appending(path: "RemoteConfig/Parent/") }
        static var remoteConfigLocalRef: URL { level0.appending(path: "RemoteConfig/LocalRef/") }
        static var remoteConfigCycle: URL { level0.appending(path: "RemoteConfig/Cycle/") }
        static var emptyFolder: URL { level0.appending(path: "EmptyFolder/") }

        static var exclusionTests: URL { testResourcesPath.appending(path: "ExclusionTests/") }
        static var directory: URL { exclusionTests.appending(path: "directory/") }
        static var directoryExcluded: URL { directory.appending(path: "excluded/") }
    }

    // MARK: YAML File Paths
    enum Yml {
        static var _0: URL { Dir.level0.appending(path: Configuration.defaultFileName) }
        static var _0Custom: URL { Dir.level0.appending(path: "custom.yml") }
        static var _0CustomRules: URL { Dir.level0.appending(path: "custom_rules.yml") }
        static var _0CustomRulesOnly: URL { Dir.level0.appending(path: "custom_rules_only.yml") }
        static var _2: URL { Dir.level2.appending(path: Configuration.defaultFileName) }
        static var _2CustomRules: URL { Dir.level2.appending(path: "custom_rules.yml") }
        static var _2CustomRulesOnly: URL { Dir.level2.appending(path: "custom_rules_only.yml") }
        static var _2CustomRulesDisabled: URL {
            Dir.level2.appending(path: "custom_rules_disabled.yml")
        }
        static var _2CustomRulesReconfig: URL {
            Dir.level2.appending(path: "custom_rules_reconfig.yml")
        }
        static var _3: URL { Dir.level3.appending(path: Configuration.defaultFileName) }
        static var nested: URL { Dir.nested.appending(path: Configuration.defaultFileName) }
    }

    // MARK: Swift File Paths
    enum Swift {
        static var _0: URL { Dir.level0.appending(path: "Level0.swift") }
        static var _1: URL { Dir.level1.appending(path: "Level1.swift") }
        static var _2: URL { Dir.level2.appending(path: "Level2.swift") }
        static var _3: URL { Dir.level3.appending(path: "Level3.swift") }
        static var nestedSub: URL { Dir.nestedSub.appending(path: "Sub.swift") }
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
