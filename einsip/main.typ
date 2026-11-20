#import "@preview/touying:0.6.1": *
#import "@preview/touying-simpl-hkustgz:0.1.2": *

#show: hkustgz-theme.with(
  font: "Libertinus Serif",
  config-common(new-section-slide-fn: none),
  config-info(
    title: [The Algorithm Einsip Discovered],
    subtitle: [Exact intermediate selection for tensor expressions],
    author: [Longli Zheng],
    date: datetime(year: 2026, month: 11, day: 20),
    institution: [HKUST(GZ)],
  ),
)

#title-slide()

= The Problem

== From operators to code

#set text(size: 0.8em)
#show math.equation.where(block: true): set block(above: 0.4em, below: 0.4em)

#grid(
  columns: (auto, 1fr),
  align: (left + horizon, left),
  column-gutter: 18pt,
  row-gutter: 8pt,
  [*Operators:*],
  [
    $ H = f_(p q) a^dagger_p a_q + 1/4 ⟨p q || r s⟩ a^dagger_p a^dagger_q a_s a_r $
    $ |Psi⟩ = e^(T_2) |Phi_0⟩, quad T_2 = 1/4 t_(i j)^(a b) a^dagger_a a^dagger_b a_j a_i, quad ⟨Phi_(i j)^(a b) | H e^(T_2) | Phi_0⟩_C = 0 $
  ],
  [$arrow.b$], [],
  [*Tensor expressions:*],
  [
    $ r_(i j)^(a b) = v_(i j)^(a b)
      + 1/2 v_(c d)^(a b) t_(i j)^(c d)
      + 1/2 v_(i j)^(k l) t_(k l)^(a b)
      + P(i j) P(a b) v_(c j)^(k b) t_(i k)^(a c) $
    $ quad + 1/4 v_(c d)^(k l) t_(i j)^(c d) t_(k l)^(a b)
      + P(i j) P(a b) v_(c d)^(k l) t_(i k)^(a c) t_(j l)^(b d)
      - 1/2 P(a b) v_(c d)^(k l) t_(i j)^(a c) t_(k l)^(b d)
      - 1/2 P(i j) v_(c d)^(k l) t_(i k)^(c d) t_(l j)^(a b) $
  ],
  [$arrow.b$], [],
  [*Code:*],
  [
```python
r  = v["abij"]
r += 0.5 * einsum("cdab,ijcd->ijab", v, t)
r += 0.5 * einsum("klij,klab->ijab", v, t)
# + P·P linear term + 4 quadratic terms
```
  ],
)

= Features of the Problem

== Feature 1: scale

#slide(composer: (1fr, 1fr))[
  #figure(
    table(
      columns: 3,
      align: (left, right, right),
      inset: 7pt,
      [*instance*], [$n$ terms], [$k$ max],
      [mp3], [6], [5],
      [ccd], [19], [3],
      [adc2], [19], [3],
      [ccsd\_t], [54], [5],
      [ccsd], [80], [5],
      [ccsd\_lambda], [114], [5],
      [eom\_ccsd], [147], [5],
    ),
  )
  #text(size: 0.8em)[counted after flattening, all outputs]
][ 
  $n$: number of terms in the tensor expressions
  #v(0.5em)
  $k$: max number of tensors in one term
  #v(1.5em)
  #align(center)[*$k$ is bounded, $n$ grows fast*]
]

== Feature 2: find sharing

// Demo: two CCD terms sharing t_ij^cd. The optimization direction:
// a shared intermediate + a shared contraction.
#slide(composer: (1fr, 1.15fr))[
  *as written*
  ```python
  r += 0.5  * einsum("cdab,ijcd->ijab",
                     v, t)
  r += 0.25 * einsum("cdkl,ijcd,klab->ijab",
                     v, t, t)
  ```
  #align(center)[$O^2 V^4 + O^4 V^4$]
][
  *with sharing*
  ```python
  X = einsum("cdkl,klab->cdab", v, t)
  W = 0.5 * v + 0.25 * X
  r += einsum("ijcd,cdab->ijab", t, W)
  ```
  #align(center)[$approx 3 O^2 V^4$]
][
  #grid.cell(colspan: 2)[
    #v(1em)
    #align(center)[
      $O^4 V^4 + O^2 V^4 arrow.long 3 O^2 V^4$ — $approx O^2 times$ fewer FLOPs
    ]
  ]
]

= The ILP Formulation

== One integer program, not a pipeline of heuristics

Pipeline: flatten $->$ orbits (drop cancellations) $->$ candidate
universe $->$ covers, families, clusters $->$ *one ILP*.

// TODO: check depth — this table is the variable-class list from optimize.rs
#figure(
  table(
    columns: 3,
    align: (left, left, left),
    [*variable*], [*meaning*], [*per*],
    $x_s$, [materialize], [candidate intermediate $s$],
    $y_(s,c)$, [formation], [cover $c$ of $s$],
    $z_(t,c)$, [term cover], [term $t$],
    $h_gamma$, [cofactor family], [shared sum $gamma$],
    $s_sigma$, [shared S-sum], [signature $sigma$],
    $r_(gamma,t,c)$, [rest cover], [family member],
    $w_C$, [orbit cluster], [cluster $C$ (negative cost)],
  ),
)

== Exactness as the guard rail

- Every objective coefficient is an exact per-operation price, computed
  before the solve (contractions via an exact tree DP).
- *Storage* — exact output bytes — is the one constraint: the resource
  a fast-but-wrong objective can silently blow through.
- Cost models are swappable hypotheses (`CostModel` trait): FLOPs for
  accounting, a calibrated roofline model for the machine.
- The solver is exact $=>$ a tie with the baseline is a *proof*: within
  the encoded space, nothing cheaper exists.

= Benchmarks

== Benchmarks

// TODO: real numbers — symbolic FLOPs table and/or wall-time table.
// Candidate format (from the corpus, O = occupied, V = virtual):

#figure(
  table(
    columns: 4,
    align: (left, left, left, center),
    [*instance*], [*baseline FLOPs*], [*einsip FLOPs*], [*verified*],
    [TODO mp3], $4 O^4 V^2 + 3 O^3 V^3 + 3 O^2 V^4$, $2 O^4 V^2 + 2 O^3 V^3 + 2 O^2 V^4$, sym.checkmark,
    [TODO ccsd], $8 O^4 V^2 + 8 O^3 V^3 + 2 O^2 V^4$, $6 O^4 V^2 + 8 O^3 V^3 + 2 O^2 V^4$, sym.checkmark,
    [TODO ccsd\_t], $19 O^4 V^3 + 20 O^3 V^4$, $4 O^4 V^3 + 4 O^3 V^4$, sym.checkmark,
  ),
  caption: [TODO: sizes, solver runtimes, held-out instances.],
)

== Verification

- Symbolic checks, level by level, on the lowered plan.
- A numerical oracle: a naive dense executor, independent of the
  backend — the plan must reproduce the reference elementwise.
- TODO: how the audience can reproduce.

== Takeaway

#tblock(title: [Takeaway])[
  TODO: the one sentence the audience should remember.
  // Draft: When the whole space of schedules is one exact integer
  // program, "the best schedule" stops being a search and becomes a
  // proof.
]
