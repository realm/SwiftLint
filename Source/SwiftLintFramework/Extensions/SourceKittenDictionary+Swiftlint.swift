import SourceKittenFramework

extension SourceKittenDictionary {
    /// Returns array of tuples containing "key.kind" and "byteRange" from Structure
    /// that contains the byte offset. Returns all kinds if no parameter specified.
    ///
    /// - parameter byteOffset: Int?
    ///
    /// - returns: The kinds and byte ranges.
    internal func kinds(forByteOffset byteOffset: ByteCount? = nil)
        -> [(kind: String, byteRange: ByteRange)] {
        var results = [(kind: String, byteRange: ByteRange)]()

        func parse(_ dictionary: SourceKittenDictionary) {
            guard let range = dictionary.byteRange else {
                return
            }
            if let byteOffset, !range.contains(byteOffset) {
                return
            }
            if let kind = dictionary.kind {
                results.append((kind: kind, byteRange: range))
            }
            dictionary.substructure.forEach(parse)
        }
        parse(self)
        return results
    }

    internal func structures(forByteOffset byteOffset: ByteCount) -> [SourceKittenDictionary] {
        var results = [SourceKittenDictionary]()

        func parse(_ dictionary: SourceKittenDictionary) {
            guard let byteRange = dictionary.byteRange, byteRange.contains(byteOffset) else {
                return
            }

            results.append(dictionary)
            dictionary.substructure.forEach(parse)
        }
        parse(self)
        return results
    }

    /// Return the string content of this structure in the given file.
    /// - Parameter file: File this structure occurs in
    /// - Returns: The content of the file which this `SourceKittenDictionary` structure represents
    func content(in file: SwiftLintFile) -> String? {
        guard
            let byteRange = self.byteRange,
            let range = file.stringView.byteRangeToNSRange(byteRange)
        else {
            return nil
        }

        let body = file.stringView.nsString.substring(with: range)
        return String(body)
    }
}
