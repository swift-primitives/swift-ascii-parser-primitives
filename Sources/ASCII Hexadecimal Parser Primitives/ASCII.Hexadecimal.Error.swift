//
//  ASCII.Hexadecimal.Error.swift
//  swift-ascii-parser-primitives
//
//  Error types for ASCII hexadecimal parsing.
//

extension ASCII.Hexadecimal {
    public enum Error: Swift.Error, Sendable, Equatable {
        /// No digit bytes found at current position.
        case noDigits
        /// The parsed value would overflow the target integer type.
        case overflow
    }
}
