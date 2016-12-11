//
//  QueuedPrint.swift
//  SwiftLint
//
//  Created by JP Simard on 11/17/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Dispatch
import Foundation

private let outputQueue: DispatchQueue = {
    let queue = DispatchQueue(
        label: "io.realm.swiftlint.outputQueue",
        qos: .userInteractive,
        target: .global(qos: .userInteractive)
    )

    #if !os(Linux)
    atexit_b {
        queue.sync(flags: .barrier) {}
    }
    #endif

    return queue
}()

/**
 A thread-safe version of Swift's standard print().

 - parameter object: Object to print.
 */
public func queuedPrint<T>(_ object: T) {
    outputQueue.async {
        print(object)
    }
}

/**
 A thread-safe, newline-terminated version of fputs(..., stderr).

 - parameter string: String to print.
 */
public func queuedPrintError(_ string: String) {
    outputQueue.async {
        fflush(stdout)
        fputs(string + "\n", stderr)
    }
}
