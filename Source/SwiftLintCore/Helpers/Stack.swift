/// A basic stack type implementing the LIFO principle - only the last inserted element can be accessed and removed.
public struct Stack<Element> {
    private var elements = [Element]()

    /// Creates an empty `Stack`.
    public init() {}

    /// True if the stack has no elements. False otherwise.
    public var isEmpty: Bool {
        elements.isEmpty
    }

    /// The number of elements in this stack.
    public var count: Int {
        elements.count
    }

    /// Pushes (appends) an element onto the stack.
    ///
    /// - parameter element: The element to push onto the stack.
    public mutating func push(_ element: Element) {
        elements.append(element)
    }

    /// Removes and returns the last element of the stack.
    ///
    /// - returns: The last element of the stack if the stack is not empty; otherwise, nil.
    @discardableResult
    public mutating func pop() -> Element? {
        elements.popLast()
    }

    /// Returns the last element of the stack if the stack is not empty; otherwise, nil.
    public func peek() -> Element? {
        elements.last
    }
}

extension Stack: CustomDebugStringConvertible where Element == CustomDebugStringConvertible {
    public var debugDescription: String {
        let intermediateElements = count > 1 ? elements[1 ..< count - 1] : []
        return """
            Stack with \(count) elements:
                first: \(elements.first?.debugDescription ?? "")
                intermediate: \(intermediateElements.map(\.debugDescription).joined(separator: ", "))
                last: \(peek()?.debugDescription ?? "")
            """
    }
}
