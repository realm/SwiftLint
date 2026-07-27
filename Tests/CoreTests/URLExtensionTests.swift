import Foundation
import SwiftLintCore
import Testing

@Suite
final class URLExtensionTests {
    private let tempDir = FileManager.default.temporaryDirectory
        .appending(path: "swiftlint-response-test-\(UUID().uuidString)")

    init() throws {
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    deinit {
        do {
            try FileManager.default.removeItem(at: tempDir)
        } catch {
            Issue.record("Failed to remove temporary directory: \(error)")
        }
    }

    @Test
    func expandingResponseFilesPassesThroughRegularPaths() {
        let paths = ["/a.swift", "/b.swift"]
        #expect(paths.expandingResponseFiles == paths)
    }

    @Test
    func expandingResponseFilesExpandsResponseFile() throws {
        let responseFile = tempDir.appending(path: "files.txt")
        try "foo.swift\nbar.swift\n".write(to: responseFile, atomically: true, encoding: .utf8)

        let expanded = ["@\(responseFile.filepath)"].expandingResponseFiles
        #expect(expanded == ["foo.swift", "bar.swift"])
    }

    @Test
    func expandingResponseFilesTrimsTrailingNewlines() throws {
        let responseFile = tempDir.appending(path: "files.txt")
        try "foo.swift\nbar.swift\n".write(to: responseFile, atomically: true, encoding: .utf8)

        let expanded = ["@\(responseFile.filepath)"].expandingResponseFiles
        #expect(expanded == ["foo.swift", "bar.swift"])
    }

    @Test
    func expandingResponseFilesMixesRegularAndResponsePaths() throws {
        let responseFile = tempDir.appending(path: "files.txt")
        try "b.swift\nc.swift".write(to: responseFile, atomically: true, encoding: .utf8)

        let expanded = ["/a.swift", "@\(responseFile.filepath)", "/d.swift"].expandingResponseFiles
        #expect(expanded == ["/a.swift", "b.swift", "c.swift", "/d.swift"])
    }

    @Test
    func expandingResponseFilesRecursivelyExpands() throws {
        let inner = tempDir.appending(path: "inner.txt")
        try "c.swift".write(to: inner, atomically: true, encoding: .utf8)

        let outer = tempDir.appending(path: "outer.txt")
        try "a.swift\n@\(inner.filepath)\nb.swift".write(to: outer, atomically: true, encoding: .utf8)

        let expanded = ["@\(outer.filepath)"].expandingResponseFiles
        #expect(expanded == ["a.swift", "c.swift", "b.swift"])
    }

    @Test
    func expandingResponseFilesPreservesUnreadableArgs() {
        let expanded = ["@/nonexistent/missing.txt"].expandingResponseFiles
        #expect(expanded == ["@/nonexistent/missing.txt"])
    }

    @Test
    func expandingResponseFilesPreservesEmptyFile() throws {
        let responseFile = tempDir.appending(path: "empty.txt")
        try "".write(to: responseFile, atomically: true, encoding: .utf8)

        let expanded = ["@\(responseFile.filepath)"].expandingResponseFiles
        #expect(expanded == [""])
    }
}
