# Supporting materials

These are selected, public-safe materials supporting the tuning story. The identity-demo files are retained from earlier blog versions; that inconclusive detour is no longer part of the article. They are not a complete reproducibility package or an independently scored benchmark.

## Historical research prompt

[research-system-prompt.txt](research-system-prompt.txt) is the installed `.pi/SYSTEM.md` from the research workspace at local commit `f536236bc5e8cfeef700a6cae90b895bbee1fe62` (22 September 2026). It is byte-identical to that snapshot. It does not contain the stronger checkpoint/continuation wording subsequently proposed in the conversation. The identity-demo system bodies below are separate experimental variants, not this production prompt.

## Identity-demo input texts

The role prefix was one of `You are a coding agent.`, `You are an algorithm researcher.`, or absent. Two line breaks separated a nonempty prefix from the common body.

| Input | With research guidelines | Without research guidelines |
|---|---|---|
| System body | [with-guidelines.txt](with-guidelines.txt) | [without-guidelines.txt](without-guidelines.txt) |
| User request | [request-with-guidelines.txt](request-with-guidelines.txt) | [request-without-guidelines.txt](request-without-guidelines.txt) |
| Task context | [context-with-guidelines.md](context-with-guidelines.md) | [context-without-guidelines.md](context-without-guidelines.md) |
| Initial notebook | [initial-notebook.md](initial-notebook.md) | Same |

The source code, graphs, and literature packet were identical across the two versions. The task context changed to remove embedded research-process guidance. Filesystem/network boundaries, resource limits, and worktree placement remained. These controls are instructions and local process supervision, not an operating-system sandbox.

## Outcome metadata

[runs.json](runs.json) contains all scheduled conditions across four batches, including not-started conditions, the extra completed run in an interrupted batch, and both connection failures. `included_in_six_run_table` identifies the two complete batches used in the first blog version's table; the current article omits this demo. Timing includes cleanup overhead. `notebook_changed` is a byte comparison against the initial notebook; it does not score usefulness. Tool calls count invocations, not experiments.

The earlier blog versions' qualitative observations came from transcript inspection; no independent research-quality scoring was completed. Source sessions, authentication files, provider account details, complete workspaces, and private evaluations are deliberately omitted. The public export therefore does not let a reader independently validate every algorithmic observation.

## Limits

One run per condition per complete batch; gpt-6-astra / openai-codex / low; five-minute caps; sequential randomized order within each batch. The guided and unguided batches were not interleaved. The notebook and timing observations should not be read as a causal estimate of the effect of guidelines or identity.
