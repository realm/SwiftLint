//
//  CharacterSet+LinuxHack.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/25/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

extension CharacterSet {
    func isSuperset(ofCharactersIn string: String) -> Bool {
        #if os(Linux)
            // workaround for https://bugs.swift.org/browse/SR-3485
            let chars = Set(string.characters)
            for char in chars where !contains(char.unicodeScalar) {
                return false
            }

            return true
        #else
            let otherSet = CharacterSet(charactersIn: string)
            return isSuperset(of: otherSet)
        #endif
    }
}

extension Character {
    fileprivate var unicodeScalar: UnicodeScalar {
        let characterString = String(self)
        let scalars = characterString.unicodeScalars

        return scalars[scalars.startIndex]
    }
}
