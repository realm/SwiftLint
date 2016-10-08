//
//  Benchmark.swift
//  SwiftLint
//
//  Created by JP Simard on 1/25/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

private let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 3
    return formatter
}()

private let timestamp: String = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
    return formatter.string(from: Date())
}()

internal func saveBenchmark(_ name: String, times: [(id: String, time: Double)]) {
    let string = times
        .reduce([String: Double](), { accu, idAndTime in
            var accu = accu
            accu[idAndTime.id] = (accu[idAndTime.id] ?? 0) + idAndTime.time
            return accu
        })
        .sorted(by: { $0.1 < $1.1 })
        .map({ "\(numberFormatter.string(from: NSNumber(value:$0.1))!): \($0.0)" })
        .joined(separator: "\n")
    let data = (string + "\n").data(using: String.Encoding.utf8)
    try? data?.write(to: URL(fileURLWithPath: "benchmark_\(name)_\(timestamp).txt"), options: [.atomic])
}
