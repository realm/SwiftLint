//
//  QueuedPrint.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-11-17.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation

private let outputQueue: dispatch_queue_t = {
    let queue = dispatch_queue_create("io.realm.swiftlint.outputQueue", DISPATCH_QUEUE_SERIAL)
    dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0))

    atexit_b {
        dispatch_barrier_sync(queue) {}
    }

    return queue
}()

/**
 A thread-safe version of Swift's standard print().

 - parameter object: Object to print.
 */
public func queuedPrint<T>(object: T) {
    dispatch_async(outputQueue) {
        print(object)
    }
}

/**
 A thread-safe, newline-terminated version of fputs(..., stderr).

 - parameter string: String to print.
 */
public func queuedPrintError(string: String) {
    dispatch_async(outputQueue) {
        fflush(stdout)
        fputs(string + "\n", stderr)
    }
}
