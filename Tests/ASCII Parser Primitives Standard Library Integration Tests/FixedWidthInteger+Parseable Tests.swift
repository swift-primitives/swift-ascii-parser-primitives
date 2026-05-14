import ASCII_Parser_Primitives_Standard_Library_Integration
import Testing

@Suite("Parseable Integer Conformances")
struct ParseableIntegerTests {
    @Test
    func `Int parses via Parseable`() throws {
        let value = try Int(ascii: [UInt8]("42".utf8))
        #expect(value == 42)
    }

    @Test
    func `UInt parses via Parseable`() throws {
        let value = try UInt(ascii: [UInt8]("100".utf8))
        #expect(value == 100)
    }

    @Test
    func `Int8 parses via Parseable`() throws {
        let value = try Int8(ascii: [UInt8]("127".utf8))
        #expect(value == 127)
    }

    @Test
    func `UInt8 parses via Parseable`() throws {
        let value = try UInt8(ascii: [UInt8]("255".utf8))
        #expect(value == 255)
    }

    @Test
    func `Int16 parses via Parseable`() throws {
        let value = try Int16(ascii: [UInt8]("8080".utf8))
        #expect(value == 8080)
    }

    @Test
    func `UInt16 parses via Parseable`() throws {
        let value = try UInt16(ascii: [UInt8]("65535".utf8))
        #expect(value == 65535)
    }

    @Test
    func `Int32 parses via Parseable`() throws {
        let value = try Int32(ascii: [UInt8]("0".utf8))
        #expect(value == 0)
    }

    @Test
    func `UInt32 parses via Parseable`() throws {
        let value = try UInt32(ascii: [UInt8]("1000000".utf8))
        #expect(value == 1_000_000)
    }

    @Test
    func `Int64 parses via Parseable`() throws {
        let value = try Int64(ascii: [UInt8]("9223372036854775807".utf8))
        #expect(value == Int64.max)
    }

    @Test
    func `UInt64 parses via Parseable`() throws {
        let value = try UInt64(ascii: [UInt8]("18446744073709551615".utf8))
        #expect(value == UInt64.max)
    }
}
