import ASCII_Decimal_Parser_Primitives
import Testing

// Smoke tests for the relocated borrowed-world decimal Machine parser
// (`ASCII.Decimal.Machine`, moved from `Binary.ASCII.Parsing.Machine.Decimal`
// in W1). These exercise the `Binary.Machine.build` construction path for both
// the unsigned and signed parsers (the combinator wiring runs at build time);
// full execution is covered by the Binary.Machine borrowed-input harness in
// swift-binary-parser-primitives.

@Suite("ASCII.Decimal.Machine")
struct ASCIIDecimalMachineTests {
    @Test
    func `builds an unsigned decimal parser`() {
        let _: Binary.Machine.Parser<UInt32> = ASCII.Decimal.Machine.unsigned()
    }

    @Test
    func `builds a signed decimal parser`() {
        let _: Binary.Machine.Parser<Int32> = ASCII.Decimal.Machine.signed()
    }
}
