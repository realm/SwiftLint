import SourceKittenFramework

public extension SwiftDeclarationAttributeKind {
    static var attributesRequiringFoundation: Set<SwiftDeclarationAttributeKind> {
        [
            .objc,
            .objcName,
            .objcMembers,
            .objcNonLazyRealization,
        ]
    }

    enum ModifierGroup: String, CustomDebugStringConvertible, Sendable {
        case `override`
        case acl
        case setterACL
        case owned
        case mutators
        case final
        case typeMethods
        case `required`
        case `convenience`
        case `lazy`
        case `dynamic`
        case atPrefixed

        public init?(rawAttribute: String) {
            let allModifierGroups: Set<SwiftDeclarationAttributeKind.ModifierGroup> = [
                .acl, .setterACL, .mutators, .override, .owned, .atPrefixed, .dynamic, .final, .typeMethods,
                .required, .convenience, .lazy,
            ]
            let modifierGroup = allModifierGroups.first {
                $0.swiftDeclarationAttributeKinds.contains(where: { $0.rawValue == rawAttribute })
            }

            if let modifierGroup {
                self = modifierGroup
            } else {
                return nil
            }
        }

        public var swiftDeclarationAttributeKinds: Set<SwiftDeclarationAttributeKind> {
            switch self {
            case .acl:
                [
                    .private,
                    .fileprivate,
                    .internal,
                    .public,
                    .open,
                ]
            case .setterACL:
                [
                    .setterPrivate,
                    .setterFilePrivate,
                    .setterInternal,
                    .setterPublic,
                    .setterOpen,
                ]
            case .mutators:
                [
                    .mutating,
                    .nonmutating,
                ]
            case .override:
                [.override]
            case .owned:
                [.weak]
            case .final:
                [.final]
            case .typeMethods:
                []
            case .required:
                [.required]
            case .convenience:
                [.convenience]
            case .lazy:
                [.lazy]
            case .dynamic:
                [.dynamic]
            case .atPrefixed:
                [
                    .objc,
                    .nonobjc,
                    .objcMembers,
                    .ibaction,
                    .ibsegueaction,
                    .iboutlet,
                    .ibdesignable,
                    .ibinspectable,
                    .nsManaged,
                    .nsCopying,
                ]
            }
        }

        public var debugDescription: String {
            self.rawValue
        }
    }
}
