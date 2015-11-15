//
//  File+Cache.swift
//  SwiftLint
//
//  Created by Nikolaj Schumacher on 2015-05-26.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

private var structureCache = Cache({file in Structure(file: file)})
private var syntaxMapCache = Cache({file in SyntaxMap(file: file)})

private struct Cache<T> {

    private var values = [String: T]()
    private var factory: File -> T

    private init(_ factory: File -> T) {
        self.factory = factory
    }

    private mutating func get(file: File) -> T {
        guard let path = file.path else {
            return factory(file)
        }
        if let value = values[path] {
            return value
        }
        let value = factory(file)
        values[path] = value
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

    public static func clearCaches() {
        structureCache.clear()
        syntaxMapCache.clear()
    }
}
