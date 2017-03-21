//
//  OutletSetterRule.swift
//  SwiftLint
//
//  Created by Jeffrey Bergier on 3/9/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct OutletSetterRule: ASTRule, OptInRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    // swiftlint:disable line_length
    public static let description = RuleDescription(
        identifier: "outlet_setter",
        name: "Outlet Setter",
        description: "@IBOutlet properties should only be set by Interface Builder, not in code.",
        nonTriggeringExamples: [
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t let \t bar \t  = UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t let \t bar=UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t var \t bar \t  = UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t var \t bar=UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t if case \t .bar \t = bar {} \n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t if case \t .bar=bar {} \n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t 123bar \t  = UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t 123bar=UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t XYZbar \t  = UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t XYZbar=UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t XYZ123bar \t  = UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t XYZ123bar=UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t self.bar?.backgroundColor = .blue\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t self.bar?.backgroundColor=.blue\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t self!.bar?.backgroundColor = .blue\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t self!.bar?.backgroundColor=.blue\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t self?.bar?.backgroundColor = .blue\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t self?.bar?.backgroundColor=.blue\n }\n }",
            "class Foo {\n var bar: UIView?\n func fubar() {\n \t self.bar \t = UILabel()\n }\n }",
            "class Foo {\n var bar: UIView?\n func fubar() {\n \t self.bar=UILabel()\n }\n }",
            "class Foo {\n var bar: UIView?\n func fubar() {\n \t self!.bar \t = UILabel()\n }\n }",
            "class Foo {\n var bar: UIView?\n func fubar() {\n \t self!.bar=UILabel()\n }\n }",
            "class Foo {\n var bar: UIView?\n func fubar() {\n \t self?.bar \t = UILabel()\n }\n }",
            "class Foo {\n var bar: UIView?\n func fubar() {\n \t self?.bar=UILabel()\n }\n }",
            "class Foo {\n var bar: UIView?\n func fubar() {\n \t bar \t = UILabel()\n }\n }",
            "class Foo {\n var bar: UIView?\n func fubar() {\n \t bar=UILabel()\n }\n }"
            // MARK: ToDo: This string literal causes warning
            // "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n print(\"my bar = \\(bar?.description)\")\n }\n }",
            // MARK: ToDo: This valid multiline local variable will cause warning
            // "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t var \t bar: UIView?\n bar \t = UILabel()\n }\n }",
        ],
        triggeringExamples: [
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t self.bar \t  = UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t self.bar=UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t self!.bar \t = UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t self!.bar=UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t self?.bar \t = UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t self?.bar=UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t bar \t = UILabel()\n }\n }",
            "class Foo {\n @IBOutlet var bar: UIView?\n func fubar() {\n \t bar=UILabel()\n }\n }"
            // MARK: ToDo: Fix Bug. This is very uncommon, but it should be warned against. Currently is not matched.
            // "class Foo {\n @IBOutlet var invalidLabel = UILabel()\n }",
        ]
    )
    // swiftlint:enable line_length

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        // Find IBOutlets in the File
        let substructure = dictionary.substructure
        let outlets = substructure.filter({ $0.enclosedSwiftAttributes.contains("source.decl.attribute.iboutlet") })
        let outletNames = outlets.flatMap({ $0.name })

        // If there are no IBOutlets, we can bail
        guard outletNames.isEmpty == false else { return [] }

        // Find any line that contains a string that matches the discovered outlet names
        // This will have many false positives
        let possibleViolations: [(String, Line)] = outletNames.flatMap { outletName -> [(String, Line)] in
            return file.lines.filter({ $0.content.contains(outletName) }).map({ (outletName, $0) })
        }

        // Go through possible violations, use regex to see if they violate rules
        let confirmedViolations = possibleViolations.filter { outletName, line -> Bool in

            // build the regex pattern
            let noSelfPattern = "^\\s*\(outletName)\\s*="
            let selfPattern = "self[\\?\\!]?\\.\(outletName)\\s*="
            let noDotPattern = "[\\W*][\\D*][^\\.]\\s+\(outletName)\\s*="
            let pattern = "(\(noSelfPattern)|\(selfPattern)|\(noDotPattern))"

            // get the text that is being scanned
            let content = line.content
            let range = content.bridge().range(of: content)

            // init new regex object and start operation
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let match = regex?.firstMatch(in: content, options: [], range: range)

            // if we have a match, then there is a violation
            return match != nil
        }

        // Convert the Lines into errors
        let errors = confirmedViolations.map { _, line -> StyleViolation in
            let location = Location(file: file, byteOffset: line.range.location)
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: self.configuration.severity,
                                  location: location)
        }

        return errors
    }
}
