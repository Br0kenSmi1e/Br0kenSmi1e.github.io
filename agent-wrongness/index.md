# How do you know your agent is wrong?

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

## Numbers don't carry their own validity

Once I saw this, I found its consequences everywhere in the compiler project's records.

A schedule had been timed and showed a win. The timing run had no idea the schedule was numerically wrong — correctness lived in a *different command*, and the intersection was checked by nobody. The win looked exactly like a real win.

The same baseline was measured in two honest, protocol-compliant sessions: 58.7 ms and 67.9 ms. Fifteen percent apart, nothing flagged it, and two downstream conclusions silently depended on which number was right. There was no way to adjudicate — there is no ground truth for wall time, only measurements of it.

And a headline comparison rested on measurements with too-few iterations and a 3.4× spread between repeats of the *same candidate* — visible right there in the file, for weeks. Nobody was assigned to look.

In the STM project, a wrong answer came with its location and size. In the compiler project, wrongness lived at *intersections* — timing ∩ correctness, session ∩ session, claim ∩ fine print — and intersections only get checked when someone with judgment decides to look.

## What would make wrongness visible?

Debugging is my mental model. Programming environments make wrongness visible in four ways; agent research environments usually ship with none:

**Detectable.** A failing build produces a signal. A silently-wrong number does not. Most agent loops emit rewards, not alarms.

**Diagnosable.** A stack trace says *where*. A bare "test failed" does not. This is the difference between a per-fixture residual and a single wall-time scalar — between getting the "why" with the failure and manufacturing it yourself, one "perhaps" at a time.

**Expensive to ignore.** A compiler warning gets ignored; a compiler error blocks the build. This is the property people underestimate. Disclosure without enforcement is a warning, and warnings get ignored. In the STM project, the scoring priced a confident wrong answer at ten times a refusal. As that agent put it: *a refusal is a delay; a lie is fake science.*

**Remembered.** A bug fixed without a postmortem recurs. An agent session that ends forgets. The STM project froze every failure into a permanent regression test; the compiler project re-derived the same lessons across context resets.

The STM project got all four from its environment, for free, because ground truth was available. The compiler project has no ground truth. So the question becomes: can these four properties be built by hand, into an environment that doesn't provide them?

I don't know. We're trying — the current attempt moves the workflow into versioned files, installs a run-once exam and a critic whose challenges block progress, and prices confident wrong answers above honest refusals. It's too early to say whether it works. What I can say is that the attempt has already changed what I watch: less the agent's outputs, more whether its failures arrive with their coordinates attached.

My last post ended by asking how to get an agent to question its chosen approach. I suspect this is the same question in disguise. An agent questions its conclusions exactly when wrongness is detectable, diagnosable, expensive, and remembered — and not before. Making that true, in domains without ground truth, is the problem we're working on now.

*Written with AI assistance from the original conversations and saved session records. Quotes are verbatim from session logs; `[…]` marks omissions. The compiler project is unfinished. The raw sessions, credentials, and private repositories are not published.*
