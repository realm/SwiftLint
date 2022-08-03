// swiftlint:disable all
// Copied from https://github.com/apple/swift-algorithms/blob/main/Sources/Algorithms/Windows.swift

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Algorithms open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// windows(ofCount:)
//===----------------------------------------------------------------------===//

extension Collection {
  /// Returns a collection of all the overlapping slices of a given size.
  ///
  /// Use this method to iterate over overlapping subsequences of this
  /// collection. This example prints every five character substring of `str`:
  ///
  ///     let str = "Hello, world!"
  ///     for substring in str.windows(ofCount: 5) {
  ///         print(substring)
  ///     }
  ///     // "Hello"
  ///     // "ello,"
  ///     // "llo, "
  ///     // "lo, W"
  ///     // ...
  ///     // "orld!"
  ///
  /// - Parameter count: The number of elements in each window subsequence.
  /// - Returns: A collection of subsequences of this collection, each with
  ///   length `count`. If this collection is shorter than `count`, the
  ///   resulting collection is empty.
  ///
  /// - Complexity: O(1) if the collection conforms to
  ///   `RandomAccessCollection`, otherwise O(*k*) where `k` is `count`.
  ///   Access to successive windows is O(1).
  func windows(ofCount count: Int) -> WindowsOfCountCollection<Self> {
    WindowsOfCountCollection(base: self, windowSize: count)
  }
}

/// A collection wrapper that presents a sliding window over the elements of
/// a collection.
struct WindowsOfCountCollection<Base: Collection> {
  internal let base: Base
  internal let windowSize: Int
  internal var endOfFirstWindow: Base.Index?

  internal init(base: Base, windowSize: Int) {
    precondition(windowSize > 0, "Windows size must be greater than zero")
    self.base = base
    self.windowSize = windowSize
    self.endOfFirstWindow =
      base.index(base.startIndex, offsetBy: windowSize, limitedBy: base.endIndex)
  }
}

extension WindowsOfCountCollection: Collection {
  /// A position in a `WindowsOfCountCollection` instance.
  struct Index: Comparable {
    internal var lowerBound: Base.Index
    internal var upperBound: Base.Index

    internal init(lowerBound: Base.Index, upperBound: Base.Index) {
      self.lowerBound = lowerBound
      self.upperBound = upperBound
    }

    static func == (lhs: Index, rhs: Index) -> Bool {
      lhs.lowerBound == rhs.lowerBound
    }

    static func < (lhs: Index, rhs: Index) -> Bool {
      lhs.lowerBound < rhs.lowerBound
    }
  }

  var startIndex: Index {
    if let upperBound = endOfFirstWindow {
      return Index(lowerBound: base.startIndex, upperBound: upperBound)
    } else {
      return endIndex
    }
  }

  var endIndex: Index {
    Index(lowerBound: base.endIndex, upperBound: base.endIndex)
  }

  subscript(index: Index) -> Base.SubSequence {
    precondition(
      index.lowerBound != index.upperBound,
      "Windows index is out of range")
    return base[index.lowerBound..<index.upperBound]
  }

  func index(after index: Index) -> Index {
    precondition(index != endIndex, "Advancing past end index")
    guard index.upperBound < base.endIndex else { return endIndex }

    let lowerBound = windowSize == 1
      ? index.upperBound
      : base.index(after: index.lowerBound)
    let upperBound = base.index(after: index.upperBound)
    return Index(lowerBound: lowerBound, upperBound: upperBound)
  }

  func index(_ i: Index, offsetBy distance: Int) -> Index {
    guard distance != 0 else { return i }

    return distance > 0
      ? offsetForward(i, by: distance)
      : offsetBackward(i, by: -distance)
  }

  func index(
    _ i: Index,
    offsetBy distance: Int,
    limitedBy limit: Index
  ) -> Index? {
    guard distance != 0 else { return i }
    guard limit != i else { return nil }

    if distance > 0 {
      return limit > i
        ? offsetForward(i, by: distance, limitedBy: limit)
        : offsetForward(i, by: distance)
    } else {
      return limit < i
        ? offsetBackward(i, by: -distance, limitedBy: limit)
        : offsetBackward(i, by: -distance)
    }
  }

  internal func offsetForward(_ i: Index, by distance: Int) -> Index {
    guard let index = offsetForward(i, by: distance, limitedBy: endIndex)
      else { fatalError("Index is out of bounds") }
    return index
  }

  internal func offsetBackward(_ i: Index, by distance: Int) -> Index {
    guard let index = offsetBackward(i, by: distance, limitedBy: startIndex)
      else { fatalError("Index is out of bounds") }
    return index
  }

  internal func offsetForward(
    _ i: Index, by distance: Int, limitedBy limit: Index
  ) -> Index? {
    assert(distance > 0)
    assert(limit > i)

    // `endIndex` and the index before it both have `base.endIndex` as their
    // upper bound, so we first advance to the base index _before_ the upper
    // bound of the output, in order to avoid advancing past the end of `base`
    // when advancing to `endIndex`.
    //
    // Advancing by 4:
    //
    //  input: [x|x x x x x|x x x x]        [x x|x x x x x|x x x]
    //                     |> > >|>|   or                 |> > >|
    // output: [x x x x x|x x x x x]        [x x x x x x x x x x]  (`endIndex`)

    if distance >= windowSize {
      // Avoid traversing `self[i.lowerBound..<i.upperBound]` when the lower
      // bound of the output is greater than or equal to the upper bound of the
      // input.

      //  input: [x|x x x x|x x x x x x x]
      //                   |> >|> > >|>|
      // output: [x x x x x x x|x x x x|x]

      guard limit.lowerBound >= i.upperBound,
            let lowerBound = base.index(
              i.upperBound,
              offsetBy: distance - windowSize,
              limitedBy: limit.lowerBound),
            let indexBeforeUpperBound = base.index(
              lowerBound,
              offsetBy: windowSize - 1,
              limitedBy: limit.upperBound)
      else { return nil }

      // If `indexBeforeUpperBound` equals `base.endIndex`, we're advancing to
      // `endIndex`.
      guard indexBeforeUpperBound != base.endIndex else { return endIndex }

      return Index(
        lowerBound: lowerBound,
        upperBound: base.index(after: indexBeforeUpperBound))
    } else {
      //  input: [x|x x x x x x|x x x x x]
      //           |> > > >|   |> > >|>|
      // output: [x x x x x|x x x x x x|x]

      guard let indexBeforeUpperBound = base.index(
              i.upperBound,
              offsetBy: distance - 1,
              limitedBy: limit.upperBound)
      else { return nil }

      // If `indexBeforeUpperBound` equals the limit, the upper bound itself
      // exceeds it.
      guard indexBeforeUpperBound != limit.upperBound || limit == endIndex
        else { return nil }

      // If `indexBeforeUpperBound` equals `base.endIndex`, we're advancing to
      // `endIndex`.
      guard indexBeforeUpperBound != base.endIndex else { return endIndex }

      return Index(
        lowerBound: base.index(i.lowerBound, offsetBy: distance),
        upperBound: base.index(after: indexBeforeUpperBound))
    }
  }

  internal func offsetBackward(
      _ i: Index, by distance: Int, limitedBy limit: Index
    ) -> Index? {
    assert(distance > 0)
    assert(limit < i)

    if i == endIndex {
      // Advance `base.endIndex` by `distance - 1`, because the index before
      // `endIndex` also has `base.endIndex` as its upper bound.
      //
      // Advancing by 4:
      //
      //  input: [x x x x x x x x x x]  (`endIndex`)
      //             |< < < < <|< < <|
      // output: [x x|x x x x x|x x x]

      guard let upperBound = base.index(
              base.endIndex,
              offsetBy: -(distance - 1),
              limitedBy: limit.upperBound)
      else { return nil }

      return Index(
        lowerBound: base.index(upperBound, offsetBy: -windowSize),
        upperBound: upperBound)
    } else if distance >= windowSize {
      // Avoid traversing `self[i.lowerBound..<i.upperBound]` when the upper
      // bound of the output is less than or equal to the lower bound of the
      // input.
      //
      //  input: [x x x x x x x|x x x x|x]
      //           |< < < <|< <|
      // output: [x|x x x x|x x x x x x x]

      guard limit.upperBound <= i.lowerBound,
            let upperBound = base.index(
              i.lowerBound,
              offsetBy: -(distance - windowSize),
              limitedBy: limit.upperBound)
      else { return nil }

      return Index(
        lowerBound: base.index(upperBound, offsetBy: -windowSize),
        upperBound: upperBound)
    } else {
      //  input: [x x x x x|x x x x x x|x]
      //           |< < < <|   |< < < <|
      // output: [x|x x x x x x|x x x x x]

      guard let lowerBound = base.index(
              i.lowerBound,
              offsetBy: -distance,
              limitedBy: limit.lowerBound)
      else { return nil }

      return Index(
        lowerBound: lowerBound,
        upperBound: base.index(i.lowerBound, offsetBy: -distance))
    }
  }

  func distance(from start: Index, to end: Index) -> Int {
    guard start <= end else { return -distance(from: end, to: start) }
    guard start != end else { return 0 }
    guard end != endIndex else {
      // We add 1 here because the index before `endIndex` also has
      // `base.endIndex` as its upper bound.
      return base[start.upperBound...].count + 1
    }

    if start.upperBound <= end.lowerBound {
      // The distance between `start.lowerBound` and `start.upperBound` is
      // already known.
      //
      // start: [x|x x x x|x x x x x x x]
      //          |- - - -|> >|
      //   end: [x x x x x x x|x x x x|x]

      return windowSize + base[start.upperBound..<end.lowerBound].count
    } else {
      // start: [x|x x x x x x|x x x x x]
      //          |> > > >|
      //   end: [x x x x x|x x x x x x|x]

      return base[start.lowerBound..<end.lowerBound].count
    }
  }
}

extension WindowsOfCountCollection: BidirectionalCollection
  where Base: BidirectionalCollection
{
  func index(before index: Index) -> Index {
    precondition(index != startIndex, "Incrementing past start index")
    if index == endIndex {
      return Index(
        lowerBound: base.index(index.lowerBound, offsetBy: -windowSize),
        upperBound: index.upperBound
      )
    } else {
      return Index(
        lowerBound: base.index(before: index.lowerBound),
        upperBound: base.index(before: index.upperBound)
      )
    }
  }
}

extension WindowsOfCountCollection: RandomAccessCollection
  where Base: RandomAccessCollection {}

extension WindowsOfCountCollection: LazySequenceProtocol, LazyCollectionProtocol
  where Base: LazySequenceProtocol {}

extension WindowsOfCountCollection.Index: Hashable where Base.Index: Hashable {}
