# swift-ascii-parser-primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Parses ASCII byte input into fixed-width integers across decimal, hexadecimal, binary, and octal radices, and into `Double` for decimal floating-point literals.

---

## Key Features

- **Four integer radices** — `ASCII.Decimal.Parser`, `ASCII.Hexadecimal.Parser`, `ASCII.Binary.Parser`, and `ASCII.Octal.Parser`, each generic over the input collection and the target `FixedWidthInteger`.
- **Sign and digit-count policies** — `ASCII.Digits.Sign` (`.none` / `.optional`) governs a leading `+`/`-` byte; `ASCII.Digits.Count` (`.greedy` / `.exactly(n)` / `.atMost(n)`) governs how many digit bytes are consumed.
- **Overflow-safe accumulation** — magnitude accumulates in the sign's direction so `T.min` is reachable, and every step uses reporting-overflow arithmetic that throws rather than wraps.
- **Floating-point parsing** — `ASCII.Decimal.Float.Parser` decodes decimal float literals to `Double` through a Clinger fast path, an Eisel–Lemire core, and a standard-library slow-path fallback for long mantissas.
- **Typed throws** — each parser fails with its own error type (`ASCII.Decimal.Error`, `ASCII.Hexadecimal.Error`, `ASCII.Binary.Error`, `ASCII.Octal.Error`, `ASCII.Decimal.Float.Error`) via `throws(Failure)`.
- **Combinator conformance** — every parser conforms to parser-primitives' `Parser.\`Protocol\``, composing with the wider parser ecosystem.
- **Standard-library integration** — conforms the ten fixed-width integer types to `ASCII.Parseable` and adds a `FixedWidthInteger.init(ascii:)` convenience.
- **Span hot path** — `ASCII.Decimal.Float.parse(_:)` accepts a borrowed `Span<Byte>` for callers that already hold contiguous byte storage.

---

## Quick Start

Construct a parser over `Byte.Input` and run it against an ASCII byte cursor. The parser consumes the digit run, advances the input past it, and returns the accumulated value:

```swift
import ASCII_Parser_Primitives   // decimal, hexadecimal, binary, octal parsers
import Byte_Parser_Primitives    // Byte.Input

// Greedy decimal parse into a UInt16.
var input = Byte.Input(utf8: "8080")
let port = try ASCII.Decimal.Parser<Byte.Input, UInt16>().parse(&input)        // 8080

// Fixed-width: consume exactly four digits, leaving the rest unconsumed.
var date = Byte.Input(utf8: "2026-06-30")
let year = try ASCII.Decimal.Parser<Byte.Input, Int>(count: .exactly(4)).parse(&date)  // 2026

// Signed: consume an optional leading '+'/'-', reaching Int8.min exactly.
var temp = Byte.Input(utf8: "-128")
let celsius = try ASCII.Decimal.Parser<Byte.Input, Int8>(sign: .optional).parse(&temp) // -128
```

The standard-library integration target adds a one-call convenience on the integer types themselves:

```swift
import ASCII_Parser_Primitives_Standard_Library_Integration

let count = try Int(ascii: Array("42".utf8))   // 42
```

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-ascii-parser-primitives.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "ASCII Parser Primitives", package: "swift-ascii-parser-primitives"),
    ]
)
```

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the matching Linux / Windows toolchain).

---

## Architecture

Eight library products: one per radix, an ASCII-substrate sibling protocol, a standard-library integration target, an umbrella, and a test-support target.

| Product | Purpose |
|---------|---------|
| `Parseable ASCII Primitives` | The `ASCII.Parseable` sibling protocol — the ASCII-substrate peer of the canonical parser-attachment protocol. |
| `ASCII Decimal Parser Primitives` | `ASCII.Decimal.Parser` for decimal integers and `ASCII.Decimal.Float.Parser` for decimal float literals, with their error types. |
| `ASCII Hexadecimal Parser Primitives` | `ASCII.Hexadecimal.Parser` for base-16 integers (`0–9`, `A–F`, `a–f`). |
| `ASCII Binary Parser Primitives` | `ASCII.Binary.Parser` for base-2 integers. |
| `ASCII Octal Parser Primitives` | `ASCII.Octal.Parser` for base-8 integers. |
| `ASCII Parser Primitives Standard Library Integration` | `ASCII.Parseable` conformances for the ten fixed-width integer types plus `FixedWidthInteger.init(ascii:)`. |
| `ASCII Parser Primitives` | Umbrella that re-exports the parsers and the `ASCII.Parser` capability namespace. |
| `ASCII Parser Primitives Test Support` | Re-exports the main targets for test consumers. |

Import the narrowest product you need — a single radix target for one parser, or the `ASCII Parser Primitives` umbrella for all of them.

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at first public flip.*
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE](LICENSE.md).
