import Foundation
@testable import SwiftLintFramework
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

    @Test
    func parentConfigurationFilePrecedesDefaultConfigurationFile() {
        let options = LintOrAnalyzeOptions(
            configurationFiles: [],
            parentConfigurationFile: "parent.yml".url()
        )

        #expect(options.effectiveConfigurationFiles == [
            "parent.yml".url(),
            Configuration.defaultFileName.url(),
        ])
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
