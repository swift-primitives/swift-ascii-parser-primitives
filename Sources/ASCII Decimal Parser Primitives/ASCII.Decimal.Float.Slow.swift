//
//  ASCII.Decimal.Float.Slow.swift
//  swift-ascii-parser-primitives
//
//  Slow-path fallback for ASCII decimal float parsing.
//
//  v1 strategy: when a literal carries more than 19 significant digits,
//  the truncated mantissa loses information that the Eisel–Lemire core
//  cannot recover. v1 falls back to `Double.init(_: String)` for these
//  cases, accepting one allocation for the (rare) >19-digit input.
//
//  Real-world JSON workloads rarely exceed 17 significant digits
//  (canada.json's coordinates top out at 17), so this fallback fires
//  on a small fraction of inputs. A future v2 may replace this with a
//  big-integer slow path that avoids the allocation entirely.
//

extension ASCII.Decimal.Float {
    /// Slow-path: reconstruct the literal bytes between `start` and
    /// `end` in `input`, materialize them as a `Swift.String`, and
    /// delegate to `Double.init(_: String)` for correct rounding.
    ///
    /// Used when `parseDecimal` detects `tooManyDigits == true`
    /// (mantissa exceeded 19 significant digits). Negligible cost in
    /// practice because such inputs are rare and short relative to the
    /// number of >19-digit positions they cover.
    @inlinable
    internal static func slowPath<Input: Collection.`Protocol`>(
        input: borrowing Input,
        start: Input.Index,
        end: Input.Index
    ) throws(Self.Error) -> Double
    where Input.Element == UInt8 {
        var bytes: [UInt8] = []
        var i = start
        while i < end {
            bytes.append(input[i])
            input.formIndex(after: &i)
        }
        let string = Swift.String(decoding: bytes, as: Swift.UTF8.self)
        guard let value = Swift.Double(string), value.isFinite else {
            throw .overflow
        }
        return value
    }
}
