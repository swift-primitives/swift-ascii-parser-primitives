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
    /// require `T: ASCII.Parseable`. The canonical parser instance is
    /// supplied by the conformer as a static accessor, by convention
    /// (no protocol requirement carries the associated-type slot).
    ///
    /// ## Symmetry with `ASCII.Serializable`
    ///
    /// A type may conform to both `ASCII.Parseable` (read) and the
    /// future `ASCII.Serializable` peer (write) — per the family-Codable
    /// convention's byte-stream split-pair shape. Until `ASCII.Serializable`
    /// lands (per Φ.1 of the ASCII codable unification plan), conformers
    /// expose serialization through `ASCII.Decimal.Serializer<T>` or
    /// peer leaves directly.
    public protocol Parseable {}
}
