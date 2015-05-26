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
        if let path = file.path {
            if let value = values[path] {
                return value
            } else {
                let value = factory(file)
                values[path] = value
                return value
            }
        } else {
            return factory(file)
        }
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
