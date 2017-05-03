//
//  NotificationCenterDetachmentRuleExamples.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/15/17.
//  Copyright © 2017 Realm. All rights reserved.
//

internal struct NotificationCenterDetachmentRuleExamples {

    static let nonTriggeringExamples = [
        "class Foo { \n" +
        "   deinit {\n" +
        "       NotificationCenter.default.removeObserver(self)\n" +
        "   }\n" +
        "}\n",

        "class Foo { \n" +
        "   func bar() {\n" +
        "       NotificationCenter.default.removeObserver(otherObject)\n" +
        "   }\n" +
        "}\n"
    ]

    static let triggeringExamples = [
        "class Foo { \n" +
        "   func bar() {\n" +
        "       ↓NotificationCenter.default.removeObserver(self)\n" +
        "   }\n" +
        "}\n"
    ]
}
