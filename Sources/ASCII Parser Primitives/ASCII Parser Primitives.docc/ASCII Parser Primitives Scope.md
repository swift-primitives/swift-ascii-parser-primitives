# ASCII Parser Primitives Scope

The identity surface of `swift-ascii-parser-primitives`, and what is
deliberately out of it.

## Identity

`swift-ascii-parser-primitives` is a **discipline package over the upstream
`ASCII` namespace** (owned by `swift-ascii-primitives`, `ASCII.swift`) and the
upstream `Parser.Protocol` substrate (owned by `swift-parser-primitives`). It
binds the policy-free parser substrate to the concrete ASCII input domain:
ASCII-decimal-digit → integer, ASCII-hexadecimal-digit → integer, and
ASCII-decimal → floating-point parsing over `Byte` streams, plus the
`ASCII.Parseable` sibling protocol and the stdlib conformances that make the
domain ergonomic.

Because every declaration extends an upstream-owned namespace
(`extension ASCII { protocol Parseable }`, `extension ASCII.Decimal { … }`,
`extension ASCII.Hexadecimal { … }`) and imports external modules
(`ASCII_Primitives`, `Parser_Primitives_Core`, `Byte_Primitives`), the package
has **no zero-dependency `{Domain} Primitive` substrate root** of its own (per
the discipline-package rule, /modularization §7). It splits into sub-namespace
modules + an umbrella.

## Core targets

The package is decomposed by **input flavor / conformance subject**:

- **Parseable ASCII Primitives** — the `extension ASCII { protocol Parseable }`
  ASCII-substrate sibling protocol (family-Codable convention). Extends the
  upstream `ASCII` namespace; depends on `ASCII_Primitives`.
- **ASCII Decimal Parser Primitives** — `ASCII.Decimal.Parser<Input, T>`
  (ASCII decimal digits → `FixedWidthInteger`) and
  `ASCII.Decimal.Float.Parser<Input>` (Eisel-Lemire fast `Double` parser).
  Extends upstream `ASCII.Decimal`; depends on `ASCII_Primitives`,
  `Parser_Primitives_Core`.
- **ASCII Hexadecimal Parser Primitives** — `ASCII.Hexadecimal.Parser<Input, T>`:
  ASCII hexadecimal digits → `FixedWidthInteger`. Extends upstream
  `ASCII.Hexadecimal`; same dependencies as the decimal sub-namespace.
- **ASCII Parser Primitives Standard Library Integration** — the stdlib
  `FixedWidthInteger` `ASCII.Parseable` conformances (routed through
  `ASCII.Decimal.Parser`) and the `init(ascii:)` convenience over `Byte.Input`.
  Depends on `ASCII Decimal Parser Primitives`, `Parseable ASCII Primitives`.
- **ASCII Parser Primitives** — the umbrella, re-exporting every sub-namespace
  above plus the `ASCII.Parser` capability namespace shell.

## Out of scope

- A zero-dependency namespace root: this is a discipline package over upstream
  `ASCII` and `Parser`; it mints no `ASCII Parser Primitive` root.
- **`ASCII Parser Primitives Core`** is a transitional DEPRECATED shim
  (L1 core-dissolution sweep 2026-06-23), exports-only, re-exporting the
  dissolved Core surface (`Parseable ASCII Primitives` + the `ASCII` and
  `Parser` externals Core previously funneled). It is removed in the
  core-dissolution cleanup wave and is not part of the package's identity.
- **Serialization** (integer → ASCII bytes): → the serializer family
  (`swift-ascii-serializer-primitives`). Parsing here is one-way.
- **The parser combinator substrate** (map, filter, many, `var body`, …): →
  upstream `swift-parser-primitives`, which this package builds ON.

## Evaluation rule

Sub-target additions are evaluated against this scope. A proposed addition
that parses an ASCII-domain byte stream into a value, or conforms a type to
`ASCII.Parseable`, lands as / within a sub-namespace target per [MOD-031];
anything that serializes to ASCII, composes generic parser combinators, or
pins a non-ASCII input domain extracts to a sibling package, not into this one.
