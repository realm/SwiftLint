//
//  File+Cache.swift
//  SwiftLint
//
//  Created by Nikolaj Schumacher on 2015-05-26.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private var responseCache = Cache({file -> [String: SourceKitRepresentable]? in
    do {
        return try Request.EditorOpen(file).failableSend()
    } catch let error as Request.Error {
        queuedPrintError(error.description)
        return nil
    } catch {
        return nil
    }
})
private var structureCache = Cache({file -> Structure? in
    if let structure = responseCache.get(file).map(Structure.init) {
        queueForRebuild.append(structure)
        return structure
    }
    return nil
})
private var syntaxMapCache = Cache({file in responseCache.get(file).map(SyntaxMap.init)})
private var syntaxKindsByLinesCache = Cache({file in file.syntaxKindsByLine()})

private typealias AssertHandler = () -> ()
private var assertHandlers = [String: AssertHandler?]()

private var _allDeclarationsByType = [String: [String]]()
private var queueForRebuild = [Structure]()

private struct Cache<T> {

    private var values = [String: T]()
    private var factory: File -> T

    private init(_ factory: File -> T) {
        self.factory = factory
    }

    private mutating func get(file: File) -> T {
        let key = file.cacheKey
        if let value = values[key] {
            return value
        }
        let value = factory(file)
        values[key] = value
        return value
    }

    private mutating func invalidate(file: File) {
        if let key = file.path {
            values.removeValueForKey(key)
        }
    }

    private mutating func clear() {
        values.removeAll(keepCapacity: false)
    }
}

extension File {

    private var cacheKey: String {
        return path ?? "\(ObjectIdentifier(self).hashValue)"
    }

    internal var sourcekitdFailed: Bool {
        get {
            return responseCache.get(self) == nil
        }
        set {
            if newValue {
                responseCache.values[cacheKey] = Optional<[String: SourceKitRepresentable]>.None
            } else {
                responseCache.values.removeValueForKey(cacheKey)
            }
        }
    }

    internal var assertHandler: (() -> ())? {
        get {
            return assertHandlers[cacheKey] ?? nil
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
            fatalError("Never call this for file that sourcekitd fails.")
        }
        return structure
    }

    internal var syntaxMap: SyntaxMap {
        guard let syntaxMap = syntaxMapCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return SyntaxMap(data: [])
            }
            fatalError("Never call this for file that sourcekitd fails.")
        }
        return syntaxMap
    }

    internal var syntaxKindsByLines: [[SyntaxKind]] {
        guard let syntaxKindsByLines = syntaxKindsByLinesCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return []
            }
            fatalError("Never call this for file that sourcekitd fails.")
        }
        return syntaxKindsByLines
    }

    public func invalidateCache() {
        responseCache.invalidate(self)
        assertHandlers.removeValueForKey(cacheKey)
        structureCache.invalidate(self)
        syntaxMapCache.invalidate(self)
        syntaxKindsByLinesCache.invalidate(self)
    }

    internal static func clearCaches() {
        queueForRebuild = []
        _allDeclarationsByType = [:]
        responseCache.clear()
        assertHandlers = [:]
        structureCache.clear()
        syntaxMapCache.clear()
        syntaxKindsByLinesCache.clear()
    }

    internal static var allDeclarationsByType: [String: [String]] {
        if !queueForRebuild.isEmpty {
            rebuildAllDeclarationsByType()
        }
        return _allDeclarationsByType
    }
}

private func dictFromKeyValuePairs<Key: Hashable, Value>(pairs: [(Key, Value)]) -> [Key: Value] {
    var dict = [Key: Value]()
    for pair in pairs {
        dict[pair.0] = pair.1
    }
    return dict
}

private func substructureForDict(dict: [String: SourceKitRepresentable]) ->
                                 [[String: SourceKitRepresentable]]? {
    return (dict["key.substructure"] as? [SourceKitRepresentable])?.flatMap {
        $0 as? [String: SourceKitRepresentable]
    }
}

private func rebuildAllDeclarationsByType() {
    let allDeclarationsByType = queueForRebuild.flatMap { structure -> (String, [String])? in
        guard let firstSubstructureDict = substructureForDict(structure.dictionary)?.first,
            name = firstSubstructureDict["key.name"] as? String,
            kind = (firstSubstructureDict["key.kind"] as? String).flatMap(SwiftDeclarationKind.init)
            where kind == .Protocol,
            let substructure = substructureForDict(firstSubstructureDict) else {
                return nil
        }
        return (name, substructure.flatMap({ $0["key.name"] as? String }))
    }
    allDeclarationsByType.forEach { _allDeclarationsByType[$0.0] = $0.1 }
    queueForRebuild = []
}
