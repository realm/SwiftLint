//
//  shim.swift
//  SwiftLint
//
//  Created by Norio Nomura on 2/5/18.
//  Copyright © 2018 Realm. All rights reserved.
//

#if (!swift(>=4.1) && swift(>=4.0)) || !swift(>=3.3)

    extension Sequence {
        func compactMap<ElementOfResult>(
            _ transform: (Self.Element
            ) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
            return try flatMap(transform)
        }
    }

#endif
