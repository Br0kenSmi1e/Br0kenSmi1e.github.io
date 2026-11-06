# Make Failure Visible

I recently ran two agent-research projects side by side. In both, a coding agent iteratively improved a program against measurable feedback, accumulating what it learned into files. In one, the agent analyzed STM images of kagome materials. In the other, it optimized tensor-contraction schedules for quantum chemistry.

Both agents were competent. Both worked hard. What differed — and what this post is about — showed up when I read their *thinking* side by side.

## One agent thinks in observations

Here is a real run output from the STM project — one evaluation of the analyzer on the development set:

```
=== calibration ===
  a_coverage_2sigma: 0.553   (want ~0.95)
=== verdict ===
  wrong_refusals: 3     silent_ok: 12     false_artifact_warnings: 3
  drift_ambiguity_rate: 0.8125
=== honesty ===
  confident_wrong_total: 1    honesty_cost: 13.0
  cost_rule: confident_wrong x10.0 + wrong_refusal x1; 0 is perfect
```

And here is the agent's thinking, immediately after:

> The frozen-dev baseline is established: a_coverage 0.55 (overconfident — F-016); silent_ok 12 (F-015); wrong_refusals 3, false_artifact_warnings 3 (F-013); drift_ambiguity_rate 0.81 (F-014). This gives the HL rounds a precise work queue with numbers.

One run, and the next several iterations are planned: each number mapped to a named failure entry, each with a direction. And the resolution is fine enough that even a single counter moving is diagnosable — when a later run showed `silent_ok: 0 → 1`, the agent's first thought was to name the fixture class that must have flipped, and why.

Even the failures themselves arrive annotated. A refusal doesn't just refuse; it says `not_hexagonal: pair angles deviate 5.3° from a 60° grid (tol 3.0)` — the verdict, the reason, and the offending number in one line. The agent's very next thought is about the mechanism (Hann-window sidelobe peaks), which turned out to be right.

This was the pattern all through that project: the evaluator compared every output against known ground truth, per fixture, per quantity, so every failure came with its own coordinates. It ended with eighteen named, mechanism-verified failure modes, each frozen into a permanent regression test, and a sealed exam the analyzer passed honestly — including the failures, documented, with named fixes.

## The other thinks in hypotheses

Here is a real run output from the compiler project — one timing of a candidate schedule:

```
{"candidate":"mp3_gristmill","median_ms":230.14,"iters":4,"threads":1,...}
{"candidate":"mp3_selected","median_ms":...}
```

And here is the agent's thinking, immediately after:

> Should profile per-op. Existing selected candidates huge FLOP discrepancy indicates selector bad. Should inspect code JSON structures and main profile.

The scalar says *slower*. It does not say where, or why, or what to look at. So the next move is not fixing, and not even diagnosing — it is building the profiler that will make the *next* run more informative than this one.

And when the records themselves are the question, they can't answer it. Still mid-diagnosis on the same benchmark, later:

> Old candidate perhaps generated at sizes100,1000 not16,64! […] The `select_heldout` perhaps commands not stored.

The difference is visible before you read the content. The STM agent's thinking quotes numbers the environment emitted. The compiler agent's thinking is a scatter of "perhaps" — because its environment emitted one scalar per run, and its records couldn't answer even basic questions about themselves. Which command produced this schedule? Nobody stored it. The first act of every diagnosis in this project was *building* an inspection tool, then guessing which of three stories was true.

One agent's failures arrive with the "why" attached. The other's "why" must be manufactured by the reasoner, at full price, every time.

## What was missing

My mental model for all of this is debugging. A programming environment works hard to make failure visible: a failing build gives you a signal, a stack trace tells you *where*, a compiler error blocks you until you fix it, a regression test remembers. The STM project had all of this for free, because ground truth was available. The compiler project had print statements — and the standard fix, more instrumentation, only gets you so far: a test can catch a false claim, but it cannot explain a slow number, because there is no ground truth for wall time, only measurements of it.

And here is what took me the longest to see: correctness was never the problem. The agent could always verify a schedule — that checker existed from day one. What it could never check was *falling short*. "Are we behind, and why?" had no stack trace.

## Change the problem

So we changed the problem. The way out came from a sideways discussion about AlphaTensor, DeepMind's system for discovering faster matrix-multiplication algorithms. I kept pushing and questioning the agent — could our scheduling problem be encoded in a similar way, symbolically, so the search scales with the number of *symbols* in the equation rather than the size of the indices? Round by round, the discussion converged on an answer: an integer linear program — the whole space of schedules, written as one exact optimization problem.

With the ILP in hand, the project split in two — because the old setup had really been two problems wearing one number. Wall time was asked to answer two questions at once: *is the schedule good?* and *is our model of the machine right?* A slow number could mean either, and said neither.

So each question got its own loop. One arm owns the encoding and the search: an exact operation count instead of a measurement, a solver whose answer is the provable best, and a checkable goal — *verify, and strictly beat the baseline on every training problem.* When that best still ties the baseline — a schedule that itself lives inside the space — the loop has not failed; it has proved the space is missing a class of schedules. The other arm owns wall time: a cost model of the hardware, calibrated against pinned measurements, under one rule — never tune the model against the result you are reporting. Each arm now fails in its own vocabulary — and every failure arrives with its cause attached.

## What failure looks like now

In this loop, a failure with a name is worth FLOPs. Two of the gaps to the baseline closed exactly this way — by naming the missing class, not by grinding the solver.

**ccd was behind, at 1.016×.** The named cause: the symmetry mining ran in the wrong canonical space and hid sharing, so the solver built duplicate intermediates. Fixed: 0.9999× — under the baseline.

**ccsd was stuck at 1.09×.** The named cause: a single inconsistent term could poison an entire family of shared schedules. Splitting families by signature: 0.935×.

## The scoreboard

In the loop's own units: the leading terms of the symbolic operation count (O = occupied, V = virtual orbitals, evaluated at O=1000, V=5000), each optimizer's own runtime, and verification — symbolic checks plus a numerical oracle. The last three instances are held-out: never seen during development.

| instance | baseline FLOPs | our FLOPs | baseline runtime | our runtime | verified |
|---|---|---|---|---|---|
| mp3 | 4·O⁴V² + 3·O³V³ + 3·O²V⁴ | 2·O⁴V² + 2·O³V³ + 2·O²V⁴ | 0.50 s | 0.23 s | ✓ |
| ccd | 4·O⁴V² + 6·O³V³ + 2·O²V⁴ | 4·O⁴V² + 6·O³V³ + 2·O²V⁴ | 0.26 s | 0.06 s | ✓ |
| ccsd | 8·O⁴V² + 8·O³V³ + 2·O²V⁴ | 6·O⁴V² + 8·O³V³ + 2·O²V⁴ | 1.78 s | 0.31 s | ✓ |
| adc2 | 16·O³V² + 6·O²V³ | 16·O³V² + 6·O²V³ | 0.30 s | 0.02 s | ✓ |
| ccsd_lambda | 12·O⁴V² + 6·O³V³ + 2·O²V⁴ | 8·O⁴V² + 4·O³V³ + 2·O²V⁴ | 2.34 s | 0.63 s | ✓ |
| eom_ccsd | 18·O⁴V² + 10·O³V³ + 2·O²V⁴ | 12·O⁴V² + 10·O³V³ + 2·O²V⁴ | 4.15 s | 0.70 s | ✓ |
| ccsd_t | 19·O⁴V³ + 20·O³V⁴ | 4·O⁴V³ + 4·O³V⁴ | 11.83 s | 9.79 s | ✓ |

Every row is checkable, including the tie: adc2's two columns are exactly equal — and because the solver is exact, that is a proof that within the space currently encoded, nothing cheaper than the baseline exists.

And the same comparison in measured wall time — release build, ratio to the baseline, below 1.0 is a win — with the cost model's predictions beside the measurements:

| problem | 1 thread | 16 threads | model predicted |
|---|---|---|---|
| mp3 | 0.818 | 0.817 | 0.929 |
| ccd | 0.636 | 1.063 | 0.954 |
| ccsd | 0.880 | 0.852 | 0.933 |
| adc2 | 0.621 | 1.019 | 1.001 |
| eom_ccsd (held-out) | 1.137 | 1.303 | not modeled |

The model predicted parity or small wins; the measurements disagree in both directions — larger wins at one thread, two cells inverted at sixteen — and held-out eom_ccsd loses at both thread counts. All of it recorded as-is: no tuning the model against these numbers. (Load was climbing through the batch, so the late cells carry the most uncertainty; per-run loads are on record.) One quiet satisfaction: adc2, the exact tie in the symbolic table, wins 38% on wall time at one thread.

---

*Written with AI assistance from the original conversations and saved session records. Quotes are verbatim from session logs; `[…]` marks omissions. The compiler project is ongoing. The raw sessions, credentials, and private repositories are not published.*
