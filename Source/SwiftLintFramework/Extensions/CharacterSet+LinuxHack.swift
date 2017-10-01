//
//  CharacterSet+LinuxHack.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/25/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

extension CharacterSet {
    func isSuperset(ofCharactersIn string: String,
                    union other: CharacterSet = CharacterSet()) -> Bool {
#if swift(>=3.2)
        let set = union(other)
        return set.isSuperset(of: CharacterSet(charactersIn: string))
#else
        // workaround for https://bugs.swift.org/browse/SR-3485
        return !Set(string.characters).contains { character in
            let scalar = String(character).unicodeScalars.first!
            return !contains(scalar) && !other.contains(scalar)
        }
#endif
    }
}
