//
//  File+Cache.swift
//  SwiftLint
//
//  Created by Nikolaj Schumacher on 5/26/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private var responseCache = Cache({ file -> [String: SourceKitRepresentable]? in
    do {
        return try Request.editorOpen(file: file).failableSend()
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

private struct Cache<T> {
    private var values = [String: T]()
    private let factory: (File) -> T
    private let lock = NSLock()

    fileprivate init(_ factory: @escaping (File) -> T) {
        self.factory = factory
    }

    fileprivate mutating func get(_ file: File) -> T {
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

    fileprivate mutating func invalidate(_ file: File) {
        doLocked { values.removeValue(forKey: file.cacheKey) }
    }

    fileprivate mutating func clear() {
        doLocked { values.removeAll(keepingCapacity: false) }
    }

    fileprivate mutating func set(key: String, value: T) {
        doLocked { values[key] = value }
    }

    fileprivate mutating func unset(key: String) {
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
            return assertHandlers[cacheKey]
        }
        set {
            assertHandlers[cacheKey] = newValue
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
        assertHandlers.removeValue(forKey: cacheKey)
        structureCache.invalidate(self)
        syntaxMapCache.invalidate(self)
        syntaxTokensByLinesCache.invalidate(self)
        syntaxKindsByLinesCache.invalidate(self)
    }

    internal static func clearCaches() {
        queueForRebuild.clear()
        responseCache.clear()
        assertHandlers.removeAll(keepingCapacity: false)
        structureCache.clear()
        syntaxMapCache.clear()
        syntaxTokensByLinesCache.clear()
        syntaxKindsByLinesCache.clear()
    }
}
