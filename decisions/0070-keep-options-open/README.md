# RFD 0070: Keep options open

**State:** published
**Scope:** `decisions/`

## Problem

This repository wrote down three RFDs for a build nobody started.
RFD 0024 picked nx-ggml, and RFD 0019 replaced it, yet RFD 0024
stayed in the index as a live decision. RFD 0032 sketched a
clean-room alpha wrap algorithm RFD 0031's fallback already made
unneeded. RFD 0068 picked a training approach for a model that
needs data RFD 0064 has not finished producing.

Each RFD carried a reading cost, a cross-reference to keep current,
and an index row, for an option nobody had exercised.

## Decision

Do not open an RFD for a build this project has not committed to.

Kent Beck's price-theory reading of YAGNI names the cost: an
unexercised option costs twice if the guess is wrong, so a thing not
yet committed to is worth more left unbuilt. Waiting holds an asset.
It does not delay work.

This session deleted RFD 0024, RFD 0032, and RFD 0068 under this
rule. RFD 0031 keeps its existing fallback, with no successor RFD
promised. Committed work already under way, such as RFD 0064 and
RFD 0065, is not this rule's target. The rule stops a new RFD from
opening before commitment. It does not reach back into one already
running.

## References

- Kent Beck, "The Cost YAGNI Was Never About":
  https://newsletter.kentbeck.com/p/the-cost-yagni-was-never-about

## Related

RFD 0000 gives the state ladder a speculative RFD would otherwise
sit on. RFD 0024, RFD 0032, and RFD 0068 are the three this rule
removed. RFD 0031 keeps the fallback RFD 0032 would have replaced.
