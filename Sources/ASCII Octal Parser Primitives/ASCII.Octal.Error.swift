//
//  ASCII.Octal.Error.swift
//  swift-ascii-parser-primitives
//
//  Error types for ASCII octal parsing.
//

extension ASCII.Octal {
    public enum Error: Swift.Error, Sendable, Equatable {
        /// No digit bytes found at current position.
        case noDigits
        /// The parsed value would overflow the target integer type.
        case overflow
        /// A fixed-count policy (`ASCII.Digits.Count.exactly(n)`) required `n`
        /// digit bytes, but fewer were available before a non-digit byte or the
        /// end of input. Also thrown for the degenerate `exactly(0)` policy.
        case insufficientDigits
        /// The input carried a leading `-` (0x2D) sign byte under the
        /// `ASCII.Digits.Sign.optional` policy, but the target integer type is
        /// unsigned and cannot represent a negative value. A leading `+` (0x2B)
        /// is always accepted.
        case invalidSign
    }
}
