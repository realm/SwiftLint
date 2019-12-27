import Foundation

extension SourceKittenDictionary {
    /// Returns array of tuples containing "key.kind" and "byteRange" from Structure
    /// that contains the byte offset. Returns all kinds if no parameter specified.
    ///
    /// - Parameter byteOffset: Int?
    internal func kinds(forByteOffset byteOffset: Int? = nil)
        -> [(kind: String, byteRange: NSRange)] {
        var results = [(kind: String, byteRange: NSRange)]()

        func parse(_ dictionary: SourceKittenDictionary) {
            guard let offset = dictionary.offset,
                let byteRange = dictionary.length.map({ NSRange(location: offset, length: $0) }) else {
                    return
            }
            if let byteOffset = byteOffset, !NSLocationInRange(byteOffset, byteRange) {
                return
            }
            if let kind = dictionary.kind {
                results.append((kind: kind, byteRange: byteRange))
            }
            dictionary.substructure.forEach(parse)
        }
        parse(self)
        return results
    }

    internal func structures(forByteOffset byteOffset: Int) -> [SourceKittenDictionary] {
        var results = [SourceKittenDictionary]()

        func parse(_ dictionary: SourceKittenDictionary) {
            guard let offset = dictionary.offset,
                let byteRange = dictionary.length.map({ NSRange(location: offset, length: $0) }),
                NSLocationInRange(byteOffset, byteRange) else {
                    return
            }

            results.append(dictionary)
            dictionary.substructure.forEach(parse)
        }
        parse(self)
        return results
    }
}
