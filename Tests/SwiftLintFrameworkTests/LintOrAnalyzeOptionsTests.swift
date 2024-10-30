@testable import SwiftLintFramework
import XCTest

final class LintOrAnalyzeOptionsTests: XCTestCase {
    private typealias Leniency = LintOrAnalyzeOptions.Leniency

    func testLeniency() {
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
                    XCTAssertTrue(leniency.strict)
                    if !commandLine.lenient {
                        // `--strict` should disable configuration lenience.
                        XCTAssertFalse(leniency.lenient)
                    }
                } else if commandLine.lenient {
                    // Command line takes precedence, and should override
                    // `strict` in the configuration.
                    XCTAssertTrue(leniency.lenient)
                    XCTAssertFalse(leniency.strict)
                } else if configuration.strict {
                    XCTAssertTrue(leniency.strict)
                } else if configuration.lenient {
                    XCTAssertTrue(leniency.lenient)
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
