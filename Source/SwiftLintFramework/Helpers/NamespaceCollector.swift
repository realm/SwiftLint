//
//  NamespaceCollector.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 10/07/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

struct NamespaceCollector {
    struct Element {
        let name: String
        let kind: SwiftDeclarationKind
        let offset: Int
        let dictionary: [String: SourceKitRepresentable]

        init?(dictionary: [String: SourceKitRepresentable], namespace: [String]) {
            guard let name = dictionary.name,
                let kind = dictionary.kind.flatMap(SwiftDeclarationKind.init),
                let offset = dictionary.offset else {
                    return nil
            }

            self.name = (namespace + [name]).joined(separator: ".")
            self.kind = kind
            self.offset = offset
            self.dictionary = dictionary
        }
    }

    private let dictionary: [String: SourceKitRepresentable]

    init(dictionary: [String: SourceKitRepresentable]) {
        self.dictionary = dictionary
    }

    func findAllElements(of types: Set<SwiftDeclarationKind>,
                         namespace: [String] = []) -> [Element] {
        return findAllElements(in: dictionary, of: types, namespace: namespace)
    }

    private func findAllElements(in dictionary: [String: SourceKitRepresentable],
                                 of types: Set<SwiftDeclarationKind>,
                                 namespace: [String] = []) -> [Element] {

        return dictionary.substructure.flatMap { subDict -> [Element] in

            var elements: [Element] = []
            guard let element = Element(dictionary: subDict, namespace: namespace) else {
                return elements
            }

            if types.contains(element.kind) {
                elements.append(element)
            }

            elements += findAllElements(in: subDict, of: types, namespace: [element.name])

            return elements
        }
    }
}
