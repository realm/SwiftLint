import Foundation

public extension URL {
  var filepath: String {
#if _runtime(_ObjC)
    String(cString: fileSystemRepresentation)
#else
    self.withUnsafeFileSystemRepresentation { String(cString: $0!) }
#endif
  }
}
