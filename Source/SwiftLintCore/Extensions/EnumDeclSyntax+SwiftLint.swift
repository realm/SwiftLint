import SwiftSyntax

public extension EnumDeclSyntax {
    /// True if this enum supports raw values
    var supportsRawValues: Bool {
        guard let inheritedTypeCollection = inheritanceClause?.inheritedTypes else {
            return false
        }

        let rawValueTypes: Set<String> = [
            "Int", "Int8", "Int16", "Int32", "Int64",
            "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
            "Double", "Float", "Float80", "Decimal", "NSNumber",
            "NSDecimalNumber", "NSInteger", "String", "CGFloat",
        ]

        return inheritedTypeCollection.contains { element in
            guard let identifier = element.type.as(IdentifierTypeSyntax.self)?.name.text else {
                return false
            }

            return rawValueTypes.contains(identifier)
        }
    }

    /// True if this enum is a `CodingKey`. For that, it has to be named `CodingKeys` and must conform 
    /// to the `CodingKey` protocol. 
    var definesCodingKeys: Bool {
        guard let inheritedTypeCollection = inheritanceClause?.inheritedTypes,
              name.text == "CodingKeys" else {
            return false
        }

        return inheritedTypeCollection.contains { element in
            element.type.as(IdentifierTypeSyntax.self)?.name.text == "CodingKey"
        }
    }
}
