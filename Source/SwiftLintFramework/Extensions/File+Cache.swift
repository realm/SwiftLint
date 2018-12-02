import Foundation
import SourceKittenFramework

private var responseCache = Cache({ file -> [String: SourceKitRepresentable]? in
    do {
        return try Request.editorOpen(file: file).sendIfNotDisabled()
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
private var syntaxMapCache = Cache({ file in responseCache.get(file).map(SyntaxMap.init) })
private var syntaxKindsByLinesCache = Cache({ file in file.syntaxKindsByLine() })
private var syntaxTokensByLinesCache = Cache({ file in file.syntaxTokensByLine() })

internal typealias AssertHandler = () -> Void

private var assertHandlers = [String: AssertHandler]()
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
    private var values = [String: T]()
    private let factory: (File) -> T
    private let lock = NSLock()

    fileprivate init(_ factory: @escaping (File) -> T) {
        self.factory = factory
    }

    fileprivate func get(_ file: File) -> T {
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

    fileprivate func invalidate(_ file: File) {
        doLocked { values.removeValue(forKey: file.cacheKey) }
    }

    fileprivate func clear() {
        doLocked { values.removeAll(keepingCapacity: false) }
    }

    fileprivate func set(key: String, value: T) {
        doLocked { values[key] = value }
    }

    fileprivate func unset(key: String) {
        doLocked { values.removeValue(forKey: key) }
    }

    private func doLocked(block: () -> Void) {
        lock.lock()
        block()
        lock.unlock()
    }
}

extension File {
    fileprivate var cacheKey: String {
        return path ?? contents
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

    internal var syntaxMap: SyntaxMap {
        guard let syntaxMap = syntaxMapCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return SyntaxMap(data: [])
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return syntaxMap
    }

    internal var syntaxTokensByLines: [[SyntaxToken]] {
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

    public func invalidateCache() {
        responseCache.invalidate(self)
        assertHandlerCache.invalidate(self)
        structureCache.invalidate(self)
        syntaxMapCache.invalidate(self)
        syntaxTokensByLinesCache.invalidate(self)
        syntaxKindsByLinesCache.invalidate(self)
    }

    internal static func clearCaches() {
        queueForRebuild.clear()
        responseCache.clear()
        assertHandlerCache.clear()
        structureCache.clear()
        syntaxMapCache.clear()
        syntaxTokensByLinesCache.clear()
        syntaxKindsByLinesCache.clear()
    }
}
