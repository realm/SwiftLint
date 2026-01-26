public extension Unicode.Scalar {
    /// Returns the number of bytes needed to encode this scalar in UTF-8.
    var utf8Length: Int {
        switch value {
        case 0x00...0x7F: 1
        case 0x80...0x7FF: 2
        case 0x800...0xFFFF: 3
        default: 4
        }
    }
}
