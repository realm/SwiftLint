//
//  SwiftLintExecutable.swift
//  SwiftLint
//
//  Created by Sash Zats on 6/22/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import Result


enum SwiftLintExecutionError: ErrorType {
    case ExecutionFailed
    case LintError(String)
}

struct SwiftLintExecutable {

    private let path: String

    init() {
        let products = testBundle.bundleURL.URLByDeletingLastPathComponent!
        let executable = products
            .URLByAppendingPathComponent("swiftlint.app/Contents/MacOS/swiftlint")
        self.path = executable.relativePath!
    }

    func execute(arguments: [String]) -> Result<String, SwiftLintExecutionError> {

        let task = NSTask()
        task.launchPath = path
        task.arguments = arguments

        let successPipe = NSPipe()
        task.standardOutput = successPipe

        let failurePipe = NSPipe()
        task.standardError = failurePipe

        task.launch()
        task.waitUntilExit()

        let errorData = failurePipe.fileHandleForReading.readDataToEndOfFile()
        if let error = String(data: errorData, encoding: NSUTF8StringEncoding)
            where !error.characters.isEmpty {
            return .Failure(.LintError(error))
        }

        let data = successPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: NSUTF8StringEncoding) else {
            return .Failure(.ExecutionFailed)
        }
        return .Success(output)

    }
}
