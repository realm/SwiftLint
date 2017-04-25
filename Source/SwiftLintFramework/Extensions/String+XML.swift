//
//  String+XML.swift
//  SwiftLint
//
//  Created by Fabian Ehrentraud on 12/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

extension String {
    func escapedForXML() -> String {
        // & needs to go first, otherwise other replacements will be replaced again
        let htmlEscapes = [
            ("&", "&amp;"),
            ("\"", "&quot;"),
            ("'", "&apos;"),
            (">", "&gt;"),
            ("<", "&lt;")
        ]
        var newString = self
        for (key, value) in htmlEscapes {
            newString = newString.replacingOccurrences(of: key, with: value)
        }
        return newString
    }
}
