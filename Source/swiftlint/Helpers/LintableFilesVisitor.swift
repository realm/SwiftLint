import Foundation
import SwiftLintFramework

struct LintableFilesVisitor {
    let paths: [String]
    let action: String
    let useSTDIN: Bool
    let quiet: Bool
    let useScriptInputFiles: Bool
    let forceExclude: Bool
    let cache: LinterCache?
    let parallel: Bool
    let compilerLogContents: String
    let block: (Linter) -> Void

    init?(paths: [String], action: String, useSTDIN: Bool, quiet: Bool, useScriptInputFiles: Bool, forceExclude: Bool,
          cache: LinterCache?, parallel: Bool, compilerLogPath: String, block: @escaping (Linter) -> Void) {
        self.paths = paths
        self.action = action
        self.useSTDIN = useSTDIN
        self.quiet = quiet
        self.useScriptInputFiles = useScriptInputFiles
        self.forceExclude = forceExclude
        self.cache = cache
        self.parallel = parallel
        self.compilerLogContents = LintableFilesVisitor.compilerLogContents(logPath: compilerLogPath)
        self.block = block
    }

    private static func compilerLogContents(logPath: String) -> String {
        if logPath.isEmpty {
            return ""
        }

        if let data = FileManager.default.contents(atPath: logPath),
            let logContents = String(data: data, encoding: .utf8) {
            return logContents
        }

        print("couldn't read log file at path '\(logPath)'")
        return ""
    }
}
