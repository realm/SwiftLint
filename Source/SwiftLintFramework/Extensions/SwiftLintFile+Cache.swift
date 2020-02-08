import Foundation
import SourceKittenFramework
#if canImport(SwiftSyntax)
import SwiftSyntax
#endif

private typealias FileCacheKey = Int
private var responseCache = Cache({ file -> [String: SourceKitRepresentable]? in
    do {
        return try Request.editorOpen(file: file.file).sendIfNotDisabled()
    } catch let error as Request.Error {
        queuedPrintError(error.description)
        return nil
    } catch {
        return nil
    }
})
private var structureCache = Cache({ file -> Structure? in
    if let structure = responseCache.get(file).map(Structure.init) {
        queueForRebuild.append(structure)
        return structure
    }
    return nil
})

private var structureDictionaryCache = Cache({ file in
    return structureCache.get(file).map { SourceKittenDictionary($0.dictionary) }
})

private var syntaxMapCache = Cache({ file in
    responseCache.get(file).map { SwiftLintSyntaxMap(value: SyntaxMap(sourceKitResponse: $0)) }
})
private var syntaxKindsByLinesCache = Cache({ file in file.syntaxKindsByLine() })
private var syntaxTokensByLinesCache = Cache({ file in file.syntaxTokensByLine() })

#if canImport(SwiftSyntax)
private var syntaxCache = Cache({ file -> SourceFileSyntax? in
    do {
        if let path = file.path {
            return try SyntaxParser.parse(URL(fileURLWithPath: path))
        }

         return try SyntaxParser.parse(source: file.contents)
    } catch {
        return nil
    }
})
#endif

internal typealias AssertHandler = () -> Void

private var assertHandlers = [FileCacheKey: AssertHandler]()
private var assertHandlerCache = Cache({ file in assertHandlers[file.cacheKey] })

private struct RebuildQueue {
    private let lock = NSLock()
    private var queue = [Structure]()

    mutating func append(_ structure: Structure) {
        lock.lock()
        defer { lock.unlock() }
        queue.append(structure)
    }

    mutating func clear() {
        lock.lock()
        defer { lock.unlock() }
        queue.removeAll(keepingCapacity: false)
    }
}

private var queueForRebuild = RebuildQueue()

private class Cache<T> {
    private var values = [FileCacheKey: T]()
    private let factory: (SwiftLintFile) -> T
    private let lock = NSLock()

    fileprivate init(_ factory: @escaping (SwiftLintFile) -> T) {
        self.factory = factory
    }

    fileprivate func get(_ file: SwiftLintFile) -> T {
        let key = file.cacheKey
        lock.lock()
        defer { lock.unlock() }
        if let cachedValue = values[key] {
            return cachedValue
        }
        let value = factory(file)
        values[key] = value
        return value
    }

    fileprivate func invalidate(_ file: SwiftLintFile) {
        doLocked { values.removeValue(forKey: file.cacheKey) }
    }

    fileprivate func clear() {
        doLocked { values.removeAll(keepingCapacity: false) }
    }

    fileprivate func set(key: FileCacheKey, value: T) {
        doLocked { values[key] = value }
    }

    fileprivate func unset(key: FileCacheKey) {
        doLocked { values.removeValue(forKey: key) }
    }

    private func doLocked(block: () -> Void) {
        lock.lock()
        block()
        lock.unlock()
    }
}

extension SwiftLintFile {
    fileprivate var cacheKey: FileCacheKey {
        return id
    }

    internal var sourcekitdFailed: Bool {
        get {
            return responseCache.get(self) == nil
        }
        set {
            if newValue {
                responseCache.set(key: cacheKey, value: nil)
            } else {
                responseCache.unset(key: cacheKey)
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

    internal var structure: Structure {
        guard let structure = structureCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return Structure(sourceKitResponse: [:])
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return structure
    }

    internal var structureDictionary: SourceKittenDictionary {
        guard let structureDictionary = structureDictionaryCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return SourceKittenDictionary([:])
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return structureDictionary
    }

    internal var syntaxMap: SwiftLintSyntaxMap {
        guard let syntaxMap = syntaxMapCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return SwiftLintSyntaxMap(value: SyntaxMap(data: []))
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return syntaxMap
    }

    #if canImport(SwiftSyntax)
    internal var syntax: SourceFileSyntax {
        guard let syntax = syntaxCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return SourceFileSyntax({ _ in })
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return syntax
    }
    #endif

    internal var syntaxTokensByLines: [[SwiftLintSyntaxToken]] {
        guard let syntaxTokensByLines = syntaxTokensByLinesCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return []
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return syntaxTokensByLines
    }

    internal var syntaxKindsByLines: [[SyntaxKind]] {
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
        responseCache.invalidate(self)
        assertHandlerCache.invalidate(self)
        structureCache.invalidate(self)
        structureDictionaryCache.invalidate(self)
        syntaxMapCache.invalidate(self)
        syntaxTokensByLinesCache.invalidate(self)
        syntaxKindsByLinesCache.invalidate(self)
        #if canImport(SwiftSyntax)
        syntaxCache.invalidate(self)
        #endif
    }

    internal static func clearCaches() {
        queueForRebuild.clear()
        responseCache.clear()
        assertHandlerCache.clear()
        structureCache.clear()
        structureDictionaryCache.clear()
        syntaxMapCache.clear()
        syntaxTokensByLinesCache.clear()
        syntaxKindsByLinesCache.clear()
        #if canImport(SwiftSyntax)
        syntaxCache.clear()
        #endif
    }
}
