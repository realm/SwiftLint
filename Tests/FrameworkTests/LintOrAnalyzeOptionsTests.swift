import Foundation
@testable import SwiftLintFramework
import TestHelpers
import Testing

@Suite
struct LintOrAnalyzeOptionsTests {
    private typealias Leniency = LintOrAnalyzeOptions.Leniency

    @Test
    func leniency() {
        let parameters = [
            Leniency(strict: false, lenient: false),
            Leniency(strict: true, lenient: true),
            Leniency(strict: true, lenient: false),
            Leniency(strict: false, lenient: true),
        ]

        for commandLine in parameters {
            let options = LintOrAnalyzeOptions(leniency: commandLine)
            for configuration in parameters {
                let leniency = options.leniency(strict: configuration.strict, lenient: configuration.lenient)
                if commandLine.strict {
                    // Command line takes precedence.
                    #expect(leniency.strict)
                    if !commandLine.lenient {
                        // `--strict` should disable configuration lenience.
                        #expect(!leniency.lenient)
                    }
                } else if commandLine.lenient {
                    // Command line takes precedence, and should override
                    // `strict` in the configuration.
                    #expect(leniency.lenient)
                    #expect(!leniency.strict)
                } else if configuration.strict {
                    #expect(leniency.strict)
                } else if configuration.lenient {
                    #expect(leniency.lenient)
                }
            }
        }
    }

    @Test
    func parentConfigurationFilePrecedesExplicitConfigurationFiles() {
        let options = LintOrAnalyzeOptions(
            configurationFiles: ["child-1.yml".url(), "child-2.yml".url()],
            parentConfigurationFile: "parent.yml".url()
        )

        #expect(options.effectiveConfigurationFiles == [
            "parent.yml".url(),
            "child-1.yml".url(),
            "child-2.yml".url(),
        ])
    }

    @Test(.temporaryDirectory)
    func parentConfigurationFilePrecedesDefaultConfigurationFile() throws {
        try "reporter: csv".write(
            to: Configuration.defaultFileName.url(),
            atomically: true,
            encoding: .utf8
        )
        let options = LintOrAnalyzeOptions(
            configurationFiles: [],
            parentConfigurationFile: "parent.yml".url()
        )

        #expect(options.effectiveConfigurationFiles == [
            "parent.yml".url(),
            Configuration.defaultFileName.url(),
        ])
    }

    @Test(.temporaryDirectory)
    func parentConfigurationFileWorksWithoutDefaultConfigurationFile() {
        let options = LintOrAnalyzeOptions(
            configurationFiles: [],
            parentConfigurationFile: "parent.yml".url()
        )

        #expect(options.effectiveConfigurationFiles == ["parent.yml".url()])
    }

    @Test(.rulesRegistered, .temporaryDirectory)
    func parentConfigurationFilePreservesNestedConfigurations() throws {
        let parentConfigurationFile = "parent.yml".url()
        try "disabled_rules: []".write(to: parentConfigurationFile, atomically: true, encoding: .utf8)
        try "disabled_rules: []".write(
            to: Configuration.defaultFileName.url(),
            atomically: true,
            encoding: .utf8
        )

        let nestedDirectory = URL.cwd.appending(path: "Nested", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: nestedDirectory, withIntermediateDirectories: true)
        try "disabled_rules: [line_length]".write(
            to: nestedDirectory.appending(path: Configuration.defaultFileName),
            atomically: true,
            encoding: .utf8
        )

        let options = LintOrAnalyzeOptions(
            configurationFiles: [],
            parentConfigurationFile: parentConfigurationFile
        )
        let configuration = Configuration(options: options)
        let nestedFile = SwiftLintFile(
            pathDeferringReading: nestedDirectory.appending(path: "Example.swift")
        )

        #expect(!configuration.basedOnCustomConfigurationFiles)
        #expect(!configuration.rulesWrapper.disabledRuleIdentifiers.contains("line_length"))
        #expect(
            configuration.configuration(for: nestedFile)
                .rulesWrapper.disabledRuleIdentifiers.contains("line_length")
        )
    }
}

private extension LintOrAnalyzeOptions {
    init(
        leniency: Leniency = (strict: false, lenient: false),
        configurationFiles: [URL] = [],
        parentConfigurationFile: URL? = nil
    ) {
        self.init(mode: .lint,
                  paths: [],
                  useSTDIN: true,
                  configurationFiles: configurationFiles,
                  parentConfigurationFile: parentConfigurationFile,
                  strict: leniency.strict,
                  lenient: leniency.lenient,
                  forceExclude: false,
                  useExcludingByPrefix: false,
                  useScriptInputFiles: false,
                  useScriptInputFileLists: false,
                  benchmark: false,
                  reporter: nil,
                  baseline: nil,
                  writeBaseline: nil,
                  workingDirectory: nil,
                  quiet: false,
                  output: nil,
                  progress: false,
                  cachePath: nil,
                  ignoreCache: false,
                  enableAllRules: false,
                  onlyRule: [],
                  autocorrect: false,
                  format: false,
                  disableSourceKit: false,
                  compilerLogPath: nil,
                  compileCommands: nil,
                  checkForUpdates: false
        )
    }
}
