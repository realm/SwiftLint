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

#if os(Darwin)
        return subpaths(atPath: absolutePath)?.compactMap { element -> String? in
            guard element.bridge().isSwiftFile() else { return nil }
            let absoluteElementPath = absolutePath.bridge().appendingPathComponent(element)
            return absoluteElementPath.isFile ? absoluteElementPath : nil
        } ?? []
#else
        return enumerator(atPath: absolutePath)?.compactMap { element -> String? in
            if let element = element as? String,
                element.bridge().isSwiftFile() && (absolutePath + "/" + element).isFile {
                return absolutePath.bridge().appendingPathComponent(element)
            }
            return nil
        } ?? []
#endif
    }

    public func modificationDate(forFileAtPath path: String) -> Date? {
        return (try? attributesOfItem(atPath: path))?[.modificationDate] as? Date
    }
}
