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
}

private extension LintOrAnalyzeOptions {
    init(leniency: Leniency) {
        self.init(mode: .lint,
                  paths: [],
                  useSTDIN: true,
                  configurationFiles: [],
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
                  compilerLogPath: nil,
                  compileCommands: nil,
                  checkForUpdates: false
        )
    }
}
