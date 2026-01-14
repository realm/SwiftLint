import Foundation

public extension URL {
    var filepath: String {
        withUnsafeFileSystemRepresentation { String(cString: $0!) }
    }

    var filepathGuarded: String? {
        withUnsafeFileSystemRepresentation { ptr in
            guard let ptr else {
                Issue.genericError(
                    "File with URL '\(self)' cannot be represented as a file system path; skipping it"
                ).print()
                return nil
            }
            return String(cString: ptr)
        }
    }

    var isSwiftFile: Bool {
        filepath.isFile && pathExtension == "swift"
    }
}
