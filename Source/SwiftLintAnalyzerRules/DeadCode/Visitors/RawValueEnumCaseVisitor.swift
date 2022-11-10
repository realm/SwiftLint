import SwiftSyntax

/// A SwiftSyntax visitor that detects if the case at the specified line number should be excluded
/// from being reported as dead code because it is backed by a raw value which can be constructed indirectly.
final class RawValueEnumCaseVisitor: SyntaxVisitor {
    private(set) var isRawValueEnumCase = false
    private let line: Int
    private let locationConverter: SourceLocationConverter

    init(line: Int, locationConverter: SourceLocationConverter) {
        self.line = line
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
        let enumSourceRange = node.sourceRange(converter: self.locationConverter)
        guard
            let startLine = enumSourceRange.start.line,
            let endLine = enumSourceRange.end.line,
            startLine <= self.line,
            endLine >= self.line
        else {
            return
        }

        let nestedEnumVisitor = EnumSourceRangeVisitor(locationConverter: self.locationConverter)
        let nestedEnumRanges = nestedEnumVisitor
            .walk(tree: node.memberBlock, handler: \.enumRanges)

        let nestedEnumContainsLine = nestedEnumRanges.contains { range in
            guard
                let startLine = range.start.line,
                let endLine = range.end.line,
                startLine <= self.line,
                endLine >= self.line
            else {
                return false
            }

            return true
        }

        guard !nestedEnumContainsLine, node.inheritanceClause?.supportsRawValue == true else {
            return
        }

        self.isRawValueEnumCase = true
    }
}

// MARK: - Private

private final class EnumSourceRangeVisitor: SyntaxVisitor {
    var enumRanges = [SourceRange]()
    private let locationConverter: SourceLocationConverter

    init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
        self.enumRanges.append(
            node.sourceRange(converter: self.locationConverter)
        )
    }
}

private extension TypeInheritanceClauseSyntax {
    var supportsRawValue: Bool {
        // Check if it's an enum which supports raw values
        let implicitRawValueSet: Set<String> = [
            "Int", "Int8", "Int16", "Int32", "Int64",
            "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
            "Double", "Float", "Float80", "Decimal", "NSNumber",
            "NSDecimalNumber", "NSInteger", "String", "CGFloat"
        ]

        return self.inheritedTypeCollection.contains { element in
            guard let identifier = element.typeName.as(SimpleTypeIdentifierSyntax.self)?.name.text else {
                return false
            }

            return implicitRawValueSet.contains(identifier)
        }
    }
}
