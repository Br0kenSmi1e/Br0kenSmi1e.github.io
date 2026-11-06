# Contraction-order investigation

Find an algorithmic way to reduce total dense contraction work. No intermediate-space penalty, read/write weighting, slicing, or numerical tensor approximation. An implementation speedup alone is not the objective. Develop and test ideas.

## Available evidence

- `omeco/src/`: frozen Rust implementation, including TreeSA and exact-search code.
- `omeco/examples/research_bitmap.rs`: accelerated TreeSA implementation, available as a control—not a preferred direction. Other examples are baseline implementation context, not instructions.
- `benchmarks/graphs/`: five development instances: chain, two grids, and two regular graphs. They are not a holdout or a representative application distribution. `reg3_220.json` is additionally included because the library's unit-test source embeds it; it is not required as a development benchmark. Small counterexamples and additional synthetic cases may be generated locally.
- `literature/`: full primary papers by Pfeifer–Haegeman–Verstraete (optimal contraction sequences), Gray–Kourtis (hyper-optimized contraction), and Stoian et al. (linear orders). Text extraction may damage formulas; PDFs are also supplied. This packet is deliberately incomplete.

## Working environment

A fresh local Git repository contains this packet, with no earlier experiment results or conversation history. Standard-library Python and Rust (`cargo ... --offline`) with the existing package cache are available. Do not install dependencies or access the network. Work only within this repository; do not inspect sibling runs or historical research repositories. New code and experimental artifacts belong in `./.worktrees/<experiment-name>/`.

A supervisor will end execution at the time limit supplied in the user message.
