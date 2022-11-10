import SwiftSyntax

/// Visits the source syntax tree to collect attributes at a given line.
final class AttributeVisitor: SyntaxVisitor {
    private(set) var attributes = [String]()
    private let line: Int
    private let locationConverter: SourceLocationConverter

    init(line: Int, locationConverter: SourceLocationConverter) {
        self.line = line
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: AttributeSyntax) {
        if nodeIncludesLine(node.parent?.parent) {
            attributes.append(node.attributeName.text)
        }
    }

    private func nodeIncludesLine(_ node: SyntaxProtocol?) -> Bool {
        guard
            let node = node,
            let startLine = node.startLocation(converter: locationConverter).line,
            let endLine = node.endLocation(converter: locationConverter).line
        else {
            return false
        }

        return (startLine...endLine).contains(line)
    }
}
