//
//  RuleParameter.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

struct RuleParameter<T> {
    let severity: ViolationSeverity
    let value: T
}
