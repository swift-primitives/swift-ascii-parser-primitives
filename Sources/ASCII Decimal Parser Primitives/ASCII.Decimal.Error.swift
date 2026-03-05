//
//  ASCII.Decimal.Error.swift
//  swift-ascii-parser-primitives
//
//  Error types for ASCII decimal parsing.
//

extension ASCII.Decimal {
    public enum Error: Swift.Error, Sendable, Equatable {
        /// No digit bytes found at current position.
        case noDigits
        /// The parsed value would overflow the target integer type.
        case overflow
    }
}
