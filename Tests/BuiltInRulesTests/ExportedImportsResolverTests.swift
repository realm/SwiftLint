import Foundation
import Testing

@testable import SwiftLintBuiltInRules

@Suite
struct ExportedImportsResolverTests {
    @Test
    func parsesExportedImportsAndFiltersCompilerArguments() throws {
        let dump = try makeAPIDump(
            children: [
                [
                    "kind": "Import",
                    "name": "B.Submodule",
                    "moduleName": "AExport",
                    "declAttributes": ["Exported"],
                ],
                [
                    "kind": "Import",
                    "name": "NotExported",
                    "moduleName": "AExport",
                ],
                [
                    "kind": "Import",
                    "name": "C",
                    "moduleName": "APlain",
                ],
                [
                    "kind": "Import",
                    "name": "Foreign",
                    "moduleName": "Other",
                    "declAttributes": ["Exported"],
                ],
            ]
        )
        let recorder = DigesterRecorder(responses: [dump])
        let resolver = ExportedImportsResolver { arguments in
            recorder.run(arguments)
        }

        let result = resolver.exportedImports(
            for: ["APlain", "AExport"],
            compilerArguments: compilerArgumentsFixture()
        )

        let exported = try #require(result["AExport"])
        let plain = try #require(result["APlain"])
        let invocation = try #require(recorder.invocations.first)

        #expect(exported == Set(["B"]))
        #expect(plain.isEmpty)
        #expect(
            invocation == expectedDigesterArguments()
        )
    }

    @Test
    func cachesSuccessfulLookups() throws {
        let dump = try makeExportedImportDump(
            owner: "A",
            importedModule: "B"
        )
        let recorder = DigesterRecorder(responses: [dump])
        let resolver = ExportedImportsResolver { arguments in
            recorder.run(arguments)
        }

        let first = resolver.exportedImports(
            for: ["A"],
            compilerArguments: ["-I", "/modules"]
        )
        let second = resolver.exportedImports(
            for: ["A"],
            compilerArguments: ["-I", "/modules"]
        )

        #expect(first == second)
        #expect(try #require(first["A"]) == Set(["B"]))
        #expect(recorder.invocations.count == 1)
    }

    @Test
    func retriesFailedLookups() throws {
        let dump = try makeExportedImportDump(
            owner: "A",
            importedModule: "B"
        )
        let recorder = DigesterRecorder(
            responses: [nil, dump]
        )
        let resolver = ExportedImportsResolver { arguments in
            recorder.run(arguments)
        }

        let first = resolver.exportedImports(
            for: ["A"],
            compilerArguments: ["-I", "/modules"]
        )
        let second = resolver.exportedImports(
            for: ["A"],
            compilerArguments: ["-I", "/modules"]
        )

        #expect(first["A"] == nil)
        #expect(try #require(second["A"]) == Set(["B"]))
        #expect(recorder.invocations.count == 2)
    }

    @Test
    func separatesCompilerContextsInCache() throws {
        let dump = try makeExportedImportDump(
            owner: "A",
            importedModule: "B"
        )
        let recorder = DigesterRecorder(
            responses: [dump, dump]
        )
        let resolver = ExportedImportsResolver { arguments in
            recorder.run(arguments)
        }

        _ = resolver.exportedImports(
            for: ["A"],
            compilerArguments: [
                "-target", "arm64-apple-macosx14.0",
            ]
        )
        _ = resolver.exportedImports(
            for: ["A"],
            compilerArguments: [
                "-target", "x86_64-apple-macosx14.0",
            ]
        )

        #expect(recorder.invocations.count == 2)
    }
}

private func compilerArgumentsFixture() -> [String] {
    [
        "/tmp/main.swift",
        "-I", "/modules",
        "-plugin-path", "/plugins",
        "-external-plugin-path", "/external-plugins",
        "-target", "arm64-apple-macosx14.0",
        "-sdk", "/sdk",
        "-Xcc", "-F", "-Xcc", "/clang/frameworks",
        "-Xcc", "-I/clang/include",
        "-F", "-Xcc",
    ]
}

private func expectedDigesterArguments() -> [String] {
    [
        "-dump-sdk",
        "-abort-on-module-fail",
        "-avoid-location",
        "-avoid-tool-args",
        "-o", "-",
        "-module", "AExport",
        "-module", "APlain",
        "-I", "/modules",
        "-target", "arm64-apple-macosx14.0",
        "-sdk", "/sdk",
        "-F", "/clang/frameworks",
        "-I/clang/include",
    ]
}

private final class DigesterRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var responses: [Data?]
    private var recordedInvocations = [[String]]()

    init(responses: [Data?]) {
        self.responses = responses
    }

    var invocations: [[String]] {
        lock.lock()
        defer {
            lock.unlock()
        }

        return recordedInvocations
    }

    func run(_ arguments: [String]) -> Data? {
        lock.lock()
        defer {
            lock.unlock()
        }

        recordedInvocations.append(arguments)

        guard responses.isNotEmpty else {
            return nil
        }

        return responses.removeFirst()
    }
}

private func makeExportedImportDump(
    owner: String,
    importedModule: String
) throws -> Data {
    try makeAPIDump(
        children: [
            [
                "kind": "Import",
                "name": importedModule,
                "moduleName": owner,
                "declAttributes": ["Exported"],
            ],
        ]
    )
}

private func makeAPIDump(
    children: [[String: Any]]
) throws -> Data {
    try JSONSerialization.data(
        withJSONObject: [
            "ABIRoot": [
                "kind": "Root",
                "name": "MULTI_MODULES",
                "children": children,
            ] as [String: Any],
        ]
    )
}
