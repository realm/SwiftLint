import Foundation

public protocol LintableFileManager {
    func filesToLint(inPath: String, rootDirectory: String?) -> [String]
    func modificationDate(forFileAtPath: String) -> Date?
}

extension FileManager: LintableFileManager {
    public func filesToLint(inPath path: String, rootDirectory: String? = nil) -> [String] {
        let rootPath = rootDirectory ?? currentDirectoryPath
        let absolutePath = path.bridge()
            .absolutePathRepresentation(rootDirectory: rootPath).bridge()
            .standardizingPath

        // if path is a file, it won't be returned in `enumerator(atPath:)`
        if absolutePath.bridge().isSwiftFile() && absolutePath.isFile {
            return [absolutePath]
        }

#if os(Linux)
        return enumerator(atPath: absolutePath)?.compactMap { element -> String? in
            guard let element = element as? String, element.bridge().isSwiftFile() else { return nil }
            let absoluteElementPath = absolutePath.bridge().appendingPathComponent(element)
            return absoluteElementPath.isFile ? absoluteElementPath : nil
        } ?? []
#else
        return subpaths(atPath: absolutePath)?.parallelCompactMap { element -> String? in
            guard element.bridge().isSwiftFile() else { return nil }
            let absoluteElementPath = absolutePath.bridge().appendingPathComponent(element)
            return absoluteElementPath.isFile ? absoluteElementPath : nil
        } ?? []
#endif
    }

    public func modificationDate(forFileAtPath path: String) -> Date? {
        return (try? attributesOfItem(atPath: path))?[.modificationDate] as? Date
    }
}
