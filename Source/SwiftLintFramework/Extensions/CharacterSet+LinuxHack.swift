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
#if swift(>=4.0)
        return isSuperset(of: CharacterSet(charactersIn: string))
#else
        // workaround for https://bugs.swift.org/browse/SR-3485
        return !Set(string.characters).contains { character in
            !contains(String(character).unicodeScalars.first!)
        }
#endif
    }
}
