import SwiftSyntax

// TODO: Use result builders
func VisitorBuilder() -> VisitorBuilderImpl {
    VisitorBuilderImpl(viewMode: .sourceAccurate)
}

final class VisitorBuilderImpl: SyntaxVisitor {
    // FunctionCallExpr

    private var _onFunctionCallExpr: ((FunctionCallExprSyntax) -> Void)?
    @discardableResult
    func onFunctionCallExpr(_ block: @escaping (FunctionCallExprSyntax) -> Void) -> Self {
        _onFunctionCallExpr = block
        return self
    }
    override func visitPost(_ node: FunctionCallExprSyntax) {
        _onFunctionCallExpr?(node)
    }

    // ClassDecl

    private var _onClassDecl: ((ClassDeclSyntax) -> Void)?
    @discardableResult
    func onClassDecl(_ block: @escaping (ClassDeclSyntax) -> Void) -> Self {
        _onClassDecl = block
        return self
    }
    override func visitPost(_ node: ClassDeclSyntax) {
        _onClassDecl?(node)
    }

    // SwitchStmt

    private var _onSwitchStmt: ((SwitchStmtSyntax) -> Void)?
    @discardableResult
    func onSwitchStmt(_ block: @escaping (SwitchStmtSyntax) -> Void) -> Self {
        _onSwitchStmt = block
        return self
    }
    override func visitPost(_ node: SwitchStmtSyntax) {
        _onSwitchStmt?(node)
    }
}
