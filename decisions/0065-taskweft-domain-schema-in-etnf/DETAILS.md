# RFD 0065 details: ETNF, its worked example, and the schema sketch

## The definition

Darwen, Date, and Fagin, "A Normal Form for Preventing Redundant
Tuples in Relational Databases" (ICDT 2012), define essential tuple
normal form (ETNF). A relation schema sits in ETNF when every tuple
in every instance is essential. An essential tuple is a tuple no one
can rebuild by projecting and rejoining the rest of the relation.

Their syntactic test (Theorem 1.13) needs only two checks. The
schema sits in Boyce-Codd normal form (BCNF), and some component of
every declared join dependency is a superkey. ETNF sits strictly
between fourth normal form (4NF) and fifth normal form (5NF, also
called projection-join normal form). The paper proves ETNF removes
tuple redundancy as well as 5NF does, though ETNF is easier to
satisfy.

## The worked example (the paper's Example 1.2)

A relation R has attributes supplier (S), part (P), and project (J).
A tuple (s, p, j) means supplier s supplies part p to project j. Two
constraints hold: the join dependency ⋈{SP, PJ, JS}, and the
functional dependency SP → J (a supplier and a part fix one project).

5NF asks for R to split into three relations, one per pair of
attributes, because of the join dependency alone. The paper shows
R already carries no redundant tuple. The FD SP → J forces the
join's third match before any tuple is added twice. R sits in 4NF
and ETNF, not in 5NF, and needs no split.

The lesson for this RFD: a functional dependency anchored on a
superkey already blocks redundant tuples. Decomposing further, down
to full 5NF, does no extra work against redundancy. It only adds more
tables to maintain.

## The schema sketch

`domain.ex`, shared across all 15,000 problems, holds the trait map
and one new action, `a_resolve_trait`. It has no fixed capability
list. The list grows as Claude's vision inspection meets new values.

```elixir
@variables %{
  trait: %{
    type: :ref,
    init: %{hair_color: nil, eye_color: nil, pose: nil, clothing: nil}
  }
}

@capabilities %{
  hair_color: %{},
  eye_color: %{},
  pose: %{},
  clothing: %{}
}

@actions %{
  a_resolve_trait: %{
    params: [:role, :caption_text],
    bind: [
      {:capability_id, {HRR.Cleanup, :resolve_or_create, ["{role}", "{caption_text}"]}}
    ],
    body: [
      %{pointer_set: "/trait/{role}", value: "{capability_id}"}
    ]
  }
}
```

`HRR.Cleanup.resolve_or_create/2` is the RFD 0021 library, called
from inside taskweft, not from `WeftspunStudio.FactVector`. It binds
the role and the caption text, and it checks the bound vector against
the existing codebook. A near match returns the existing capability
id. No match creates one and adds it to the codebook. Each `problem.ex`
then calls `a_resolve_trait` once per trait, and stores only the
returned `:ref`, never the caption text.

## What this schema does not need

No per-trait join table, no per-character-pair table, and no
hand-maintained enum list. The 15,000 `problem.ex` files repeat only
a capability id. Near-duplicate captions collapse to one id through
`HRR.Cleanup`, so the redundant-tuple problem the paper's Example
1.1 shows never appears here.

## Source

Darwen, H., Date, C. J., and Fagin, R. "A Normal Form for
Preventing Redundant Tuples in Relational Databases." ICDT 2012,
Berlin. https://openproceedings.org/2012/conf/icdt/DarwenDF12.pdf
