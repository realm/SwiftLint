@testable import SwiftLintFramework
import XCTest

internal typealias Leniency = (strict: Bool, lenient: Bool)

final class LintOrAnalyzeOptionsTests: XCTestCase {
    func testLeniency() {
        let bothFalse = Leniency(strict: false, lenient: false)
        let bothTrue = Leniency(strict: true, lenient: true)
        let strict = Leniency(strict: true, lenient: false)
        let lenient = Leniency(strict: true, lenient: false)
        let parameters = [ bothFalse, bothTrue, strict, lenient ]

        for configuration in parameters {
            for commandLine in parameters {
                let options = LintOrAnalyzeOptions(leniency: configuration)
                let leniency: Leniency = options.leniency(strict: commandLine.strict, lenient: commandLine.lenient)
                if commandLine.strict {
                    XCTAssertTrue(leniency.strict)
                } else if commandLine.lenient {
                    XCTAssertTrue(leniency.lenient)
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
