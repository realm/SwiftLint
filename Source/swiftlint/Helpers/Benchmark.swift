//
//  Benchmark.swift
//  SwiftLint
//
//  Created by JP Simard on 1/25/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

private let numberFormatter: NSNumberFormatter = {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .DecimalStyle
    formatter.minimumFractionDigits = 3
    return formatter
}()

private let timestamp: String = {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
    return formatter.stringFromDate(NSDate())
}()

internal func saveBenchmark(name: String, times: [(id: String, time: Double)]) {
    let string = times
        .reduce([String: Double](), combine: { accu, idAndTime in
            var accu = accu
            accu[idAndTime.id] = (accu[idAndTime.id] ?? 0) + idAndTime.time
            return accu
        })
        .sort({ $0.1 < $1.1 })
        .map({ "\(numberFormatter.stringFromNumber($0.1)!): \($0.0)" })
        .joinWithSeparator("\n")
        + "\n"
    let data = string.dataUsingEncoding(NSUTF8StringEncoding)
    data?.writeToFile("benchmark_\(name)_\(timestamp).txt", atomically: true)
}
