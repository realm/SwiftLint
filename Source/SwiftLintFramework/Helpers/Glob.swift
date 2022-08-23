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
        var shouldToLintForPaths = [String]()
        vagueSearchStarPaths(pattern: optimizationGeneralPath(pattern: pattern), lintPaths: &shouldToLintForPaths)
//        debugPrint(shouldToLintForPaths)
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
//                debugPrint("invalid paths: \(pattern)")
                return
            }
            lintPaths.append(pattern) // valid paths and no include star dir
            return
        }

        /// split two paths
        let path_parts = splitDoubleStarDirPath(path: pattern)
        let current_matching_dir = path_parts[0].bridge().deletingLastPathComponent
        let general_folders = path_parts[0].bridge().lastPathComponent
        let remain_parts = path_parts[1]

//        debugPrint("start matching search: \(current_matching_dir), vague: \(general_folders), remain: \(remain_parts)")
        searchMatchingDir(searchDir: current_matching_dir, vagueExpression: general_folders, remainPath: remain_parts, lintPaths: &lintPaths)
    }

    /// matching include * folder
    /// - Parameters:
    ///   - searchDir: search target dir
    ///   - vagueExpression: star dir , eg: *DM*, DM*,*DM, **,  s*ed
    ///   - remainPath: last path
    private static func searchMatchingDir(searchDir: String, vagueExpression: String, remainPath: String, lintPaths: inout [String]) {
        let fileManager = FileManager.default
        let searchPath = searchDir.isEmpty ? fileManager.currentDirectoryPath : searchDir
        let loop_all = vagueExpression.isEqualTo("**")
        do {
            var top_sub_dir = ""
            _ = try fileManager.subpathsOfDirectory(atPath: searchPath).compactMap({ subpath in
                guard !subpath.contains(top_sub_dir) || loop_all else {
                    return
                }

                top_sub_dir = subpath

                if isMatching(src: subpath, pstr: vagueExpression) {
                    var next_folder = searchPath.bridge().appendingPathComponent(subpath)
                    if !remainPath.isEmpty {
                        next_folder = next_folder.bridge().appendingPathComponent(remainPath)
                    }
                    vagueSearchStarPaths(pattern: next_folder, lintPaths: &lintPaths)
                }
            })
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
            var found_star = false
            for ( cidx, citem ) in first.enumerated() {
                if citem == "*" {
                    found_star = true
                }

                if citem == "/", found_star {
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

        var first_is_star = false
        var last_is_star = false
        var mid_is_start = false
        var matchstr = ""
        for (idx, ic) in pstr.enumerated() {
            if idx == 0, "*".isEqualTo(String(ic)) {
                first_is_star = true
            }
            if idx == pstr.count - 1, "*".isEqualTo(String(ic)) {
                last_is_star = true
            }

            if "*".isEqualTo(String(ic)) {
                mid_is_start = true
                continue
            }

            matchstr += String(ic)
        }

        guard !matchstr.isEmpty else {
            return false
        }

        if first_is_star && last_is_star { // match being star, end star. eg: *xx*
            var tmp = src

            if let range: Range = tmp.range(of: matchstr) {
                let location = tmp.distance(from: tmp.startIndex, to: range.lowerBound)

                if location == 0 {
                    tmp.removeSubrange(range)
                }
            }

            tmp = String(tmp.reversed())

            if let range: Range = tmp.range(of: String(matchstr.reversed())) {
                let location = tmp.distance(from: tmp.startIndex, to: range.lowerBound)

                if location == 0 {
                    tmp.removeSubrange(range)
                }
            }

            tmp = String(tmp.reversed())

            return tmp.contains(matchstr)
        } else if first_is_star { // matching being star. eg: *subs
            let len = matchstr.count
            let laststr = String(src.suffix(len))
            return laststr.isEqualTo(matchstr)
        } else if last_is_star {// matching end star. eg: folder*
            let len = matchstr.count
            let prestr = String(src.prefix(len))
            return prestr.isEqualTo(matchstr)
        } else if mid_is_start {// matching mid stat. eg: s*ed
            let folder_parts = pstr.components(separatedBy: "*")
            guard folder_parts.count == 2 else {
                return false
            }
            return src.hasPrefix(folder_parts[0]) && src.hasSuffix(folder_parts[1])
        }

        return false
    }
}
