import SwiftLintFramework
import XCTest

extension Configuration {
    func assertCorrection(_ initial: Example, expected: Example) {
        let (cleanedInitial, markerOffsets) = TestHelpers.cleanedContentsAndMarkerOffsets(from: initial.code)
        let file = SwiftLintFile.temporary(withContents: cleanedInitial)
        // expectedLocations are needed to create before call `correct()`
        let expectedLocations = markerOffsets.map { Location(file: file, characterOffset: $0) }
        let includeCompilerArguments = self.rules.contains(where: { $0 is AnalyzerRule })
        let compilerArguments = includeCompilerArguments ? file.makeCompilerArguments() : []
        let storage = RuleStorage()
        let collecter = Linter(file: file, configuration: self, compilerArguments: compilerArguments)
        let linter = collecter.collect(into: storage)
        let corrections = linter.correct(using: storage).sorted { $0.location < $1.location }
        assertCorrections(
            at: expectedLocations,
            corrections: corrections,
            initial: initial,
            expected: expected,
            file: file
        )
    }
}

private extension Configuration {
    func assertCorrections(
        at expectedLocations: [Location],
        corrections: [Correction],
        initial: Example,
        expected: Example,
        file: SwiftLintFile) {
        if expectedLocations.isEmpty {
            XCTAssertEqual(
                corrections.count, initial.code != expected.code ? 1 : 0, #function + ".expectedLocationsEmpty",
                file: initial.file, line: initial.line)
        } else {
            XCTAssertEqual(
                corrections.count,
                expectedLocations.count,
                #function + ".expected locations: \(expectedLocations.count)",
                file: initial.file, line: initial.line)
            for (correction, expectedLocation) in zip(corrections, expectedLocations) {
                XCTAssertEqual(
                    correction.location,
                    expectedLocation,
                    #function + ".correction location",
                    file: initial.file, line: initial.line)
            }
        }
        XCTAssertEqual(
            file.contents,
            expected.code,
            #function + ".file contents",
            file: initial.file, line: initial.line)
        let path = file.path!
        do {
            let corrected = try String(contentsOfFile: path, encoding: .utf8)
            XCTAssertEqual(
                corrected,
                expected.code,
                #function + ".corrected file equals expected",
                file: initial.file, line: initial.line)
        } catch {
            XCTFail(
                "couldn't read file at path '\(path)': \(error)",
                file: initial.file, line: initial.line)
        }
    }
}
