# RFD 0065: Taskweft domain schema in essential tuple normal form

**State:** discussion
**Scope:** RFD 0064's `domain.ex` and its 15,000 `problem.ex` files

## Problem

RFD 0064 asks Claude to inspect 15,000 dataset rows and write one
`problem.ex` per row. Many rows share the same hair color, eye
color, and pose. A schema that writes each trait as free text per
row repeats the same fact thousands of times.

## Decision

Design the `domain.ex`/`problem.ex` schema per essential tuple normal
form (ETNF), from Darwen, Date, and Fagin (ICDT 2012). See
`DETAILS.md` for the definition and its worked example. Two rules
follow.

1. `@variables` in `domain.ex` holds a trait map, keyed by trait
   name, one value per character. This matches the `have`/`handle`/
   `loaded` pattern RFD 0044's `domain.ex` already uses. The key is a
   superkey, so the map sits in Boyce-Codd normal form.
2. A trait value that repeats across characters, such as hair color
   or clothing archetype, goes in `domain.ex`'s top-level
   `capabilities` key, per RFD 0037's rule against `:enum`. Each
   `problem.ex` stores a `:ref` to a capability id, never the value
   as text.

Rule 2 removes the redundancy. ETNF proves a schema needs no full
fifth normal form to stay redundancy-free. A functional dependency
anchored on the capability id, a superkey, already blocks the
redundant tuple. See `DETAILS.md` for the proof this decision leans
on.

## Related

RFD 0064 sets the domain/problem split this schema fills in. RFD 0037
gives the `:ref`/`capabilities` type rules. RFD 0044 gives the
worked `domain.ex` this schema's shape follows.
