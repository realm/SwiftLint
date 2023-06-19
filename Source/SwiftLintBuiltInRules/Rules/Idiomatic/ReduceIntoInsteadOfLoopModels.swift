import SwiftSyntax

typealias ReduceIntoInsteadOfLoopModels = ReduceIntoInsteadOfLoop

internal extension ReduceIntoInsteadOfLoop {
    struct ReferencedVariable: Hashable {
        let name: String
        let position: AbsolutePosition
        let kind: Kind

        func hash(into hasher: inout Hasher) {
            hasher.combine(self.name)
            hasher.combine(self.position.utf8Offset)
            hasher.combine(self.kind)
        }
    }

    enum Kind: Hashable {
        case method(name: String, arguments: Int)
        case assignment(subscript: Bool)

        func hash(into hasher: inout Hasher) {
            switch self {
            case let .method(name, arguments):
                hasher.combine("method")
                hasher.combine(name)
                hasher.combine(arguments)
            case let .assignment(`subscript`):
                hasher.combine("assignment")
                hasher.combine(`subscript`)
            }
        }
    }

    struct CollectionType: Hashable {
        let name: String
        let genericArguments: Int

        static let types: [CollectionType] = [
            .set,
            .array,
            .dictionary
        ]

        static let array = CollectionType(name: "Array", genericArguments: 1)
        static let set = CollectionType(name: "Set", genericArguments: 1)
        static let dictionary = CollectionType(name: "Dictionary", genericArguments: 2)

        static let names: [String: CollectionType] = {
            return CollectionType.types.reduce(into: [String: CollectionType]()) { partialResult, collectionType in
                partialResult[collectionType.name] = collectionType
            }
        }()
    }
}
