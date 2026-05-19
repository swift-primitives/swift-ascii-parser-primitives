//
//  ASCII.Decimal.Float.swift
//  swift-ascii-parser-primitives
//
//  Namespace for ASCII decimal floating-point parsing.
//

extension ASCII.Decimal {
    /// Namespace for ASCII decimal floating-point parsing.
    ///
    /// Hosts ``ASCII/Decimal/Float/Parser``, an Eisel–Lemire-class fast
    /// parser that converts ASCII decimal digit sequences
    /// (e.g. `"-3.14159e-7"`) directly to IEEE 754 binary64
    /// (`Swift.Double`) without materializing an intermediate
    /// `Swift.String`. Sibling to ``ASCII/Decimal/Parser`` (integers).
    public enum Float {}
}
