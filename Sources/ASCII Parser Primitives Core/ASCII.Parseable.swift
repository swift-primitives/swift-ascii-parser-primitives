//
//  ASCII.Parseable.swift
//  swift-ascii-parser-primitives
//
//  ASCII-substrate refinement of Parseable.
//

public import Parser_Primitives_Core

extension ASCII {
    /// A type whose canonical parser consumes ASCII-substrate byte content.
    ///
    /// Nominal refinement of ``Parser_Primitives_Core/Parseable``. Generic
    /// algorithms that want to dispatch on ASCII-substrate parsing can
    /// require `T: ASCII.Parseable`; consumers requiring `T: Parseable`
    /// match via inheritance.
    public protocol Parseable: Parser_Primitives_Core.Parseable {}
}
