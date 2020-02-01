@testable import SwiftLintFramework

extension Collection where Element == StyleViolation {
    func withoutFiles() -> [StyleViolation] {
        return map { violation in
            let locationWithoutFile = Location(file: nil, line: violation.location.line,
                                               character: violation.location.character)
            return violation.with(location: locationWithoutFile)
        }
    }
}

private extension Collection where Element == Correction {
    func withoutFiles() -> [Correction] {
        return map { correction in
            let locationWithoutFile = Location(file: nil, line: correction.location.line,
                                               character: correction.location.character)
            return Correction(ruleDescription: correction.ruleDescription, location: locationWithoutFile)
        }
    }
}

extension Collection where Element == Example {
    /// Returns a dictionary with SwiftLint violation markers (↓) removed from keys.
    ///
    /// - returns: A new `Array`.
    func removingViolationMarkers() -> [Element] {
        return map { $0.removingViolationMarkers() }
    }
}

extension Collection where Element == String {
    func violations(config: Configuration = Configuration()!, requiresFileOnDisk: Bool = false)
        -> [StyleViolation] {
            let makeFile = requiresFileOnDisk ? SwiftLintFile.temporary : SwiftLintFile.init(contents:)
            return map(makeFile).violations(config: config, requiresFileOnDisk: requiresFileOnDisk)
    }

    func corrections(config: Configuration = Configuration()!, requiresFileOnDisk: Bool = false) -> [Correction] {
        let makeFile = requiresFileOnDisk ? SwiftLintFile.temporary : SwiftLintFile.init(contents:)
        return map(makeFile).corrections(config: config, requiresFileOnDisk: requiresFileOnDisk)
    }
}

extension Collection where Element: SwiftLintFile {
    func violations(config: Configuration = Configuration()!, requiresFileOnDisk: Bool = false)
        -> [StyleViolation] {
            let storage = RuleStorage()
            let violations = map({ file in
                Linter(file: file, configuration: config,
                       compilerArguments: requiresFileOnDisk ? file.makeCompilerArguments() : [])
            }).map({ linter in
                linter.collect(into: storage)
            }).flatMap({ linter in
                linter.styleViolations(using: storage)
            })
            return requiresFileOnDisk ? violations.withoutFiles() : violations
    }

    func corrections(config: Configuration = Configuration()!, requiresFileOnDisk: Bool = false) -> [Correction] {
        let storage = RuleStorage()
        let corrections = map({ file in
            Linter(file: file, configuration: config,
                   compilerArguments: requiresFileOnDisk ? file.makeCompilerArguments() : [])
        }).map({ linter in
            linter.collect(into: storage)
        }).flatMap({ linter in
            linter.correct(using: storage)
        })
        return requiresFileOnDisk ? corrections.withoutFiles() : corrections
    }
}
