import SwiftSyntax

struct ReduceIntoInsteadOfLoopRuleModels {}

internal extension ReduceIntoInsteadOfLoopRule {
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

        static let types: [Self] = [
            .set,
            .array,
            .dictionary,
        ]

        static let array = Self(name: "Array", genericArguments: 1)
        static let set = Self(name: "Set", genericArguments: 1)
        static let dictionary = Self(name: "Dictionary", genericArguments: 2)

        static let names: [String: Self] = {
            Self.types.reduce(into: [String: Self]()) { partialResult, collectionType in
                partialResult[collectionType.name] = collectionType
            }
        }()
    }
}
