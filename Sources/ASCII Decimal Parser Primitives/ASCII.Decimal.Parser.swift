//
//  ASCII.Decimal.Parser.swift
//  swift-ascii-parser-primitives
//
//  Parses a decimal integer from ASCII bytes.
//

public import Byte_Primitives
public import Collection_Primitives

extension ASCII.Decimal {
    /// A parser that consumes one or more ASCII decimal digit bytes (0x30–0x39)
    /// and accumulates them into a `FixedWidthInteger`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let port = ASCII.Decimal.Parser<Input, UInt16>()
    /// let value = try port.parse(&input) // e.g. 8080
    ///
    /// // Fixed-width: consume exactly four digits (e.g. an ISO 8601 year).
    /// let year = ASCII.Decimal.Parser<Input, Int>(count: .exactly(4))
    /// ```
    public struct Parser<Input: Collection.Slice.`Protocol`, T: FixedWidthInteger>: Sendable
    where Input: Sendable, Input.Element == Byte {
        /// The digit-count policy governing how many digit bytes are consumed.
        public let count: ASCII.Digits.Count

        /// Creates a decimal parser.
        ///
        /// - Parameter count: the digit-count policy. Defaults to ``ASCII/Digits/Count/greedy``,
        ///   which consumes every available decimal digit byte — the historical behavior.
        @inlinable
        public init(count: ASCII.Digits.Count = .greedy) {
            self.count = count
        }
    }
}

extension ASCII.Decimal.Parser: Parser.`Protocol` {
    public typealias Output = T
    public typealias Failure = ASCII.Decimal.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> T {
        // Resolve the consumption bound from the policy.
        // `.greedy` is unbounded; `.exactly(n)`/`.atMost(n)` cap at `n`.
        let limit: Int?
        switch count {
        case .greedy: limit = nil
        case .exactly(let n): limit = n
        case .atMost(let n): limit = n
        }
        // Degenerate fixed-count policy: zero digits can never satisfy `.exactly`.
        if case .exactly(let n) = count, n == 0 { throw .insufficientDigits }

        var result: T = 0
        var consumed = 0
        var index = input.startIndex

        while index < input.endIndex {
            if let limit, consumed == limit { break }
            let byte = input[index]
            guard byte >= 0x30, byte <= 0x39 else {
                break
            }
            let digit = T(byte.underlying &- 0x30)
            let (product, mulOverflow) = result.multipliedReportingOverflow(by: 10)
            guard !mulOverflow else { throw .overflow }
            let (sum, addOverflow) = product.addingReportingOverflow(digit)
            guard !addOverflow else { throw .overflow }
            result = sum
            input.formIndex(after: &index)
            consumed += 1
        }

        switch count {
        case .exactly(let n):
            guard consumed == n else { throw .insufficientDigits }
        case .greedy, .atMost:
            guard consumed > 0 else { throw .noDigits }
        }

        input = input[index...]
        return result
    }
}
