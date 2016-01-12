//
//  File+Cache.swift
//  SwiftLint
//
//  Created by Nikolaj Schumacher on 2015-05-26.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
import SwiftXPC

private var responseCache = Cache({file in Request.EditorOpen(file).send()})
private var structureCache = Cache({file in Structure(sourceKitResponse: responseCache.get(file))})
private var syntaxMapCache = Cache({file in SyntaxMap(sourceKitResponse: responseCache.get(file))})
private var syntaxKindsByLinesCache = Cache({file in file.syntaxKindsByLine()})

private var _allDeclarationsByType = [String: [String]]()
private var declarationMapNeedsRebuilding = true

private struct Cache<T> {

    private var values = [String: T]()
    private var factory: File -> T

    private init(_ factory: File -> T) {
        self.factory = factory
    }

    private mutating func get(file: File) -> T {
        let key = file.path ?? NSUUID().UUIDString
        if let value = values[key] {
            return value
        }
        let value = factory(file)
        values[key] = value
        if value is Structure {
            declarationMapNeedsRebuilding = true
        }
        return value
    }

    private mutating func clear() {
        values.removeAll(keepCapacity: false)
    }
}

public extension File {

    public var structure: Structure {
        return structureCache.get(self)
    }

    public var syntaxMap: SyntaxMap {
        return syntaxMapCache.get(self)
    }

    public var syntaxKindsByLines: [(Int, [SyntaxKind])] {
        return syntaxKindsByLinesCache.get(self)
    }

    public static func clearCaches() {
        declarationMapNeedsRebuilding = true
        _allDeclarationsByType = [:]
        structureCache.clear()
        syntaxMapCache.clear()
        syntaxKindsByLinesCache.clear()
    }

    public static var allDeclarationsByType: [String: [String]] {
        if declarationMapNeedsRebuilding {
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

private func substructureForDict(dict: XPCDictionary) -> [XPCDictionary]? {
    return (dict["key.substructure"] as? XPCArray)?.flatMap { $0 as? XPCDictionary }
}

private func rebuildAllDeclarationsByType() {
    let structures = structureCache.values.map { $0.1 }
    let allDeclarationsByType = structures.flatMap { structure -> (String, [String])? in
        guard let firstSubstructureDict = substructureForDict(structure.dictionary)?.first,
            name = firstSubstructureDict["key.name"] as? String,
            kind = (firstSubstructureDict["key.kind"] as? String).flatMap(SwiftDeclarationKind.init)
            where kind == .Protocol,
            let substructure = substructureForDict(firstSubstructureDict) else {
                return nil
        }
        return (name, substructure.flatMap({ $0["key.name"] as? String }))
    }
    _allDeclarationsByType = dictFromKeyValuePairs(allDeclarationsByType)
    declarationMapNeedsRebuilding = false
}
