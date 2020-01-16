import SourceKittenFramework

struct NamespaceCollector {
    struct Element {
        let name: String
        let kind: SwiftDeclarationKind
        let offset: ByteCount
        let dictionary: SourceKittenDictionary

        init?(dictionary: SourceKittenDictionary, namespace: [String]) {
            guard let name = dictionary.name,
                let kind = dictionary.declarationKind,
                let offset = dictionary.offset else {
                    return nil
            }

            self.name = (namespace + [name]).joined(separator: ".")
            self.kind = kind
            self.offset = offset
            self.dictionary = dictionary
        }
    }

    private let dictionary: SourceKittenDictionary

    init(dictionary: SourceKittenDictionary) {
        self.dictionary = dictionary
    }

    func findAllElements(of types: Set<SwiftDeclarationKind>,
                         namespace: [String] = []) -> [Element] {
        return findAllElements(in: dictionary, of: types, namespace: namespace)
    }

    private func findAllElements(in dictionary: SourceKittenDictionary,
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
