import Foundation
import SwiftParser
import SwiftSyntax

final class ForbiddenVariableVisitor: SyntaxVisitor {
    let locationConverter: SourceLocationConverter
    var locations = [SourceLocation]()

    init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
        if node.identifier.text == "forbidden" {
            locations.append(node.identifier.startLocation(converter: locationConverter))
        }
        return .skipChildren
    }
}

func runPlugin(file: String) -> [SwiftLintPluginStyleViolation] {
    let source = try! String(contentsOfFile: file)
    let sourceFile = Parser.parse(source: source)

    let locationConverter = SourceLocationConverter(fileName: file, tree: sourceFile)
    let visitor = ForbiddenVariableVisitor(locationConverter: locationConverter)
    visitor.walk(sourceFile)

    return visitor.locations.map { location in
        SwiftLintPluginStyleViolation(
            ruleIdentifier: "plugin_example",
            ruleDescription: "Identifiers cannot be named 'forbidden'",
            ruleName: "Plugin Example Rule",
            severity: .error,
            location: SwiftLintPluginLocation(location),
            reason: "Identifiers cannot be named 'forbidden'"
        )
    }
}
