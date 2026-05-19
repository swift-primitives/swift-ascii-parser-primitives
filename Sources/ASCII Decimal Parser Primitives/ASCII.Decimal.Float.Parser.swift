//
//  ASCII.Decimal.Float.Parser.swift
//  swift-ascii-parser-primitives
//
//  Eisel–Lemire-class ASCII-decimal-to-binary64 parser.
//
//  Port of fast_float's scalar `from_chars` for binary64 (Apache 2.0).
//  References:
//   - Lemire, Number Parsing at a Gigabyte per Second, SP&E 2021.
//   - Mushtak & Lemire, Fast Number Parsing Without Fallback.
//

public import Collection_Primitives

extension ASCII.Decimal.Float {
    /// A parser that consumes an ASCII decimal floating-point literal
    /// (e.g. `"-3.14159e-7"`, `"0.0001"`, `"6.022e23"`) and produces a
    /// `Swift.Double` via the Eisel–Lemire algorithm.
    ///
    /// The grammar accepted is the standard JSON/IEEE number grammar:
    /// optional sign, one or more integer digits, optional fraction
    /// (`.` followed by digits), optional exponent (`e`/`E` followed
    /// by optional sign and digits). The parser stops at the first
    /// non-numeric byte, leaving any trailing input unconsumed.
    ///
    /// ## Algorithm
    ///
    /// Three-tier strategy:
    /// 1. **Clinger fast path** — when the mantissa fits in 53 bits and
    ///    the decimal exponent is in `[-22, +22]`, a single IEEE round
    ///    of `Double(mantissa) * 10^q` is exact.
    /// 2. **Eisel–Lemire core** — 128-bit product of the mantissa with
    ///    a precomputed power-of-five table entry (10⁻³⁴² ≤ 10ᵠ ≤ 10³⁰⁸).
    ///    Mushtak–Lemire (2024) proves the product alone is sufficient
    ///    for ≤19-digit mantissas; no fallback is required in this
    ///    branch.
    /// 3. **Slow path** — when the literal has >19 significant digits,
    ///    fall back to the standard library's `Double.init(_: String)`
    ///    for correct rounding. Rare in JSON workloads.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let parser = ASCII.Decimal.Float.Parser<Cursor>()
    /// var input: Cursor = [0x2D, 0x33, 0x2E, 0x31, 0x34]   // "-3.14"
    /// let value = try parser.parse(&input)                  // -3.14
    /// ```
    public struct Parser<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension ASCII.Decimal.Float.Parser: Parser.`Protocol` {
    public typealias Output = Double
    public typealias Failure = ASCII.Decimal.Float.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Double {
        guard !input.isEmpty else { throw .empty }

        var index = input.startIndex
        var negative = false

        // Sign
        let first = input[index]
        if first == 0x2D {              // '-'
            negative = true
            input.formIndex(after: &index)
        } else if first == 0x2B {       // '+'
            input.formIndex(after: &index)
        }

        var mantissa: UInt64 = 0
        var nSignificantDigits = 0      // mantissa contributors only (≤ 19)
        var nTotalDigits = 0
        var nDigitsAfterPoint = 0
        var tooManyDigits = false
        var sawAnyDigit = false

        // Integer digits
        while index < input.endIndex {
            let b = input[index]
            guard b >= 0x30, b <= 0x39 else { break }
            sawAnyDigit = true
            if nSignificantDigits < 19 {
                mantissa = mantissa &* 10 &+ UInt64(b &- 0x30)
                nSignificantDigits &+= 1
            } else {
                tooManyDigits = true
            }
            nTotalDigits &+= 1
            input.formIndex(after: &index)
        }

        // Fraction
        if index < input.endIndex, input[index] == 0x2E {
            input.formIndex(after: &index)
            while index < input.endIndex {
                let b = input[index]
                guard b >= 0x30, b <= 0x39 else { break }
                sawAnyDigit = true
                if nSignificantDigits < 19 {
                    mantissa = mantissa &* 10 &+ UInt64(b &- 0x30)
                    nSignificantDigits &+= 1
                } else {
                    tooManyDigits = true
                }
                nTotalDigits &+= 1
                nDigitsAfterPoint &+= 1
                input.formIndex(after: &index)
            }
        }

        guard sawAnyDigit else { throw .missingDigits }

        // Exponent
        var explicitExp = 0
        let beforeExp = index
        if index < input.endIndex {
            let b = input[index]
            if b == 0x65 || b == 0x45 {     // 'e' / 'E'
                input.formIndex(after: &index)
                var expNegative = false
                if index < input.endIndex {
                    let s = input[index]
                    if s == 0x2D {
                        expNegative = true
                        input.formIndex(after: &index)
                    } else if s == 0x2B {
                        input.formIndex(after: &index)
                    }
                }
                var expValue = 0
                var sawExpDigit = false
                while index < input.endIndex {
                    let b = input[index]
                    guard b >= 0x30, b <= 0x39 else { break }
                    sawExpDigit = true
                    // Saturate at a value already large enough to overflow Double.
                    if expValue < 100_000 {
                        expValue = expValue &* 10 &+ Int(b &- 0x30)
                    }
                    input.formIndex(after: &index)
                }
                if !sawExpDigit {
                    // Rewind: the 'e' belonged to a different token.
                    index = beforeExp
                } else {
                    explicitExp = expNegative ? -expValue : expValue
                }
            }
        }

        let q = explicitExp - nDigitsAfterPoint

        let value: Double
        if !tooManyDigits, let fast = ASCII.Decimal.Float.clingerFastPath(
            negative: negative, mantissa: mantissa, q: q
        ) {
            value = fast
        } else if !tooManyDigits {
            value = ASCII.Decimal.Float.eiselLemire(
                negative: negative, mantissa: mantissa, q: q
            )
        } else {
            // Reconstruct the literal bytes for the slow path.
            value = try ASCII.Decimal.Float.slowPath(
                input: input, start: input.startIndex, end: index
            )
            _ = nTotalDigits   // silence unused-warning; reserved for future big-int path
        }

        input = input[index...]
        return value
    }
}

// MARK: - Span Entry Point

extension ASCII.Decimal.Float {
    /// Parses an ASCII decimal float literal from a borrowed
    /// `Swift.Span<UInt8>` and returns the corresponding `Double`.
    ///
    /// Hot-path entry for callers that already have contiguous byte
    /// storage (e.g. JSON's `lexNumberValue`). Same algorithm as
    /// ``Parser/parse(_:)`` but without `inout` consumption: the
    /// entire span is parsed or the call throws.
    ///
    /// - Parameter span: ASCII decimal float bytes
    ///   (`-? digit+ ('.' digit+)? ([eE] [+-]? digit+)?`).
    /// - Returns: The corresponding `Double`. `.infinity` / `0.0` are
    ///   valid returns for magnitudes outside binary64 range.
    /// - Throws: ``Error`` on syntactic failure.
    @inlinable
    public static func parse(
        _ span: borrowing Swift.Span<UInt8>
    ) throws(ASCII.Decimal.Float.Error) -> Double {
        guard !span.isEmpty else { throw .empty }

        var i = 0
        let end = span.count
        var negative = false

        let first = span[i]
        if first == 0x2D {              // '-'
            negative = true
            i &+= 1
        } else if first == 0x2B {       // '+'
            i &+= 1
        }

        var mantissa: UInt64 = 0
        var nSignificantDigits = 0
        var nDigitsAfterPoint = 0
        var tooManyDigits = false
        var sawAnyDigit = false

        // Integer digits
        while i < end {
            let b = span[i]
            guard b >= 0x30, b <= 0x39 else { break }
            sawAnyDigit = true
            if nSignificantDigits < 19 {
                mantissa = mantissa &* 10 &+ UInt64(b &- 0x30)
                nSignificantDigits &+= 1
            } else {
                tooManyDigits = true
            }
            i &+= 1
        }

        // Fraction
        if i < end, span[i] == 0x2E {
            i &+= 1
            while i < end {
                let b = span[i]
                guard b >= 0x30, b <= 0x39 else { break }
                sawAnyDigit = true
                if nSignificantDigits < 19 {
                    mantissa = mantissa &* 10 &+ UInt64(b &- 0x30)
                    nSignificantDigits &+= 1
                } else {
                    tooManyDigits = true
                }
                nDigitsAfterPoint &+= 1
                i &+= 1
            }
        }

        guard sawAnyDigit else { throw .missingDigits }

        // Exponent
        var explicitExp = 0
        let beforeExp = i
        if i < end {
            let b = span[i]
            if b == 0x65 || b == 0x45 {
                i &+= 1
                var expNegative = false
                if i < end {
                    let s = span[i]
                    if s == 0x2D {
                        expNegative = true
                        i &+= 1
                    } else if s == 0x2B {
                        i &+= 1
                    }
                }
                var expValue = 0
                var sawExpDigit = false
                while i < end {
                    let b = span[i]
                    guard b >= 0x30, b <= 0x39 else { break }
                    sawExpDigit = true
                    if expValue < 100_000 {
                        expValue = expValue &* 10 &+ Int(b &- 0x30)
                    }
                    i &+= 1
                }
                if !sawExpDigit {
                    i = beforeExp
                } else {
                    explicitExp = expNegative ? -expValue : expValue
                }
            }
        }

        let q = explicitExp - nDigitsAfterPoint

        if !tooManyDigits, let fast = clingerFastPath(
            negative: negative, mantissa: mantissa, q: q
        ) {
            return fast
        } else if !tooManyDigits {
            return eiselLemire(
                negative: negative, mantissa: mantissa, q: q
            )
        } else {
            // Slow path: reconstruct prefix-of-span bytes for stdlib.
            var bytes: [UInt8] = []
            bytes.reserveCapacity(i)
            for j in 0..<i { bytes.append(span[j]) }
            let str = Swift.String(decoding: bytes, as: Swift.UTF8.self)
            guard let v = Double(str), v.isFinite else { throw .overflow }
            return v
        }
    }
}

// MARK: - Clinger Fast Path

extension ASCII.Decimal.Float {
    /// Maximum mantissa that is exactly representable in binary64 (2⁵³ − 1).
    @usableFromInline
    internal static let maxMantissaFastPath: UInt64 = 9_007_199_254_740_991

    /// Decimal exponent range over which Clinger's fast path is exact.
    @usableFromInline
    internal static let minExponentFastPath: Int = -22
    @usableFromInline
    internal static let maxExponentFastPath: Int =  22

    /// Powers of 10 that are exactly representable as binary64.
    /// `1e0` through `1e22` are exact; `1e23` and beyond are not.
    @usableFromInline
    internal static let exactPowersOfTen: [Double] = [
        1e0,  1e1,  1e2,  1e3,  1e4,  1e5,  1e6,  1e7,
        1e8,  1e9,  1e10, 1e11, 1e12, 1e13, 1e14, 1e15,
        1e16, 1e17, 1e18, 1e19, 1e20, 1e21, 1e22,
    ]

    /// Clinger's algorithm M: a single rounded IEEE multiplication of two
    /// exactly-representable operands yields a correctly rounded result.
    ///
    /// Returns `nil` when preconditions aren't met (mantissa too large or
    /// exponent out of `[−22, +22]`); the caller falls through to Eisel–Lemire.
    @inlinable
    internal static func clingerFastPath(
        negative: Bool, mantissa: UInt64, q: Int
    ) -> Double? {
        guard mantissa <= maxMantissaFastPath else { return nil }
        guard q >= minExponentFastPath, q <= maxExponentFastPath else { return nil }

        let m = Double(mantissa)
        let value: Double
        if q >= 0 {
            value = m * exactPowersOfTen[q]
        } else {
            value = m / exactPowersOfTen[-q]
        }
        return negative ? -value : value
    }
}

// MARK: - Eisel–Lemire Core

extension ASCII.Decimal.Float {
    @usableFromInline
    internal static let mantissaExplicitBits: Int = 52
    @usableFromInline
    internal static let minimumExponent: Int = -1023
    @usableFromInline
    internal static let infinitePower: Int = 0x7FF
    @usableFromInline
    internal static let minExponentRoundToEven: Int = -4
    @usableFromInline
    internal static let maxExponentRoundToEven: Int =  23

    /// Eisel–Lemire core: compute the correctly rounded binary64 for
    /// `(mantissa, q)` where `mantissa` fits in 19 decimal digits.
    ///
    /// Mushtak–Lemire (2024) proves the 128-bit product approximation is
    /// always sufficient for this case; no big-integer fallback is needed.
    @inlinable
    internal static func eiselLemire(
        negative: Bool, mantissa: UInt64, q: Int
    ) -> Double {
        var w = mantissa

        // Special cases: zero, underflow, overflow.
        if w == 0 || q < smallestPowerOfTen {
            return negative ? -0.0 : 0.0
        }
        if q > largestPowerOfTen {
            return negative ? -.infinity : .infinity
        }

        // Normalize w: shift left so the MSB is 1.
        let lz = w.leadingZeroBitCount
        w <<= lz

        // Look up 128-bit power-of-five approximation.
        let tableIndex = q - smallestPowerOfTen
        let factor = powerOfFive128[tableIndex]

        // 128-bit product approximation.
        var (high, low) = w.multipliedFullWidth(by: factor.high)

        // If the high word's low bits are all 1, the approximation may be
        // off — fold in the contribution from factor.low to disambiguate.
        // Precision = mantissaExplicitBits + 3 = 55 bits → mask = 0x1FF.
        let precisionMask: UInt64 = ~UInt64(0) >> (mantissaExplicitBits + 3)
        if (high & precisionMask) == precisionMask {
            let (h2, _) = w.multipliedFullWidth(by: factor.low)
            let newLow = low &+ h2
            if h2 > newLow {        // carry into `high`
                high &+= 1
            }
            low = newLow
        }

        let upperBit = Int(high >> 63)
        let shift = upperBit + 64 - mantissaExplicitBits - 3
        var resultMantissa = high >> shift

        // power(q) = floor(q · log₂(10)) approximation, see fast_float.
        // Equivalent: ((152170 + 65536) * q) >> 16 + 63 ≈ q · 3.321928 + 63.
        let powerOfQ = (((152170 &+ 65536) &* q) >> 16) &+ 63
        var power2 = powerOfQ + upperBit - lz - minimumExponent

        // Subnormal handling.
        if power2 <= 0 {
            if -power2 + 1 >= 64 {
                // Magnitude is smaller than the smallest subnormal.
                return negative ? -0.0 : 0.0
            }
            resultMantissa >>= UInt64(-power2 + 1)
            resultMantissa &+= resultMantissa & 1
            resultMantissa >>= 1
            // A "just barely normal" mantissa might round up out of subnormal range.
            let normalized = resultMantissa >= (UInt64(1) << mantissaExplicitBits)
            power2 = normalized ? 1 : 0
            return makeDouble(negative: negative, mantissa: resultMantissa, power2: power2)
        }

        // Round-to-even correction when the bit dropped on rounding is the only
        // information available and we sit exactly between two binary64 values.
        if low <= 1,
           q >= minExponentRoundToEven, q <= maxExponentRoundToEven,
           (resultMantissa & 3) == 1 {
            if (resultMantissa << shift) == high {
                resultMantissa &= ~UInt64(1)    // clear bit 0: round-to-even
            }
        }

        // Round to nearest by adding the low bit, then shifting away.
        resultMantissa &+= resultMantissa & 1
        resultMantissa >>= 1

        // If rounding overflowed into the next exponent, normalize.
        if resultMantissa >= (UInt64(2) << mantissaExplicitBits) {
            resultMantissa = UInt64(1) << mantissaExplicitBits
            power2 &+= 1
        }

        // Strip the implicit leading 1 from the mantissa.
        resultMantissa &= ~(UInt64(1) << mantissaExplicitBits)

        if power2 >= infinitePower {
            return negative ? -.infinity : .infinity
        }

        return makeDouble(negative: negative, mantissa: resultMantissa, power2: power2)
    }

    /// Pack `(sign, mantissa, power2)` into IEEE 754 binary64 bits.
    @inlinable
    internal static func makeDouble(
        negative: Bool, mantissa: UInt64, power2: Int
    ) -> Double {
        let signBit: UInt64 = negative ? (1 &<< 63) : 0
        let expBits: UInt64 = (UInt64(bitPattern: Int64(power2)) & 0x7FF) &<< 52
        let mantBits: UInt64 = mantissa & 0x000F_FFFF_FFFF_FFFF
        return Double(bitPattern: signBit | expBits | mantBits)
    }
}
