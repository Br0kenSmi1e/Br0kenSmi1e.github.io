#import "@preview/touying:0.6.1": *
#import "@preview/touying-simpl-hkustgz:0.1.2": *
#import "@preview/cetz:0.3.4": canvas, draw

#show: hkustgz-theme.with(
  font: "Libertinus Serif",
  config-common(new-section-slide-fn: none),
  config-info(
    title: [Intermediate selection via integer programming],
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

== Feature 1: find sharing

// Demo: two CCD terms share the piece M_ij^kl = v_cd^kl t_ij^cd.
// Term 5 reads it straight; term 8 reads it with k hooked back to t.
// Figure adapted from einsip/docs/fig/typ/ccd.typ.
#slide[
  #align(center + horizon)[
  #align(center)[
  #canvas(length: 1.15cm, {
    import draw: *

    let ink = rgb("#1a1a1a")
    let vir = rgb("#1d4ed8")
    let dim = rgb("#6b7280")
    let B = 0.58
    let GL = 0.40

    let nrm(side) = if side == "l" { (-1, 0) } else if side == "r" { (1, 0) } else if side == "u" { (0, 1) } else { (0, -1) }
    let tan(side) = if side == "l" or side == "r" { (0, 1) } else { (1, 0) }
    let at(p, v, k) = (p.at(0) + v.at(0)*k, p.at(1) + v.at(1)*k)

    let ten(p, lab, paint: ink) = {
      rect((p.at(0) - B/2, p.at(1) - B/2), (p.at(0) + B/2, p.at(1) + B/2), radius: 0.06,
           stroke: (paint: paint, thickness: 1.0pt), fill: white)
      content(p, text(style: "italic", size: 12pt, fill: paint)[#lab])
    }
    let lab(p, s, paint: ink) = content(p, anchor: "center",
      text(size: 9.5pt, style: "italic", fill: paint)[#s])

    // a free leg: a short straight stub, labelled at its end
    let leg(p, side, s, paint: ink) = {
      let a = at(p, nrm(side), B/2)
      let b = at(p, nrm(side), B/2 + GL)
      line(a, b, stroke: (paint: paint, thickness: 0.9pt))
      if s != none {
        let n = nrm(side)
        let lp = (b.at(0) + (if n.at(0) == 0 { 0 } else { n.at(0)*0.15 }),
                  b.at(1) + (if n.at(1) == 0 { 0 } else { n.at(1)*0.15 }))
        lab(lp, s, paint: paint)
      }
    }

    // a wire: leaves and enters perpendicular to its side; lo nudges the label
    let wire(a, sa, b, sb, s, paint: ink, m: 0.62, oa: 0, ob: 0, lo: (0, 0.16)) = {
      let s0 = at(at(a, tan(sa), oa), nrm(sa), B/2)
      let e0 = at(at(b, tan(sb), ob), nrm(sb), B/2)
      let c1 = at(s0, nrm(sa), m)
      let c2 = at(e0, nrm(sb), m)
      bezier(s0, e0, c1, c2, stroke: (paint: paint, thickness: 0.9pt))
      if s != none {
        let mid = ( (s0.at(0) + 3*c1.at(0) + 3*c2.at(0) + e0.at(0))/8,
                    (s0.at(1) + 3*c1.at(1) + 3*c2.at(1) + e0.at(1))/8 )
        lab((mid.at(0) + lo.at(0), mid.at(1) + lo.at(1)), s, paint: paint)
      }
    }

    // the shared core: t raised, v lowered; c leaves t right, d leaves t bottom
    let core(x, y, j_lab) = {
      let tp = (x, y + 0.40)
      let vp = (x + 2.30, y - 0.40)
      ten(tp, [t], paint: vir)
      ten(vp, [v], paint: vir)
      wire(tp, "r", vp, "u", $c$, paint: vir, m: 0.55, oa: 0.08)
      wire(tp, "d", vp, "l", $d$, paint: vir, m: 0.55, oa: -0.06)
      leg(tp, "u", $i$)
      leg(tp, "l", j_lab)
    }

    // term 5
    let yA = 7.10
    core(1.75, yA, $j$)
    let vA = (1.75 + 2.30, yA - 0.40)
    let t3 = (4.30, yA - 2.35)
    ten(t3, [t])
    wire(vA, "r", t3, "r", $k$, m: 0.85, lo: (0.16, 0.14))
    wire(vA, "d", t3, "u", $l$, m: 0.55, lo: (-0.24, 0))
    leg(t3, "l", $a$)
    leg(t3, "d", $b$)
    rect((1.20, yA - 1.25), (4.70, yA + 1.05), radius: 0.14,
         fill: vir.transparentize(95%), stroke: (paint: vir, thickness: 0.9pt, dash: "dashed"))

    // term 8
    let yB = 3.10
    core(1.75, yB, none)
    let vB = (1.75 + 2.30, yB - 0.40)
    let t4 = (6.10, yB - 0.40)
    ten(t4, [t])
    wire(vB, "r", t4, "l", $l$, m: 0.60, lo: (0, 0.18))
    // k: t's left leg and v's bottom leg leave the box and join outside
    line((1.75 - B/2, yB + 0.40), (0.92, yB + 0.40), stroke: (paint: ink, thickness: 0.9pt))
    line((vB.at(0), vB.at(1) - B/2), (vB.at(0), yB - 1.55), stroke: (paint: ink, thickness: 0.9pt))
    bezier((0.92, yB + 0.40), (0.78, yB - 0.80), (0.55, yB + 0.40), (0.78, yB + 0.20),
           stroke: (paint: ink, thickness: 0.9pt))
    bezier((0.78, yB - 0.80), (vB.at(0), yB - 1.55), (0.78, yB - 1.70), (vB.at(0), yB - 2.15),
           stroke: (paint: ink, thickness: 0.9pt))
    lab((2.40, yB - 2.05), $k$)
    leg(t4, "u", $j$)
    leg(t4, "r", $a$)
    leg(t4, "d", $b$)
    rect((1.20, yB - 1.25), (4.70, yB + 1.05), radius: 0.14,
         fill: vir.transparentize(95%), stroke: (paint: vir, thickness: 0.9pt, dash: "dashed"))

    // legend
    let ly = 0.35
    rect((0.60, ly - 0.34), (2.90, ly + 0.34), radius: 0.10,
         fill: vir.transparentize(95%), stroke: (paint: vir, thickness: 0.9pt, dash: "dashed"))
    content((1.75, ly), text(size: 9.5pt, fill: vir)[the boxed piece])
    content((3.25, ly), text(size: 13pt, fill: dim)[$=$])
    ten((4.45, ly), [$M$], paint: vir)
    leg((4.45, ly), "u", $i$, paint: dim)
    leg((4.45, ly), "l", $j$, paint: dim)
    leg((4.45, ly), "r", $k$, paint: dim)
    leg((4.45, ly), "d", $l$, paint: dim)
    content((5.75, ly), anchor: "west", text(size: 10pt, fill: ink)[computed once, read twice])
  })
  ]
  #v(1em)
  #align(center)[
    $2 O^4 V^4 arrow.long 3 O^4 V^2$ — one shared piece, $approx V^2 times$ fewer FLOPs
  ]
  ]
]

== Feature 2: scale

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

= The ILP Formulation

== Collect the shares

// Block from einsip/docs/fig/typ/dict-slide.typ (sizes bumped for projection).
#align(center + horizon)[
#block(width: 21cm)[
  #set text(size: 11pt)
  #let dim = rgb("#6b7280")
  #let rule = rgb("#d1d5db")
  #let id(t) = text(style: "italic", t)
  #let kw(t) = text(weight: "bold", t)
  #let com(t) = text(style: "italic", fill: dim, size: 10pt, [— #t])

  #text(size: 12pt)[#text(weight: "bold")[Algorithm 1] #h(0.5em) #text(style: "italic", fill: dim)[collect the shares]]

  #v(0.5em)
  #grid(columns: (auto, 1fr), align: (right, left), column-gutter: 1.2em, row-gutter: 0.35em,
    text(weight: "bold", size: 10pt)[in],  [a problem: its terms, and a canonicaliser #id[canon]],
    text(weight: "bold", size: 10pt)[out], [the #id[shares] : signature #sym.arrow.r occurrences],
  )

  #v(0.5em)
  #rect(width: 100%, height: 0.4pt, fill: rule)
  #v(0.6em)

  #grid(columns: (auto, 1fr), align: (right, left), column-gutter: 1.2em, row-gutter: 0.45em,
    text(fill: dim, size: 10pt)[1],  [#id[reps] #h(0.35em)#sym.arrow.l#h(0.35em) #id[orbits]#text[(terms)] #h(0.8em)#com[grouped by #id[canon] of the whole term]],
    text(fill: dim, size: 10pt)[2],  [#id[D] #h(0.35em)#sym.arrow.l#h(0.35em) $emptyset$ #h(1.2em)#com[signature #sym.arrow.r record]],
    text(fill: dim, size: 10pt)[3],  [#id[E] #h(0.35em)#sym.arrow.l#h(0.35em) $emptyset$ #h(1.2em)#com[term #sym.arrow.r its occurrences]],
    text(fill: dim, size: 10pt)[4],  [#kw[for] $r$ #kw[in] #id[reps]],
    text(fill: dim, size: 10pt)[5],  [#h(1.1em)#kw[for] $k = 2, dots, |r|$ #h(0.8em)#com[over its factors]],
    text(fill: dim, size: 10pt)[6],  [#h(2.2em)#kw[for] $S subset.eq r$ #kw[with] $|S| = k$],
    text(fill: dim, size: 10pt)[7],  [#h(3.3em)$(sigma, s) arrow.l italic("canon")(S)$ #h(0.8em)#com[normal form, sign]],
    text(fill: dim, size: 10pt)[8],  [#h(3.3em)#kw[if] $sigma = 0$ #kw[then skip] #h(0.8em)#com[structurally zero]],
    text(fill: dim, size: 10pt)[9],  [#h(3.3em)$italic("D")[sigma] arrow.l S$ #h(0.8em)#com[only the first time]],
    text(fill: dim, size: 10pt)[10], [#h(3.3em)$italic("E")[r] arrow.l italic("E")[r] union {(sigma, S, s)}$],
    text(fill: dim, size: 10pt)[11], [#id[shares] #h(0.35em)#sym.arrow.l#h(0.35em) $sigma arrow.r.long {(r, S, s) in italic("E")}$ #h(0.8em)#com[invert]],
    text(fill: dim, size: 10pt)[12], [#kw[for] $sigma$ #kw[in] #id[shares]],
    text(fill: dim, size: 10pt)[13], [#h(1.1em)$italic("roots")[sigma] arrow.l |{r : (r, dot, dot) in italic("shares")[sigma]}|$],
    text(fill: dim, size: 10pt)[14], [#h(1.1em)$italic("uses")[sigma] arrow.l |italic("shares")[sigma]|$],
    text(fill: dim, size: 10pt)[15], [#kw[return] #id[shares]],
  )

  #v(0.7em)
  #text(size: 10pt, style: "italic", fill: dim)[
    A record is written once, the first time its signature is seen. #text(style: "normal")[#id[shares]] is the inversion of #text(style: "normal")[#id[E]].
  ]
]
]

== One integer program

// Block from einsip/docs/fig/typ/model-slide.typ.
#align(center + horizon)[
#block[
  #set text(size: 11.5pt)
  #show math.equation: set text(size: 11.5pt)
  #let dim = rgb("#6b7280")
  #let rule = rgb("#d1d5db")
  #let section(t) = table.cell(colspan: 3, text(weight: "medium", size: 12.5pt)[#t])

  #table(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    inset: (x: 0.5em, y: 0.34em),
    stroke: (_, y) => if y <= 2 { none } else { (top: 0.35pt + rule) },

    [ ], [ ], [ ],
    [ ], [ ], [ ],
    section[Variables],
    [ ], [$x(v, rho) in {0,1}$], [value $v$ is built by recipe $rho$],
    [ ], [$e(v) in {0,1}$], [optional value $v$ is built at all],

    section[Constraints],
    [$(R 1)$], [$sum_rho x(v, rho) = 1$], [for every required value],
    [$(R 3)$], [$sum_rho x(v, rho) = e(v)$], [for every optional value],
    [$(R 2)$], [$x(v, rho) <= e(u)$], [for every $u$ that $rho$ reads, when $u$ is optional],
    [$(B)$], [$sum_v "bytes"(v) thin e(v) <= B$], [once, if a budget is given],

    section[Objective],
    [ ], [$min sum_(v, rho) p(v, rho) thin x(v, rho)$], [each price $p(v, rho)$ is exact, fixed before the solve],
  )

  #v(0.7em)
  #text(size: 10pt, fill: dim)[
    $x$ is the only thing the solver moves: one 0/1 per recipe $rho$. $e$ is not independent — $(R 3)$ ties it to the recipes, and existence itself is free; only operations cost.
  ]
  #v(0.4em)
  #text(size: 10pt, fill: dim)[For ccsd: 450 values and 1261 recipes, so 1663 binaries.]
]
]

== What sums add

// Block from einsip/docs/fig/typ/sums-slide.typ.
#align(center + horizon)[
#block[
  #set text(size: 10.5pt)
  #show math.equation: set text(size: 10.5pt)
  #let dim = rgb("#6b7280")
  #let rule = rgb("#d1d5db")
  #let section(t) = table.cell(colspan: 4, text(weight: "medium", size: 11.5pt)[#t])

  #table(
    columns: (auto, auto, auto, 1fr),
    align: (left, left, left, left),
    inset: (x: 0.42em, y: 0.3em),
    stroke: (_, y) => if y == 0 { none } else { (top: 0.35pt + rule) },

    section[New values],
    [ ], [$R_m$], [rest of member $m$], [optional],
    [ ], [$U_sigma$], [the sum over members], [optional, one recipe],
    [ ], [$T_sigma$], [$sigma times U_sigma$], [optional, one recipe],

    section[New variable],
    [ ], [$j(U, t) in {0,1}$], [term $t$ of sum $U$ takes part], [one per optional term],

    section[New constraints],
    [$(R 4)$], [$j(U, t) <= x(U, rho)$], [no joining a sum nobody builds], [each optional term],
    [ ], [$j(U, t) <= e(R_t)$], [its rest must exist too], [each optional term],
    [ ], [$x(U, rho) <= sum_t j(U, t)$], [a sum is never empty], [sums with no fixed term],
    [(link)], [$x(m, "yield") = j(U, m)$], [a member yields iff it joins], [each member],
    [(consume)], [$x(c, rho) = e(U)$], [reading a sum forces it to exist], [each consumer],

    section[Objective],
    [ ], [$+ sum_(U, t) q(U, t) thin j(U, t)$], [the marginal price of adding term $t$], [ ],
  )

  #v(0.5em)
  #text(size: 9.5pt, fill: dim)[
    $(R 4)$ is what a sum needs beyond a contraction: a term is optional, but the sum is only as full as the terms that joined. The link is the one rule with a meaning — if a member joins, its contribution comes from the yield, and not also from its own value.
  ]
  #v(0.3em)
  #text(size: 9.5pt, fill: dim)[For ccd_t2: 6 families turn 44 values and 74 recipes into 117 binaries; the objective falls from 2.1509e21 to 2.1007e21.]
]
]

= Benchmarks

== Against gristmill

// Blocks from einsip/docs/fig/typ/flops-slide.typ and time-slide.typ.
#slide(composer: (1.25fr, 1fr))[
  #align(center + horizon)[
  #block[
    #set text(size: 10.5pt)
    #show math.equation: set text(size: 10.5pt)
    #let dim = rgb("#6b7280")
    #let rule = rgb("#d1d5db")
    #let row(name, a, b) = (
      text(style: "italic")[#name],
      a,
      b,
    )

    *symbolic FLOPs*
    #v(0.3em)
    #table(
      columns: (auto, 1fr, 1fr),
      align: (left, left, left),
      inset: (x: 0.45em, y: 0.42em),
      stroke: (_, y) => if y == 0 { none } else { (top: 0.35pt + rule) },
      [ ], [gristmill], [this work],
      ..row([mp3],         [$4 O^4 V^2 + 3 O^3 V^3 + 3 O^2 V^4$], [$2 O^4 V^2 + 2 O^3 V^3 + 2 O^2 V^4$]),
      ..row([ccd],         [$4 O^4 V^2 + 6 O^3 V^3 + 2 O^2 V^4$], [$4 O^4 V^2 + 6 O^3 V^3 + 2 O^2 V^4$]),
      ..row([adc2],        [$16 O^3 V^2 + 6 O^2 V^3$], [$16 O^3 V^2 + 6 O^2 V^3$]),
      ..row([ccsd_t],      [$19 O^4 V^3 + 17 O^3 V^4$], [$4 O^4 V^3 + 4 O^3 V^4$]),
      ..row([ccsd],        [$8 O^4 V^2 + 8 O^3 V^3 + 2 O^2 V^4$], [$6 O^4 V^2 + 8 O^3 V^3 + 2 O^2 V^4$]),
      ..row([ccsd_lambda], [$12 O^4 V^2 + 6 O^3 V^3 + 2 O^2 V^4$], [$10 O^4 V^2 + 4 O^3 V^3 + 2 O^2 V^4$]),
      ..row([eom_ccsd],    [$18 O^4 V^2 + 10 O^3 V^3 + 2 O^2 V^4$], [$16 O^4 V^2 + 10 O^3 V^3 + 2 O^2 V^4$]),
    )

    #v(0.6em)
    #text(size: 8.5pt, fill: dim)[
      Highest-order part of the exact polynomial in the domain sizes: $O$ occupied, $V$ virtual. Both sides are costed in one convention, so the coefficients are comparable term by term.
    ]
  ]
  ]
][
  #align(center + horizon)[
  #block[
    #set text(size: 10.5pt)
    #show math.equation: set text(size: 10.5pt)
    #let dim = rgb("#6b7280")
    #let rule = rgb("#d1d5db")
    #let r(name, g, b, s, t, sp) = (
      text(style: "italic")[#name], g, b, s, text(weight: "medium")[#t], sp,
    )

    *optimiser wall time*
    #v(0.3em)
    #table(
      columns: (auto, auto, auto, auto, auto, auto),
      align: (left, right, right, right, right, right),
      inset: (x: 0.55em, y: 0.30em),
      stroke: (_, y) => if y == 0 { none } else { (top: 0.35pt + rule) },
      [ ], [gristmill], [build], [solve], [total], [speed-up],
      ..r([mp3], [0.82], [0.06], [0.02], [0.08], [11#text(size: 8pt)[×]]),
      ..r([ccd], [0.73], [0.06], [0.01], [0.06], [12#text(size: 8pt)[×]]),
      ..r([adc2], [1.14], [0.01], [0.01], [0.01], [85#text(size: 8pt)[×]]),
      ..r([ccsd_t], [7.80], [1.88], [0.19], [2.07], [3.8#text(size: 8pt)[×]]),
      ..r([ccsd], [1.74], [0.19], [0.04], [0.23], [7.7#text(size: 8pt)[×]]),
      ..r([ccsd_lambda], [2.00], [0.37], [0.12], [0.49], [4.1#text(size: 8pt)[×]]),
      ..r([eom_ccsd], [3.22], [0.42], [0.10], [0.52], [6.2#text(size: 8pt)[×]]),
    )

    #v(0.6em)
    #text(size: 8.5pt, fill: dim)[
      Optimiser wall time in seconds, not the cost of the expression it produces. gristmill's figure is its own harness's $"wall"_"seconds"$; ours is read, parse, build, then solve, median of five runs on an Apple M3, one thread.
    ]
  ]
  ]
]
