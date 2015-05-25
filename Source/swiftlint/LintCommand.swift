//
//  LintCommand.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Commandant
import Foundation
import LlamaKit
import SourceKittenFramework
import SwiftLintFramework

let fileManager = NSFileManager.defaultManager()

struct LintCommand: CommandType {
    let verb = "lint"
    let function = "Print lint warnings and errors for the Swift files in the current directory " +
                   "(default command)"

    func run(mode: CommandMode) -> Result<(), CommandantError<()>> {
        println("Finding Swift files in current directory...")
        let files = recursivelyFindSwiftFilesInDirectory(fileManager.currentDirectoryPath)
        var numberOfViolations = 0, numberOfSeriousViolations = 0
        for (index, file) in enumerate(files) {
            println("Linting '\(file.lastPathComponent)' (\(index + 1)/\(files.count))")
            for violation in Linter(file: File(path: file)!).styleViolations {
                println(violation)
                numberOfViolations++
                if violation.severity.isError {
                    numberOfSeriousViolations++
                }
            }
        }
        let violationSuffix = (numberOfViolations != 1 ? "s" : "")
        let filesSuffix = (files.count != 1 ? "s." : ".")
        println(
            "Done linting!" +
            " Found \(numberOfViolations) violation\(violationSuffix)," +
            " \(numberOfSeriousViolations) serious" +
            " in \(files.count) file\(filesSuffix)"
        )
        if numberOfSeriousViolations <= 0 {
            return success()
        } else {
            // This represents failure of the content (i.e. violations in the files linted)
            // and not failure of the scanning process itself. The current command architecture
            // doesn't discriminate between these types.
            return failure(CommandantError<()>.CommandError(Box()))
        }
    }
}

func recursivelyFindSwiftFilesInDirectory(directory: String) -> [String] {
    let subPaths = fileManager.subpathsOfDirectoryAtPath(directory, error: nil) as? [String]
    return map(subPaths) { subPaths in
        return reduce(compact((["."] + subPaths).map { dirPath in
            let files = fileManager.contentsOfDirectoryAtPath(dirPath, error: nil) as? [String]
            return map(files) { files in
                return files.map { file in
                    return directory.stringByAppendingPathComponent(dirPath)
                        .stringByAppendingPathComponent(file).stringByStandardizingPath
                }
            }
        }), [], +).filter {
            $0.isSwiftFile()
        }
    } ?? []
}
