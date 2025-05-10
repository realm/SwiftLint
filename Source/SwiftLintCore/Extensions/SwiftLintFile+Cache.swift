#if canImport(Darwin)
import Darwin
#endif
import Foundation
import SourceKittenFramework
import SwiftIDEUtils
import SwiftOperators
import SwiftParser
import SwiftParserDiagnostics
import SwiftSyntax

private typealias FileCacheKey = UUID

private let responseCache = Cache { file -> [String: any SourceKitRepresentable]? in
    do {
        return try Request.editorOpen(file: file.file).sendIfNotDisabled()
    } catch let error as Request.Error {
        queuedPrintError(error.description)
        return nil
    } catch {
        return nil
    }
}
private let structureDictionaryCache = Cache { file in
    responseCache.get(file).map(Structure.init).map { SourceKittenDictionary($0.dictionary) }
}
private let syntaxTreeCache = Cache { file -> SourceFileSyntax in
    Parser.parse(source: file.contents)
}
private let foldedSyntaxTreeCache = Cache { file -> SourceFileSyntax? in
    OperatorTable.standardOperators
        .foldAll(file.syntaxTree) { _ in /* Don't handle errors. */ }
        .as(SourceFileSyntax.self)
}
private let locationConverterCache = Cache { file -> SourceLocationConverter in
    SourceLocationConverter(fileName: file.path ?? "<nopath>", tree: file.syntaxTree)
}
private let commandsCache = Cache { file -> [Command] in
    guard file.contents.contains("swiftlint:") else {
        return []
    }
    return CommandVisitor(locationConverter: file.locationConverter)
        .walk(file: file, handler: \.commands)
}
private let syntaxMapCache = Cache { file in
    responseCache.get(file).map { SwiftLintSyntaxMap(value: SyntaxMap(sourceKitResponse: $0)) }
}
private let syntaxClassificationsCache = Cache { $0.syntaxTree.classifications }
private let syntaxKindsByLinesCache = Cache { $0.syntaxKindsByLine() }
private let syntaxTokensByLinesCache = Cache { $0.syntaxTokensByLine() }
private let linesWithTokensCache = Cache { $0.computeLinesWithTokens() }

package typealias AssertHandler = () -> Void
// Re-enable once all parser diagnostics in tests have been addressed.
// https://github.com/realm/SwiftLint/issues/3348
package nonisolated(unsafe) var parserDiagnosticsDisabledForTests = false

private let assertHandlerCache = Cache { (_: SwiftLintFile) -> AssertHandler? in nil }

private final class Cache<T>: Sendable {
    private nonisolated(unsafe) var values = [FileCacheKey: T]()
    private let factory: @Sendable (SwiftLintFile) -> T
    private let lock = PlatformLock()

    fileprivate init(_ factory: @escaping @Sendable (SwiftLintFile) -> T) {
        self.factory = factory
    }

    fileprivate func get(_ file: SwiftLintFile) -> T {
        let key = file.cacheKey
        return lock.doLocked {
            if let cachedValue = values[key] {
                return cachedValue
            }
            let value = factory(file)
            values[key] = value
            return value
        }
    }

    fileprivate func invalidate(_ file: SwiftLintFile) {
        lock.doLocked { values.removeValue(forKey: file.cacheKey) }
    }

    fileprivate func clear() {
        lock.doLocked { values.removeAll(keepingCapacity: false) }
    }

    fileprivate func set(key: FileCacheKey, value: T) {
        lock.doLocked { values[key] = value }
    }

    fileprivate func unset(key: FileCacheKey) {
        lock.doLocked { values.removeValue(forKey: key) }
    }
}

extension SwiftLintFile {
    fileprivate var cacheKey: FileCacheKey {
        id
    }

    public var sourcekitdFailed: Bool {
        get {
            responseCache.get(self) == nil
        }
        set {
            if newValue {
                responseCache.set(key: cacheKey, value: nil)
            } else {
                responseCache.unset(key: cacheKey)
            }
        }
    }

    package var assertHandler: AssertHandler? {
        get {
            assertHandlerCache.get(self)
        }
        set {
            assertHandlerCache.set(key: cacheKey, value: newValue)
        }
    }

    public var parserDiagnostics: [String]? {
        if parserDiagnosticsDisabledForTests {
            return nil
        }

        return ParseDiagnosticsGenerator.diagnostics(for: syntaxTree)
            .filter { $0.diagMessage.severity == .error }
            .map(\.message)
    }

    public var linesWithTokens: Set<Int> { linesWithTokensCache.get(self) }

    public var structureDictionary: SourceKittenDictionary {
        guard let structureDictionary = structureDictionaryCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return SourceKittenDictionary([:])
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return structureDictionary
    }

    public var syntaxClassifications: SyntaxClassifications { syntaxClassificationsCache.get(self) }

    public var syntaxMap: SwiftLintSyntaxMap {
        guard let syntaxMap = syntaxMapCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return SwiftLintSyntaxMap(value: SyntaxMap(data: []))
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return syntaxMap
    }

    public var syntaxTree: SourceFileSyntax { syntaxTreeCache.get(self) }

    public var foldedSyntaxTree: SourceFileSyntax? { foldedSyntaxTreeCache.get(self) }

    public var locationConverter: SourceLocationConverter { locationConverterCache.get(self) }

    public var commands: [Command] { commandsCache.get(self).filter(\.isValid) }

    public var invalidCommands: [Command] { commandsCache.get(self).filter { !$0.isValid } }

    public var syntaxTokensByLines: [[SwiftLintSyntaxToken]] {
        guard let syntaxTokensByLines = syntaxTokensByLinesCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return []
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return syntaxTokensByLines
    }

    public var syntaxKindsByLines: [[SourceKittenFramework.SyntaxKind]] {
        guard let syntaxKindsByLines = syntaxKindsByLinesCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return []
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return syntaxKindsByLines
    }

    /// Invalidates all cached data for this file.
    public func invalidateCache() {
        file.clearCaches()
        responseCache.invalidate(self)
        assertHandlerCache.invalidate(self)
        structureDictionaryCache.invalidate(self)
        syntaxClassificationsCache.invalidate(self)
        syntaxMapCache.invalidate(self)
        syntaxTokensByLinesCache.invalidate(self)
        syntaxKindsByLinesCache.invalidate(self)
        syntaxTreeCache.invalidate(self)
        foldedSyntaxTreeCache.invalidate(self)
        locationConverterCache.invalidate(self)
        commandsCache.invalidate(self)
        linesWithTokensCache.invalidate(self)
    }

    package static func clearCaches() {
        responseCache.clear()
        assertHandlerCache.clear()
        structureDictionaryCache.clear()
        syntaxClassificationsCache.clear()
        syntaxMapCache.clear()
        syntaxTokensByLinesCache.clear()
        syntaxKindsByLinesCache.clear()
        syntaxTreeCache.clear()
        foldedSyntaxTreeCache.clear()
        locationConverterCache.clear()
        commandsCache.clear()
        linesWithTokensCache.clear()
    }
}

private final class PlatformLock: Sendable {
#if canImport(Darwin)
    private nonisolated(unsafe) let primitiveLock: UnsafeMutablePointer<os_unfair_lock>
#else
    private let primitiveLock = NSLock()
#endif

    init() {
#if canImport(Darwin)
        primitiveLock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        primitiveLock.initialize(to: os_unfair_lock())
#endif
    }

    @discardableResult
    func doLocked<U>(_ closure: () -> U) -> U {
#if canImport(Darwin)
        os_unfair_lock_lock(primitiveLock)
        defer { os_unfair_lock_unlock(primitiveLock) }
        return closure()
#else
        primitiveLock.lock()
        defer { primitiveLock.unlock() }
        return closure()
#endif
    }
}
