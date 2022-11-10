import SwiftSyntax

extension SyntaxProtocol {
    func includesLine(_ line: Int, sourceLocationConverter: SourceLocationConverter) -> Bool {
        let start = self.startLocation(converter: sourceLocationConverter)
        let end = self.endLocation(converter: sourceLocationConverter)
        guard let startLine = start.line, let endLine = end.line else {
            return false
        }

        return (startLine...endLine).contains(line)
    }
}
