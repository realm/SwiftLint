//
//  MultilineArgumentsRuleExamples.swift
//  SwiftLint
//
//  Created by Marcel Jackwerth on 09/29/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

internal struct MultilineArgumentsRuleExamples {
    static let nonTriggeringExamples = [
        "foo()",
        "foo(\n" +
        "    \n" +
        ")",
        "foo { }",
        "foo {\n" +
        "    \n" +
        "}",
        "foo(0)",
        "foo(0, 1)",
        "foo(0, 1) { }",
        "foo(0, param1: 1)",
        "foo(0, param1: 1) { }",
        "foo(param1: 1)",
        "foo(param1: 1) { }",
        "foo(param1: 1, param2: true) { }",
        "foo(param1: 1, param2: true, param3: [3]) { }",
        "foo(param1: 1, param2: true, param3: [3]) {\n" +
        "    bar()\n" +
        "}",
        "foo(param1: 1,\n" +
        "    param2: true,\n" +
        "    param3: [3])",
        "foo(\n" +
        "    param1: 1, param2: true, param3: [3]\n" +
        ")",
        "foo(\n" +
        "    param1: 1,\n" +
        "    param2: true,\n" +
        "    param3: [3]\n" +
        ")"
    ]

    static let triggeringExamples = [
        "foo(0,\n" +
        "    param1: 1, ↓param2: true, ↓param3: [3])",
        "foo(0, ↓param1: 1,\n" +
        "    param2: true, ↓param3: [3])",
        "foo(0, ↓param1: 1, ↓param2: true,\n" +
        "    param3: [3])",
        "foo(\n" +
        "    0, ↓param1: 1,\n" +
        "    param2: true, ↓param3: [3]\n" +
        ")"
    ]
}
