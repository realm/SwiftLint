internal struct NSObjectPreferIsEqualRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        // NSObject subclass without ==
        Example("""
        class AClass: NSObject {
        }
        """),
        // @objc class without ==
        Example("""
        @objc class AClass: SomeNSObjectSubclass {
        }
        """),
        // Class with == which does not subclass NSObject
        Example("""
        class AClass: Equatable {
            static func ==(lhs: AClass, rhs: AClass) -> Bool {
                return true
            }
        """),
        // NSObject subclass implementing isEqual
        Example("""
        class AClass: NSObject {
            override func isEqual(_ object: Any?) -> Bool {
                return true
            }
        }
        """),
        // @objc class implementing isEqual
        Example("""
        @objc class AClass: SomeNSObjectSubclass {
            override func isEqual(_ object: Any?) -> Bool {
                return false
            }
        }
        """),
        // NSObject subclass implementing == with different signature
        Example("""
        class AClass: NSObject {
            static func ==(lhs: AClass, rhs: BClass) -> Bool {
                return true
            }
        }
        """),
        // Equatable struct
        Example("""
        struct AStruct: Equatable {
            static func ==(lhs: AStruct, rhs: AStruct) -> Bool {
                return false
            }
        }
        """),
        // Equatable enum
        Example("""
        enum AnEnum: Equatable {
            static func ==(lhs: AnEnum, rhs: AnEnum) -> Bool {
                return true
            }
        }
        """),
        // Nested class is not itself inheriting from NSObject
        Example("""
        class C: NSObject {
            class NestedClass {
                static func ==(lhs: NestedClass, rhs: NestedClass) -> Bool {
                    return false
                }
            }
        }
        """, excludeFromDocumentation: true),
        // Enum inside nested class inheriting from NSObject
        Example("""
        public final class A: NSObject {
            public enum B: Equatable {
                case c

                public func hash(into hasher: inout Hasher) {
                    filename.original.hash(into: &hasher)
                }

                public static func == (lhs: B, rhs: B) -> Bool {
                    return true
                }
            }
        }
        """, excludeFromDocumentation: true)
    ]

    static let triggeringExamples: [Example] = [
        // NSObject subclass implementing ==
        Example("""
        class AClass: NSObject {
            ↓static func ==(lhs: AClass, rhs: AClass) -> Bool {
                return false
            }
        }
        """),
        // @objc class implementing ==
        Example("""
        @objc class AClass: SomeOtherNSObjectSubclass {
            ↓static func ==(lhs: AClass, rhs: AClass) -> Bool {
                return true
            }
        }
        """),
        // Equatable NSObject subclass implementing ==
        Example("""
        class AClass: NSObject, Equatable {
            ↓static func ==(lhs: AClass, rhs: AClass) -> Bool {
                return false
            }
        }
        """),
        // NSObject subclass overriding isEqual and implementing ==
        Example("""
        class AClass: NSObject {
            override func isEqual(_ object: Any?) -> Bool {
                guard let other = object as? AClass else {
                    return false
                }
                return true
            }

            ↓static func ==(lhs: AClass, rhs: AClass) -> Bool {
                return false
            }
        }
        """),
        // Nested @objc class implementing ==
        Example("""
        class C {
            @objc class NestedClass {
                ↓static func ==(lhs: NestedClass, rhs: NestedClass) -> Bool {
                    return false
                }
            }
        }
        struct S {
            @objcMembers class NestedClass {
                ↓static func ==(lhs: NestedClass, rhs: NestedClass) -> Bool {
                    return false
                }
            }
        }
        enum E {
            struct S {
                @objc class NestedClass {
                    ↓static func ==(lhs: NestedClass, rhs: NestedClass) -> Bool {
                        return false
                    }
                }
            }
        }
        """, excludeFromDocumentation: true)
    ]
}
