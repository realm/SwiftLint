@preconcurrency import SourceKittenFramework

public extension SwiftDeclarationKind {
    static let functionKinds: Set<SwiftDeclarationKind> = [
        .functionAccessorAddress,
        .functionAccessorDidset,
        .functionAccessorGetter,
        .functionAccessorMutableaddress,
        .functionAccessorSetter,
        .functionAccessorWillset,
        .functionConstructor,
        .functionDestructor,
        .functionFree,
        .functionMethodClass,
        .functionMethodInstance,
        .functionMethodStatic,
        .functionOperator,
        .functionSubscript,
    ]

    static let typeKinds: Set<SwiftDeclarationKind> = [
        .class,
        .struct,
        .typealias,
        .associatedtype,
        .enum,
    ]
}
