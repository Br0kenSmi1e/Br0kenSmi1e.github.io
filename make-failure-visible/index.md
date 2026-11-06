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

This gives the two things wall time never had. A schedule's cost is an operation count — computed exactly, never measured. A ground truth. And the solver's answer is the provable best in the space — no greedy loop, no search luck left to blame.

The goal became a checkable sentence: *verify, and strictly beat the baseline on every training problem.* The baseline — an existing optimizer's schedule for the same equations — is itself a point inside that space. So when the provable best still ties or trails, the solver has not failed: it has proved the space is missing a class of schedules. The failure arrives with its cause already named.

## What failure looks like now

Bugs arrive with addresses. When the verifier rejected one schedule, the agent bisected a 63-term equation down to four specific terms — {32, 33, 37, 42} — before any human looked at the failure. The fix followed from the mechanism, not from a lucky guess.

Gaps arrive with proofs. On one problem (adc2), the solver tied the baseline exactly — and because the solver is exact, the tie is a proof: within the space we had encoded, nothing better exists. That is not a dead end. It is the most useful sentence in the project, because it says precisely where to dig next.

Wins arrive checkable. Verified operation counts against the baseline: 0.656×, 0.992×, 0.935×, and the exact tie. Measured wall time on the release build, single-threaded: 0.62× to 0.88× of the baseline on the four training problems. And on held-out problems the agent had never seen during development: one beats the baseline, one wins large on operation count, one *loses* on wall time — recorded in the same file, by the same rules, not tuned away.

## One data point

I used to frame all of this as "make wrongness visible." After this round I would say it wider: make *failure* visible — where failure means any verified distance from the goal. A bug is a failure whose coordinates point at code. A gap is a failure whose coordinates point at the space. The agent could always check whether its answers were correct; what changed is that falling short became explainable.

My last post ended by asking how to get an agent to question its chosen approach. One project is one data point, and I would rather report it than generalize from it: the agent questioned its conclusions exactly when its failures arrived with coordinates — and when the environment could not attach coordinates, the productive move was to change the problem until it could.

---

*Written with AI assistance from the original conversations and saved session records. Quotes are verbatim from session logs; `[…]` marks omissions. The compiler project is ongoing. The raw sessions, credentials, and private repositories are not published.*
