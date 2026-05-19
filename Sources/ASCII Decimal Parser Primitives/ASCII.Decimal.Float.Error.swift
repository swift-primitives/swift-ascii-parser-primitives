//
//  ASCII.Decimal.Float.Error.swift
//  swift-ascii-parser-primitives
//
//  Typed errors for ASCII decimal floating-point parsing.
//

extension ASCII.Decimal.Float {
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Input was empty at the start of `parse(_:)`.
        case empty
        /// Input did not contain any decimal digit byte (0x30–0x39).
        case missingDigits
        /// The parsed value overflowed binary64 (magnitude > `Double.greatestFiniteMagnitude`).
        case overflow
        /// The parsed value underflowed to zero on binary64.
        case underflow
        /// Input had a syntactic defect (e.g., exponent with no digits).
        case malformed
    }
}
