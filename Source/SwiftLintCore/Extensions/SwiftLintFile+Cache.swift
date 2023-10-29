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
private let sourceKitResponseCache = Cache { file -> [String: any SourceKitRepresentable]? in
    do {
        return try Request.editorOpen(file: file.file).sendIfNotDisabled()
    } catch let error as Request.Error {
        queuedPrintError(error.description)
        return nil
    } catch {
        return nil
    }
}
private let sourceKitStructureDictionaryCache = Cache { file in
    return sourceKitResponseCache.get(file).map(Structure.init).map { SourceKittenDictionary($0.dictionary) }
}
private let syntaxTreeCache = Cache { file -> SourceFileSyntax in
    return Parser.parse(source: file.contents)
}
private let foldedSyntaxTreeCache = Cache { file -> SourceFileSyntax? in
    return OperatorTable.standardOperators
        .foldAll(file.syntaxTree) { _ in }
        .as(SourceFileSyntax.self)
}
private let locationConverterCache = Cache { file -> SourceLocationConverter in
    return SourceLocationConverter(fileName: file.path ?? "<nopath>", tree: file.syntaxTree)
}
private let commandsCache = Cache { file -> [Command] in
    guard file.contents.contains("swiftlint:") else {
        return []
    }
    return CommandVisitor(locationConverter: file.locationConverter)
        .walk(file: file, handler: \.commands)
}
private let sourceKitSyntaxMapCache = Cache { file in
    sourceKitResponseCache.get(file).map { SwiftLintSyntaxMap(value: SyntaxMap(sourceKitResponse: $0)) }
}
private let syntaxClassificationsCache = Cache { $0.syntaxTree.classifications }
private let sourceKitSyntaxKindsByLinesCache = Cache { $0.syntaxKindsByLine() }
private let sourceKitSyntaxTokensByLinesCache = Cache { $0.syntaxTokensByLine() }
private let linesWithTokensCache = Cache { $0.computeLinesWithTokens() }

internal typealias AssertHandler = () -> Void
// Re-enable once all parser diagnostics in tests have been addressed.
// https://github.com/realm/SwiftLint/issues/3348
@_spi(TestHelper)
public var parserDiagnosticsDisabledForTests = false

private let assertHandlers = [FileCacheKey: AssertHandler]()
private let assertHandlerCache = Cache { file in assertHandlers[file.cacheKey] }

private class Cache<T> {
    private var values = [FileCacheKey: T]()
    private let factory: (SwiftLintFile) -> T
    private let lock = PlatformLock()

    fileprivate init(_ factory: @escaping (SwiftLintFile) -> T) {
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
        return id
    }

    public var sourcekitdFailed: Bool {
        get {
            return sourceKitResponseCache.get(self) == nil
        }
        set {
            if newValue {
                sourceKitResponseCache.set(key: cacheKey, value: nil)
            } else {
                sourceKitResponseCache.unset(key: cacheKey)
            }
        }
    }

    internal var assertHandler: AssertHandler? {
        get {
            return assertHandlerCache.get(self)
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

    public var sourceKitStructureDictionary: SourceKittenDictionary {
        guard let structureDictionary = sourceKitStructureDictionaryCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return SourceKittenDictionary([:])
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return structureDictionary
    }

    public var syntaxClassifications: SyntaxClassifications { syntaxClassificationsCache.get(self) }

    public var sourceKitSyntaxMap: SwiftLintSyntaxMap {
        guard let syntaxMap = sourceKitSyntaxMapCache.get(self) else {
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

    public var commands: [Command] { commandsCache.get(self).filter { $0.isValid } }

    public var invalidCommands: [Command] { commandsCache.get(self).filter { !$0.isValid } }

    public var sourceKitSyntaxTokensByLines: [[SwiftLintSyntaxToken]] {
        guard let syntaxTokensByLines = sourceKitSyntaxTokensByLinesCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return []
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return syntaxTokensByLines
    }

    public var sourceKitSyntaxKindsByLines: [[SourceKittenFramework.SyntaxKind]] {
        guard let syntaxKindsByLines = sourceKitSyntaxKindsByLinesCache.get(self) else {
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
        sourceKitResponseCache.invalidate(self)
        assertHandlerCache.invalidate(self)
        sourceKitStructureDictionaryCache.invalidate(self)
        syntaxClassificationsCache.invalidate(self)
        sourceKitSyntaxMapCache.invalidate(self)
        sourceKitSyntaxTokensByLinesCache.invalidate(self)
        sourceKitSyntaxKindsByLinesCache.invalidate(self)
        syntaxTreeCache.invalidate(self)
        foldedSyntaxTreeCache.invalidate(self)
        locationConverterCache.invalidate(self)
        commandsCache.invalidate(self)
        linesWithTokensCache.invalidate(self)
    }

    @_spi(TestHelper)
    public static func clearCaches() {
        sourceKitResponseCache.clear()
        assertHandlerCache.clear()
        sourceKitStructureDictionaryCache.clear()
        syntaxClassificationsCache.clear()
        sourceKitSyntaxMapCache.clear()
        sourceKitSyntaxTokensByLinesCache.clear()
        sourceKitSyntaxKindsByLinesCache.clear()
        syntaxTreeCache.clear()
        foldedSyntaxTreeCache.clear()
        locationConverterCache.clear()
        commandsCache.clear()
        linesWithTokensCache.clear()
    }
}

private final class PlatformLock {
#if canImport(Darwin)
    private let primitiveLock: UnsafeMutablePointer<os_unfair_lock>
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
