//
//  ASCII.Octal.Parser.swift
//  swift-ascii-parser-primitives
//
//  Parses an octal (base-8) integer from ASCII bytes.
//

public import Byte_Primitives
public import Collection_Primitives

extension ASCII.Octal {
    /// A parser that consumes one or more ASCII octal digit bytes (0x30–0x37)
    /// and accumulates them into a `FixedWidthInteger`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let oct = ASCII.Octal.Parser<Input, UInt16>()
    /// let value = try oct.parse(&input) // e.g. 0o17 == 15
    ///
    /// // Fixed-width: consume exactly three octal digits (e.g. a Unix mode).
    /// let mode = ASCII.Octal.Parser<Input, UInt16>(count: .exactly(3))
    ///
    /// // Signed: consume an optional leading '+'/'-' (e.g. -0o17).
    /// let signed = ASCII.Octal.Parser<Input, Int16>(sign: .optional)
    /// ```
    public struct Parser<Input: Collection.Slice.`Protocol`, T: FixedWidthInteger>: Sendable
    where Input: Sendable, Input.Element == Byte {
        /// The sign policy governing whether a leading sign byte is consumed.
        public let sign: ASCII.Digits.Sign
        /// The digit-count policy governing how many digit bytes are consumed.
        public let count: ASCII.Digits.Count

        /// Creates an octal parser.
        ///
        /// - Parameters:
        ///   - sign: the sign policy. Defaults to ``ASCII/Digits/Sign/none``,
        ///     which consumes no leading sign byte — the historical behavior.
        ///   - count: the digit-count policy. Defaults to ``ASCII/Digits/Count/greedy``,
        ///     which consumes every available octal digit byte — the historical behavior.
        @inlinable
        public init(sign: ASCII.Digits.Sign = .none, count: ASCII.Digits.Count = .greedy) {
            self.sign = sign
            self.count = count
        }
    }
}

extension ASCII.Octal.Parser: Parser.`Protocol` {
    /// The value produced when parsing succeeds.
    public typealias Output = T
    /// The error thrown when parsing fails.
    public typealias Failure = ASCII.Octal.Error

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
            guard byte >= 0x30, byte <= 0x37 else {
                break
            }
            let digit = T(byte.underlying &- 0x30)
            // Accumulate magnitude in the sign's direction so that `T.min` is
            // reachable. Parsing positive-then-negating would overflow on the
            // most-negative value (e.g. `Int8 "-200"`: 128 has no `Int8`).
            let (product, mulOverflow) = result.multipliedReportingOverflow(by: 8)
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
