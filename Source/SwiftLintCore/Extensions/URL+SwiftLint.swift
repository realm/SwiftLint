import Foundation

public extension URL {
    var filepath: String {
        self.withUnsafeFileSystemRepresentation { String(cString: $0!) }
    }

    var isSwiftFile: Bool {
        filepath.isFile && pathExtension == "swift"
    }
}
