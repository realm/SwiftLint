import Foundation

#if canImport(Darwin)
import Darwin

private let globFunction = Darwin.glob
#elseif canImport(Glibc)
import Glibc

private let globFunction = Glibc.glob
#else
#error("Unsupported platform")
#endif

// Adapted from https://gist.github.com/efirestone/ce01ae109e08772647eb061b3bb387c3

struct Glob {
    static func resolveGlob(_ pattern: String) -> [String] {
        let globCharset = CharacterSet(charactersIn: "*?[]")
        guard pattern.rangeOfCharacter(from: globCharset) != nil else {
            return [pattern]
        }

        return expandGlobstar(pattern: pattern)
            .reduce(into: [String]()) { paths, pattern in
                var globResult = glob_t()
                defer { globfree(&globResult) }

                if globFunction(pattern, GLOB_TILDE | GLOB_BRACE | GLOB_MARK, nil, &globResult) == 0 {
                    paths.append(contentsOf: populateFiles(globResult: globResult))
                }
            }
            .unique
            .sorted()
            .map { $0.absolutePathStandardized() }
    }

    // MARK: Private
    private static func expandGlobstar(pattern: String) -> [String] {
        // not include star, or .swift files, eg: level[0-9].swift
        guard pattern.contains("*") else {
            return [pattern]
        }

        var shouldToLintForPaths = [String]()
        vagueSearchStarPaths(pattern: optimizationGeneralPath(pattern: pattern),
                             lintPaths: &shouldToLintForPaths)
        return shouldToLintForPaths
    }

    private static func isDirectory(path: String) -> Bool {
        var isDirectoryBool = ObjCBool(false)
        let isDirectory = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectoryBool)
        return isDirectory && isDirectoryBool.boolValue
    }

    private static func populateFiles(globResult: glob_t) -> [String] {
#if os(Linux)
        let matchCount = globResult.gl_pathc
#else
        let matchCount = globResult.gl_matchc
#endif
        return (0..<Int(matchCount)).compactMap { index in
            globResult.gl_pathv[index].flatMap { String(validatingUTF8: $0) }
        }
    }

    // optimization path
    private static func optimizationGeneralPath(pattern: String) -> String {
        let special = "**/**/"
        let only = "**/"
        var tmp = pattern
        while tmp.contains(special) {
            tmp = tmp.replacingOccurrences(of: special, with: only)
        }
        return tmp
    }

    /*
     
     enable vague matching at path include * or **
      /**/ all sub dirs
    */
    private static func vagueSearchStarPaths(pattern: String, lintPaths: inout [String]) {
        // path include * or **，eg:  /Test*/**/demo/f*/**/
        guard pattern.contains("*") else {
            guard isDirectory(path: pattern) else { // filter invalid paths
                return
            }
            lintPaths.append(pattern) // valid paths and no include star dir
            return
        }
        // is *.swift , Leve*.swift
        guard !pattern.hasSuffix(".swift") || pattern.contains("**") else {
            lintPaths.append(pattern)
            return
        }

        /// split two paths
        let pathParts = splitDoubleStarDirPath(path: pattern)
        let currentMatchingDir = pathParts[0].bridge().deletingLastPathComponent
        let generalFolders = pathParts[0].bridge().lastPathComponent
        let remainParts = pathParts[1]

//        debugPrint("start matching search: \(currentMatchingDir), vague: \(generalFolders), remain: \(remainParts)")
        searchMatchingDir(searchDir: currentMatchingDir,
                          vagueExpression: generalFolders,
                          remainPath: remainParts,
                          lintPaths: &lintPaths)
    }
    /// matching include * folder
    /// - Parameters:
    ///   - searchDir: search target dir
    ///   - vagueExpression: star dir , eg: *DM*, DM*,*DM, **,  s*ed
    ///   - remainPath: last path
    private static func searchMatchingDir(searchDir: String,
                                          vagueExpression: String,
                                          remainPath: String,
                                          lintPaths: inout [String]) {
        let fileManager = FileManager.default
        let searchPath = searchDir.isEmpty ? fileManager.currentDirectoryPath : searchDir
        let loopAll = vagueExpression.isEqualTo("**")
        do {
            var topSubDir = ""
            _ = try fileManager.subpathsOfDirectory(atPath: searchPath).compactMap({ subpath in
                guard !subpath.contains(topSubDir) || loopAll else {
                    return
                }

                topSubDir = subpath

                if isMatching(src: subpath, pstr: vagueExpression) {
                    var nextFolder = searchPath.bridge().appendingPathComponent(subpath)
                    // filter files
                    guard isDirectory(path: nextFolder) else {
                        return
                    }
                    if !remainPath.isEmpty {
                        nextFolder = nextFolder.bridge().appendingPathComponent(remainPath)
                    }

                    vagueSearchStarPaths(pattern: nextFolder, lintPaths: &lintPaths)
                }
            })
            // if **, search current self 
            if loopAll, !remainPath.isEmpty {
                let next = searchPath.bridge().appendingPathComponent(remainPath)
                vagueSearchStarPaths(pattern: next, lintPaths: &lintPaths)
            }
        } catch {
            queuedPrintError("filter Sub Path: \(searchPath) Error : \(error)")
        }
    }

    /// path: /user/demo/*Test*/su*/**/**/foo/**/*dm
    private static func splitDoubleStarDirPath(path: String) -> [String] {
        guard path.contains("**") else {
            return [path, ""]
        }

        var parts = path.components(separatedBy: "**")
        var first = parts.removeFirst()
        var last = parts.joined(separator: "**")

        // eg: local/host/tk*, local/host/tk*/*rec*/
        if first.contains("*") {
            var spos = -1
            var foundStar = false
            for ( cidx, citem ) in first.enumerated() {
                if citem == "*" {
                    foundStar = true
                }

                if citem == "/", foundStar {
                    spos = cidx
                    break
                }
            }
            if spos > 0 {
                let start = first.index(first.startIndex, offsetBy: spos)
                let part = String(first.suffix(from: start))
                first = String(first.prefix(spos))
                last = part.bridge().appendingPathComponent("**").bridge().appendingPathComponent(last)
            }
        } else {
            first = first.bridge().appendingPathComponent("**")
        }

        return [first, last]
    }
    /**
     src: moTestDemo    pstr: *Test*         true
     src: moTestDemo    pstr: *Test          false
     src: moTestDemo    pstr: Test*          false
     src: moTestDemo    pstr: mo*           true
     src: moTestDemo    pstr: *mo*        false
     src: moTestDemo   pstr: *mo           true
     src: moTestDemo pstr: m*mo          true
     src: moTestmoDemo  pstr: *mo*     true
     src: Any String     pstr: **              true
     src: moTestDemo   pstr: *m*T*D*     is not support.
     */
    private static func isMatching(src: String, pstr: String) -> Bool {
        guard !pstr.contains("**") else { // matching any folders
            return true
        }

        guard pstr.contains("*")  else {
            return src.isEqualTo(pstr)
        }

        var firstIsStar = false
        var lastIsStar = false
        var midIsStart = false
        var matchstr = ""
        for (idx, icstr) in pstr.enumerated() {
            if idx == 0, "*".isEqualTo(String(icstr)) {
                firstIsStar = true
            }
            if idx == pstr.count - 1, "*".isEqualTo(String(icstr)) {
                lastIsStar = true
            }

            if "*".isEqualTo(String(icstr)) {
                midIsStart = true
                continue
            }

            matchstr += String(icstr)
        }

        guard !matchstr.isEmpty else {
            return false
        }
        let tupleStr: ( String, String, String ) = ( src, matchstr, pstr )
        return dispatchMatching(firstIsStar,
                                lastIsStar,
                                midIsStart,
                                tupleStr)
    }

    private static func dispatchMatching(_ firstIsStar: Bool,
                                         _ lastIsStar: Bool,
                                         _ midIsStart: Bool,
                                         _ origin: (String, String, String)
                                         ) -> Bool {
        let src = origin.0
        let matchstr = origin.1
        let pstr = origin.2
        if firstIsStar && lastIsStar { // match being star, end star. eg: *xx*
            return matchingMidString(src: src, mstr: matchstr)
        } else if firstIsStar { // matching being star. eg: *subs
            let len = matchstr.count
            let laststr = String(src.suffix(len))
            return laststr.isEqualTo(matchstr)
        } else if lastIsStar {// matching end star. eg: folder*
            let len = matchstr.count
            let prestr = String(src.prefix(len))
            return prestr.isEqualTo(matchstr)
        } else if midIsStart {// matching mid stat. eg: s*ed
            let folderParts = pstr.components(separatedBy: "*")
            guard folderParts.count == 2 else {
                return false
            }
            return src.hasPrefix(folderParts[0]) && src.hasSuffix(folderParts[1])
        }
        return false
    }

    private static func matchingMidString(src: String, mstr: String) -> Bool {
        var tmp = src
        if let range: Range = tmp.range(of: mstr) {
            let location = tmp.distance(from: tmp.startIndex, to: range.lowerBound)

            if location == 0 {
                tmp.removeSubrange(range)
            }
        }

        tmp = String(tmp.reversed())

        if let range: Range = tmp.range(of: String(mstr.reversed())) {
            let location = tmp.distance(from: tmp.startIndex, to: range.lowerBound)

            if location == 0 {
                tmp.removeSubrange(range)
            }
        }

        tmp = String(tmp.reversed())

        return tmp.contains(mstr)
    }
}
