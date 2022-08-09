/// ObjectTypes are types that can conform to protocols or inherit from a parent class.
public enum ObjectType: String, CaseIterable {
    /// Represents Swift Classes
    case `class`

    /// Represents Swift Enums
    case `enum`

    /// Represents Swift Structs
    case `struct`
}
