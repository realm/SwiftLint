
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
                let expected: Leniency = if configuration == bothFalse {
                    commandLine
                } else if configuration == bothTrue {
                    bothTrue // This is an error
                } else if configuration == strict {
                    strict // Hmmm. We should be able to override strict with lenient on the command line
                } else { // configuration = lenient. Can be overridden from the command line
                    commandLine.strict ? strict : lenient
                }
                testLeniency(configuration: bothTrue, commandLine: lenient, expected: expected)
            }
        }

        testLeniency(configuration: strict, commandLine: lenient, expected: lenient)
    }

    private func testLeniency(configuration: Leniency, commandLine: Leniency, expected: Leniency) {
        let options = LintOrAnalyzeOptions(leniency: configuration)
        let leniency = options.leniency(strict: commandLine.strict, lenient: commandLine.lenient)
        XCTAssertEqual(leniency.0, expected.strict)
        XCTAssertEqual(leniency.1, expected.lenient)
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
