//
//  Benchmark.swift
//  SwiftLint
//
//  Created by JP Simard on 1/25/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

struct BenchmarkEntry {
    let id: String // swiftlint:disable:this variable_name
    let time: Double
}

struct Benchmark {
    private let name: String
    private var entries = [BenchmarkEntry]()

    init(name: String) {
        self.name = name
    }

    // swiftlint:disable:next variable_name
    mutating func record(id: String, time: Double) {
        entries.append(BenchmarkEntry(id: id, time: time))
    }

    mutating func record(file: File, from start: Date) {
        record(id: file.path ?? "<nopath>", time: -start.timeIntervalSinceNow)
    }

    func save() {
        let string = entries
            .reduce([String: Double]()) { accu, idAndTime in
                var accu = accu
                accu[idAndTime.id] = (accu[idAndTime.id] ?? 0) + idAndTime.time
                return accu
            }
            .sorted { $0.1 < $1.1 }
            .map { "\(numberFormatter.string(from: NSNumber(value: $0.1))!): \($0.0)" }
            .joined(separator: "\n")
        let data = (string + "\n").data(using: .utf8)
        let url = URL(fileURLWithPath: "benchmark_\(name)_\(timestamp).txt")
        try? data?.write(to: url, options: [.atomic])
    }
}

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
