/// A basic stack type implementing the LIFO principle - only the last inserted element can be accessed and removed.
public struct Stack<Element> {
    private var elements = [Element]()

    /// Creates an empty `Stack`.
    public init() { /* Publish no-op initializer */ }

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

    /// Check whether the sequence contains an element that satisfies the given predicate.
    ///
    /// - parameter predicate: A closure that takes an element of the sequence
    ///   and returns whether it represents a match.
    /// - returns: `true` if the sequence contains an element that satisfies `predicate`.
    public func contains(where predicate: (Element) -> Bool) -> Bool {
        elements.contains(where: predicate)
    }

    /// Modify the last element.
    ///
    /// - parameter modifier: A function to be applied to the last element to modify the same in place.
    public mutating func modifyLast(by modifier: (inout Element) -> Void) {
        if elements.isNotEmpty {
            modifier(&elements[count - 1])
        }
    }
}

extension Stack: Sequence {
    public func makeIterator() -> [Element].Iterator {
        elements.makeIterator()
    }
}

extension Stack: CustomDebugStringConvertible where Element: CustomDebugStringConvertible {
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
