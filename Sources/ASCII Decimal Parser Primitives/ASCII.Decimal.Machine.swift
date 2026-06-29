//
//  ASCII.Decimal.Machine.swift
//  swift-ascii-parser-primitives
//
//  Machine-based (borrowed-world / zero-copy) ASCII decimal integer parsers.
//  Relocated from the dissolved `Binary.ASCII.Parsing.Machine.Decimal` (W1):
//  the borrowed-IR twin of the owned-world `ASCII.Decimal.Parser`.
//

public import Binary_Machine_Primitives

extension ASCII.Decimal {
    /// Namespace for `Binary.Machine`-based decimal integer parsing.
    ///
    /// These parsers compile to the defunctionalized `Binary.Machine` IR for
    /// zero-copy, zero-allocation parsing when driven over a borrowed byte
    /// input. They are the borrowed-world twin of the owned-world
    /// ``ASCII/Decimal/Parser``.
    public enum Machine {}
}

extension ASCII.Decimal.Machine {
    /// Accumulator type for folding decimal digits.
    ///
    /// Tracks both the multiplier (power of 10) and running sum to enable
    /// combining with the required first digit.
    @usableFromInline
    struct FoldState<T: FixedWidthInteger & Sendable>: Sendable {
        @usableFromInline var multiplier: T
        @usableFromInline var sum: T

        @inlinable
        init(multiplier: T, sum: T) {
            self.multiplier = multiplier
            self.sum = sum
        }
    }
}

// MARK: - Unsigned Decimal Parsers

extension ASCII.Decimal.Machine {
    /// Creates a parser for unsigned decimal integers.
    ///
    /// Parses one or more ASCII decimal digits ('0'-'9') and converts to the
    /// specified unsigned integer type. Uses `fold` for zero-allocation parsing.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let parser = ASCII.Decimal.Machine.unsigned(UInt32.self)
    /// // Drive `parser` over a borrowed byte input via the Binary.Machine harness.
    /// ```
    ///
    /// - Parameter type: The unsigned integer type to parse into.
    /// - Returns: A Machine parser for unsigned decimal integers.
    @inlinable
    public static func unsigned<T: UnsignedInteger & FixedWidthInteger & Sendable>(
        _ type: T.Type = T.self
    ) -> Binary.Machine.Parser<T> {
        typealias M = Binary.Machine

        return M.build { builder -> M.Expression<T> in
            // Parse a single ASCII digit, convert to numeric value
            let digit = M.take1(in: &builder).tryMap({ byte throws(M.Fault) -> T in
                guard byte >= 0x30 && byte <= 0x39 else {
                    throw .predicateFailed(byte: byte)
                }
                return T(byte.underlying - 0x30)
            }, in: &builder)

            // Fold additional digits, tracking multiplier for final combination
            let moreDigits = M.fold(
                digit,
                initial: FoldState<T>(multiplier: 1, sum: 0),
                combine: { state, d in
                    FoldState(
                        multiplier: state.multiplier &* 10,
                        sum: state.sum &* 10 &+ d
                    )
                },
                in: &builder
            )

            // Combine: first digit * multiplier + accumulated sum
            return M.sequence(digit, moreDigits, combine: { first, state in
                first &* state.multiplier &+ state.sum
            }, in: &builder)
        }
    }
}

// MARK: - Signed Decimal Parsers

extension ASCII.Decimal.Machine {
    /// Creates a parser for signed decimal integers.
    ///
    /// Parses an optional sign ('-' or '+') followed by one or more ASCII
    /// decimal digits ('0'-'9') and converts to the specified signed integer type.
    /// Uses `fold` for zero-allocation parsing.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let parser = ASCII.Decimal.Machine.signed(Int32.self)
    /// // Drive `parser` over a borrowed byte input via the Binary.Machine harness.
    /// ```
    ///
    /// - Parameter type: The signed integer type to parse into.
    /// - Returns: A Machine parser for signed decimal integers.
    @inlinable
    public static func signed<T: SignedInteger & FixedWidthInteger & Sendable>(
        _ type: T.Type = T.self
    ) -> Binary.Machine.Parser<T> {
        typealias M = Binary.Machine

        return M.build { builder -> M.Expression<T> in
            // Parse optional sign: -1 for '-', +1 for '+' or no sign
            let minusSign = M.byte(0x2D, in: &builder).map({ _ in T(-1) }, in: &builder) // '-'
            let plusSign = M.byte(0x2B, in: &builder).map({ _ in T(1) }, in: &builder)  // '+'
            let noSign = M.pure(T(1), in: &builder)

            let sign = M.oneOf([minusSign, plusSign, noSign], in: &builder)

            // Parse a single ASCII digit, convert to numeric value
            let digit = M.take1(in: &builder).tryMap({ byte throws(M.Fault) -> T in
                guard byte >= 0x30 && byte <= 0x39 else {
                    throw .predicateFailed(byte: byte)
                }
                return T(byte.underlying - 0x30)
            }, in: &builder)

            // Fold additional digits, tracking multiplier for final combination
            let moreDigits = M.fold(
                digit,
                initial: FoldState<T>(multiplier: 1, sum: 0),
                combine: { state, d in
                    FoldState(
                        multiplier: state.multiplier &* 10,
                        sum: state.sum &* 10 &+ d
                    )
                },
                in: &builder
            )

            // Combine first digit with accumulated rest
            let magnitude = M.sequence(digit, moreDigits, combine: { first, state in
                first &* state.multiplier &+ state.sum
            }, in: &builder)

            // Apply sign
            return M.sequence(sign, magnitude, combine: { s, m in s &* m }, in: &builder)
        }
    }
}
