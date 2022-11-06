import SourceKittenFramework

public extension SwiftDeclarationKind {
    static let variableKinds: Set<SwiftDeclarationKind> = [
        .varClass,
        .varGlobal,
        .varInstance,
        .varLocal,
        .varParameter,
        .varStatic
    ]

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
        .functionSubscript
    ]

    static let typeKinds: Set<SwiftDeclarationKind> = [
        .class,
        .struct,
        .typealias,
        .associatedtype,
        .enum
    ]

    static let extensionKinds: Set<SwiftDeclarationKind> = [
        .extension,
        .extensionClass,
        .extensionEnum,
        .extensionProtocol,
        .extensionStruct
    ]
}
