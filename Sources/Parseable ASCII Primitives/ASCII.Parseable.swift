//
//  ASCII.Parseable.swift
//  swift-ascii-parser-primitives
//
//  ASCII-substrate sibling protocol in the family-Codable convention.
//

public import ASCII_Primitives

extension ASCII {
    /// A type whose canonical parser consumes ASCII-substrate byte content.
    ///
    /// Top-level format-specific sibling protocol per family-Codable
    /// convention [FAM-001/006]: flat, no associated types, no refinement
    /// of canonical-attachment protocols. Symmetric with
    /// ``Binary/Parseable`` — both are non-refining peers of the
    /// canonical `Parseable` attachment protocol.
    ///
    /// Generic algorithms dispatching on ASCII-substrate parsing can
    /// require `T: ASCII.Parseable`. Conformers witness the requirement
    /// with the uniform `init(ascii:)` — parsing ASCII-substrate bytes into
    /// the conforming type — and surface their parse-failure type through
    /// the `Failure` associated type. The canonical parser instance may
    /// additionally be exposed as a static accessor, by convention.
    ///
    /// ## Symmetry with `ASCII.Serializable`
    ///
    /// A type may conform to both `ASCII.Parseable` (read) and the
    /// future `ASCII.Serializable` peer (write) — per the family-Codable
    /// convention's byte-stream split-pair shape. Until `ASCII.Serializable`
    /// lands (per Φ.1 of the ASCII codable unification plan), conformers
    /// expose serialization through `ASCII.Decimal.Serializer<T>` or
    /// peer leaves directly.
    public protocol Parseable {
        /// The error thrown when parsing ASCII-substrate bytes fails.
        associatedtype Failure: Swift.Error

        /// Creates a value by parsing ASCII-substrate byte content.
        ///
        /// - Parameter bytes: The ASCII-substrate bytes to parse.
        /// - Throws: `Failure` if the content does not parse.
        init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Failure)
        where Bytes.Element == Byte
    }
}
