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
    ///
    /// // Signed: consume an optional leading '+'/'-' (e.g. -128).
    /// let signed = ASCII.Decimal.Parser<Input, Int8>(sign: .optional)
    /// ```
    public struct Parser<Input: Collection.Slice.`Protocol`, T: FixedWidthInteger>: Sendable
    where Input: Sendable, Input.Element == Byte {
        /// The sign policy governing whether a leading sign byte is consumed.
        public let sign: ASCII.Digits.Sign
        /// The digit-count policy governing how many digit bytes are consumed.
        public let count: ASCII.Digits.Count

        /// Creates a decimal parser.
        ///
        /// - Parameters:
        ///   - sign: the sign policy. Defaults to ``ASCII/Digits/Sign/none``,
        ///     which consumes no leading sign byte — the historical behavior.
        ///   - count: the digit-count policy. Defaults to ``ASCII/Digits/Count/greedy``,
        ///     which consumes every available decimal digit byte — the historical behavior.
        @inlinable
        public init(sign: ASCII.Digits.Sign = .none, count: ASCII.Digits.Count = .greedy) {
            self.sign = sign
            self.count = count
        }
    }
}

extension ASCII.Decimal.Parser: Parser.`Protocol` {
    /// The value produced when parsing succeeds.
    public typealias Output = T
    /// The error thrown when parsing fails.
    public typealias Failure = ASCII.Decimal.Error

    /// Parses an integer value from `input`, consuming the digits it reads.
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

        // Sign handling runs BEFORE the digit loop and only under `.optional`.
        // `.none` peeks nothing — byte-for-byte the historical behavior. Under
        // `.optional` a leading `+` (0x2B) selects positive and a leading `-`
        // (0x2D) selects negative; either is consumed when present. Advancing
        // only the local `index` keeps the throw paths non-consuming (the input
        // is committed via the final slice solely on success).
        var negative = false
        if sign == .optional, index < input.endIndex {
            let byte = input[index]
            if byte == 0x2B {
                input.formIndex(after: &index)
            } else if byte == 0x2D {
                guard T.isSigned else { throw .invalidSign }
                negative = true
                input.formIndex(after: &index)
            }
        }

        while index < input.endIndex {
            if let limit, consumed == limit { break }
            let byte = input[index]
            guard byte >= 0x30, byte <= 0x39 else {
                break
            }
            let digit = T(byte.underlying &- 0x30)
            // Accumulate magnitude in the sign's direction so that `T.min` is
            // reachable. Parsing positive-then-negating would overflow on the
            // most-negative value (e.g. `Int8 "-128"`: 128 has no `Int8`).
            let (product, mulOverflow) = result.multipliedReportingOverflow(by: 10)
            guard !mulOverflow else { throw .overflow }
            let combined =
                negative
                ? product.subtractingReportingOverflow(digit)
                : product.addingReportingOverflow(digit)
            guard !combined.overflow else { throw .overflow }
            result = combined.partialValue
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
