//
//  ObjectLiteralConfiguration.swift
//  SwiftLint
//
//  Created by Cihat Gündüz on 06/03/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

public struct ObjectLiteralConfiguration: RuleConfiguration, Equatable {
    private(set) var imageLiteralParameter: Parameter<Bool>
    private(set) var colorLiteralParameter: Parameter<Bool>
    private(set) var severityParameter = SeverityConfiguration(.warning).severityParameter

    public var severity: ViolationSeverity {
        return severityParameter.value
    }

    public var imageLiteral: Bool {
        return imageLiteralParameter.value
    }

    public var colorLiteral: Bool {
        return colorLiteralParameter.value
    }

    public init(imageLiteral: Bool = true, colorLiteral: Bool = true) {
        imageLiteralParameter = Parameter(key: "image_literal",
                                          default: imageLiteral,
                                          description: "How serious")
        colorLiteralParameter = Parameter(key: "color_literal",
                                          default: colorLiteral,
                                          description: "How serious")
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try imageLiteralParameter.parse(from: configuration)
        try colorLiteralParameter.parse(from: configuration)
        try severityParameter.parse(from: configuration)
    }

    public static func == (lhs: ObjectLiteralConfiguration,
                           rhs: ObjectLiteralConfiguration) -> Bool {
        return lhs.severity == rhs.severity &&
            lhs.imageLiteral == rhs.imageLiteral &&
            lhs.colorLiteral == rhs.colorLiteral
    }
}
