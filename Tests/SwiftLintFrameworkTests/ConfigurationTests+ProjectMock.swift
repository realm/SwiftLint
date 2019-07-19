@testable import SwiftLintFramework

extension ConfigurationTests {
    var projectMockPathLevel0: String {
        return testResourcesPath.stringByAppendingPathComponent("ProjectMock")
    }

    var projectMockPathLevel1: String {
        return projectMockPathLevel0.stringByAppendingPathComponent("Level1")
    }

    var projectMockPathLevel2: String {
        return projectMockPathLevel1.stringByAppendingPathComponent("Level2")
    }

    var projectMockPathLevel3: String {
        return projectMockPathLevel2.stringByAppendingPathComponent("Level3")
    }

    var projectMockYAML0: String {
        return projectMockPathLevel0.stringByAppendingPathComponent(Configuration.fileName)
    }

    var projectMockYAML0CustomPath: String {
        return projectMockPathLevel0.stringByAppendingPathComponent("custom.yml")
    }

    var projectMockYAML0CustomRules: String {
        return projectMockPathLevel0.stringByAppendingPathComponent("custom_rules.yml")
    }

    var projectMockYAML2: String {
        return projectMockPathLevel2.stringByAppendingPathComponent(Configuration.fileName)
    }

    var projectMockYAML2CustomRules: String {
        return projectMockPathLevel2.stringByAppendingPathComponent("custom_rules.yml")
    }

    var projectMockYAML2CustomRulesDisabled: String {
        return projectMockPathLevel2.stringByAppendingPathComponent("custom_rules_disabled.yml")
    }

    var projectMockSwift0: String {
        return projectMockPathLevel0.stringByAppendingPathComponent("Level0.swift")
    }

    var projectMockSwift1: String {
        return projectMockPathLevel1.stringByAppendingPathComponent("Level1.swift")
    }

    var projectMockSwift2: String {
        return projectMockPathLevel2.stringByAppendingPathComponent("Level2.swift")
    }

    var projectMockSwift3: String {
        return projectMockPathLevel3.stringByAppendingPathComponent("Level3.swift")
    }

    var projectMockConfig0: Configuration {
        return Configuration(path: projectMockYAML0, rootPath: projectMockPathLevel0,
                             optional: false, quiet: true)
    }

    var projectMockConfig0CustomPath: Configuration {
        return Configuration(path: projectMockYAML0CustomPath, rootPath: projectMockPathLevel0,
                             optional: false, quiet: true)
    }

    var projectMockConfig0CustomRules: Configuration {
        return Configuration(path: projectMockYAML0CustomRules, rootPath: projectMockPathLevel0,
                             optional: false, quiet: true)
    }

    var projectMockConfig2: Configuration {
        return Configuration(path: projectMockYAML2, optional: false, quiet: true)
    }

    var projectMockConfig2CustomRules: Configuration {
        return Configuration(path: projectMockYAML2CustomRules, rootPath: projectMockPathLevel0,
                             optional: false, quiet: true)
    }

    var projectMockConfig2CustomRulesDisabled: Configuration {
        return Configuration(path: projectMockYAML2CustomRulesDisabled, rootPath: projectMockPathLevel0,
                             optional: false, quiet: true)
    }

    var projectMockConfig3: Configuration {
        return Configuration(path: Configuration.fileName, rootPath: projectMockPathLevel3,
                             optional: false, quiet: true)
    }
}
