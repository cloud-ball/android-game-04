# Ball physics for a game-grade, deterministic 2.5D pool solver (Cue Club / shared/cue_sim)

Research date: 2026-11-13. Repo context: `docs/games/pool.md` and `.claude/rules/cue-sim.md` (defaults mu_slide 0.2, mu_roll 0.012, e_ball 0.93, mu_ball 0.055, e_cushion 0.85; fixed 1/240 s substeps; swept-circle TOI). Symbols: R is ball radius, m is mass, g = 9.81 m/s², I = 2/5 m R², u is the contact-point slip velocity (ball on cloth), and φ is the cut angle. Numbers marked "computed" were worked out by the researcher from the cited formulas, using R = 0.028575 m and m = 0.170097 kg.

> **Possible bug in the repo docs.** `docs/games/pool.md` lists "Rolling deceleration = 5/7 · μr · g". In both Alciatore's and pooltool's conventions the rolling deceleration is **μr · g**, with no 5/7 factor (see Q1 and Q2). With μr = 0.012 the repo formula gives 0.084 m/s². The documented convention gives 0.118 m/s², and Mathavan measured 0.124–0.126 m/s². Pick one convention and record it in cue-sim.md before the golden master is frozen.

## Q1. Motion phases (sliding, rolling, spinning) and their analytic equations; event-based vs fixed-step integration

### Takeaway
Ball-on-cloth motion has four phases (sliding, rolling, spinning, stationary). Each has closed-form, piecewise-polynomial equations. Position is at most quadratic in t, and the transition times are simple ratios. In the sliding phase the friction direction is constant, so the acceleration is a constant vector and the path is an exact parabola. That makes "analytic per-substep" updates cheap and exact. Split a substep wherever a phase transition falls inside it.

### Cited Findings
- **Sliding phase** (u ≠ 0). û₀ is the initial slip direction. u(t) = (u₀ − 7/2 μs g t) û₀; v(t) = v₀ − μs g t û₀; r(t) = r₀ + v₀t − ½ μs g t² û₀; ω_xy(t) = ω₀,xy − (5 μs g / 2R) t (k̂ × û₀); ω_z(t) = ω₀z − (5 μsp g / 2R) t. Valid for 0 ≤ t ≤ (2/7) u₀/(μs g). Sliding produces curved paths because friction has a component perpendicular to the motion. — [Kiefl, "The physics of pool/billiards" (pooltool theory), 2020-04-24](https://ekiefl.github.io/2020/04/24/pooltool-theory/)
- **Rolling phase** (u = 0): v(t) = v₀ − μr g t v̂₀; r(t) = r₀ + v₀t − ½ μr g t² v̂₀; in-plane spin locked to |v|/R; ω_z decays as above. Valid for 0 ≤ t ≤ |v₀|/(μr g). — [Kiefl 2020](https://ekiefl.github.io/2020/04/24/pooltool-theory/)
- **Spinning phase** (v = 0, ω_z ≠ 0): ω_z(t) = ω₀z − (5 μsp g / 2R) t, valid until t = 2R ω₀z/(5 μsp g). After that the ball is stationary. If the spin dies before rolling ends, ω_z stays 0. — [Kiefl 2020](https://ekiefl.github.io/2020/04/24/pooltool-theory/)
- **Transition times**: sliding→rolling Δt = (2/7) u₀/(μs g); rolling→stationary or spinning Δt = v₀/(μr g); spinning→stationary Δt = 2R ω₀z/(5 μsp g). Sliding→stationary and sliding→spinning are "very rare" and are treated as two transitions in sequence. — [Kiefl, "pooltool algorithm", 2020-12-20](https://ekiefl.github.io/2020/12/20/pooltool-alg/)
- **Rolling-resistance convention**: Alciatore defines μr = a/g, so the rolling deceleration is a = μr g. He measures it as μr = 2L/(g ΔT²) from a timed roll to rest. The equivalent rolling-resistance offset is d = (7/5) μr R ≈ 0.016 in (TP B.2, posted 2008-01-14). — [Alciatore TP B.2](https://billiards.colostate.edu/technical_proofs/new/TP_B-2.pdf)
- A ball "starts to roll immediately only when the ball is hit horizontally at a height of 7R/5 from the table surface", i.e. 0.4R above centre. — [Mathavan, Jackson & Parkin, Am. J. Phys. 77(9) 788–794, 2009](https://forums.azbilliards.com/attachments/application_of_high-speed_imaging_to_determine_the-pdf.691242/)
- After a cushion impact a rolling ball **slides again** and then re-acquires rolling. High-speed tracking shows this as a change in the speed gradient. — [Mathavan et al. 2009](https://forums.azbilliards.com/attachments/application_of_high-speed_imaging_to_determine_the-pdf.691242/)
- **Event-based simulation** (Leckie & Greenspan 2006; pooltool). The loop computes the time to every candidate event, advances all balls analytically to the earliest one, resolves it, and repeats. There are 8 event types: ball-ball, ball-cushion, ball-slate and ball-pocket collisions, plus 4 phase transitions. Ball-ball collision time is the smallest positive real root of a quartic, (A·A)Δt⁴ + 2(A·B)Δt³ + (B·B + 2A·C)Δt² + 2(B·C)Δt + (C·C − 4R²) = 0, where A, B, C are the differences of the per-ball coefficients in r(t) = a t² + b t + c. — [Kiefl 2020-12-20](https://ekiefl.github.io/2020/12/20/pooltool-alg/); [Leckie & Greenspan, "An Event-Based Pool Physics Simulator", Advances in Computer Games 2006 / ICGA J. 29:24–31](https://www.springerprofessional.de/en/an-event-based-pool-physics-simulator/1276086)
- **Trade-off numbers** (pooltool): at 10 m/s with a 0.3 mm tolerance, discrete stepping needs Δt ≈ 30 µs, so a 10 s shot takes about 30,000 steps. Event-based simulation may need only about 5 events, and typically 10–50. That is roughly 521 event-time calculations per event for 16 balls, 18 cushion segments and 6 pockets, or about 5k–25k calculations per shot. About 95% of compute goes to event-time calculation. Discrete-step error is O(Δt); event-based error is floating-point only. — [Kiefl 2020-12-20](https://ekiefl.github.io/2020/12/20/pooltool-alg/)

### Inferences
- **Per-substep analytic update (recommended).** Each ball stores its phase. On each 1/240 s substep (remaining time τ = dt), for each moving ball:
  1. Compute t_tr, the time to the next transition (closed form above).
  2. Set h = min(τ, t_tr) and apply the closed-form update for h.
  3. If the transition fires, snap the state exactly: on slide→roll set u = 0 and ω_xy = (k̂ × v)/R; on roll→stop set v = 0. Continue with τ −= h.

  This is exact for any dt, so friction never depends on frame rate. It is deterministic because it is a fixed sequence of IEEE ops on the same inputs.
- **The sliding-phase parabola is exact.** û₀ is constant during sliding, so a = −μs g û₀ is constant. Draw/follow curves after contact (the cue ball "bending" after hitting an object ball) need no special code: they fall out of the ω carried through the collision. Computed: a stun ball at 2 m/s slides 0.291 s and 0.499 m, then rolls at 5/7 v₀ = 1.43 m/s.
- **Final rolling velocity after sliding** is v_f = v₀ − (2/7) u₀ (from μs g · t_slide = 2u₀/7). A stopped ball with backspin R·ω_back therefore rolls back at (2/7) R ω_back. This is the "draw back" magnitude, and a good unit test.
- **Hybrid.** Keep the fixed 1/240 grid (required by repo rules) but sleep stationary balls and skip pair tests for sleeping pairs. If the headless AI is too slow, an event-based "jump to next event" mode would be far cheaper for the long rolling tails. It produces different rounding from substep mode, though, so the AI and live play must use the **same** mode or the AI's predicted outcomes will drift from what the player sees.
- Computed: angular deceleration while sliding is 5 μs g/(2R) = 171.7 rad/s² (μs = 0.2).

### Gaps
- No primary source found giving GDScript or ARM performance numbers for this kind of solver. The cost of 128 AI rollouts × ~2,400 substeps × 120 pairs on mid-range Android must be benchmarked in the repo.

## Q2. Cloth friction, ball, and table parameters

### Takeaway
Use μs ≈ 0.2, μr ≈ 0.010–0.013 (deceleration = μr·g), and a spin deceleration of about 10–11 rad/s² (pooltool μsp = 0.444·R). Ball: R = 0.028575 m, m = 0.170 kg, I = 2/5 m R² ≈ 5.56e-5 kg·m². Tables (playing surface between cushion noses): 9-ft 100×50 in (2.54×1.27 m), 8-ft 92×46 in, 7-ft 78×39 in (1.981×0.991 m).

### Cited Findings
- **Alciatore "Pool Physics Property Constants"** (no date on page). Ball diameter 2.25 in; mass 6 oz; I = 2/5 mR². Ball-ball μ 0.03–0.08; ball-ball e 0.92–0.98. Ball-cloth rolling resistance 0.005–0.015; ball-cloth sliding μ 0.15–0.4 (typical 0.2). Ball-cloth **spin deceleration 5–15 rad/s²**. Ball-rail e 0.6–0.9; ball-table e 0.5–0.7. Cue-tip μ 0.6; cue-tip e 0.71–0.75 (leather), 0.81–0.87 (phenolic). — [billiards.colostate.edu physical properties](https://billiards.colostate.edu/faq/physics/physical-properties/)
- Alciatore's own experiment on a typical cloth: average μr = 0.01. "This number will obviously vary with cloth type and conditions." — [TP B.2 (2008)](https://billiards.colostate.edu/technical_proofs/new/TP_B-2.pdf)
- **Mathavan et al. 2009** (snooker, high-speed camera). Sliding friction 1.75–2.40 m/s², i.e. **μs 0.178–0.245**. Rolling deceleration **0.124–0.126 m/s², μr 0.0127–0.0129** (defined as deceleration/g), constant with speed. Marlow suggested μr 0.011–0.024 for pool (mean 0.016) and derived μs ≈ 0.2. Witters & Duymelinck found μs rising from 0.14 at low speed to 0.21, which Mathavan could not verify. Sliding friction is "15–20 times larger" than rolling. — [Mathavan et al., Am. J. Phys. 77(9), 2009, DOI 10.1119/1.3157159](https://forums.azbilliards.com/attachments/application_of_high-speed_imaging_to_determine_the-pdf.691242/)
- **pooltool defaults** (SI, "taken from or based off" the colostate page, with the code comment "nothing here is well-researched or perfect"): m = 0.170097, R = 0.028575, u_s = 0.2, u_r = 0.01, u_sp = (10·2/5/9)·R ≈ 0.444·R, u_b = 0.05, e_b = 0.95, e_t = 0.5, e_c = 0.85, f_c = 0.2, g = 9.81. — [pooltool ball params.py](https://raw.githubusercontent.com/ekiefl/pooltool/main/pooltool/objects/ball/params.py)
- **WPA specs** (as reproduced; no date on page): 9-ft playing surface 100 (+1/8) × 50 (+1/8) in; 8-ft 92 × 46 in. Balls 2¼ in (+0.005 in), about 156–170 g (5.5–6 oz). Cushion rubber should let a ball travel 4–4½ table lengths. — [poolroom.com WPA table & equipment specs](https://www.poolroom.com/?p=3677)
- pooltool's default pocket table is a **7-ft, 78×39 in playing surface** (l = 1.9812 m, w = 0.9906 m), cushion width 2 in. — [pooltool table specs.py](https://raw.githubusercontent.com/ekiefl/pooltool/main/pooltool/objects/table/specs.py)
- Mathavan 2010 used snooker values: μs = 0.212, M = 0.1406 kg, R = 26.25 mm. — [Mathavan, Jackson & Parkin, Proc. IMechE C 224 (2010) 1863–1873](https://forums.azbilliards.com/attachments/smathavanetalimechemes-pdf.690515/)

### Inferences
- Computed spin deceleration with pooltool's μsp: 5·μsp·g/(2R) = 5·0.444·9.81/2 ≈ **10.9 rad/s²**, which sits inside Alciatore's 5–15 rad/s². Recommendation: store spin deceleration directly as a parameter (`spin_decel = 10.9`) rather than μsp.
- **Rolling stop distance** v²/(2 μr g), computed at 1 m/s: μr 0.010 gives 5.10 m; μr 0.012 gives 4.25 m. The repo's 5/7 convention would give 5.95 m at μr 0.012. The repo default μr = 0.012 (no 5/7) matches the Mathavan measurement best.
- Keep μs = 0.2 (consensus). It sets how quickly draw and stun "take": a higher μs means draw dies sooner.
- Ball inertia: I = 0.4·0.170097·0.028575² ≈ 5.556e-5 kg·m² (computed).
- Recommended table: a 7-ft (1.981×0.991 m) or 8-ft playfield reads better on a phone than 9-ft (larger balls on screen), but pool.md specifies 9-ft (2.54×1.27 m). This is a design call, not a physics one.

### Gaps
- No source found for cloth-specific (worsted vs napped) values of the spin-deceleration coefficient beyond Alciatore's 5–15 rad/s² range.
- I could not find the official WPA PDF. The figures rest on a secondary reproduction. The poolroom page gave no 7-ft dimensions; the 78×39 in figure comes from pooltool.

## Q3. Ball-ball collision: restitution, throw (CIT/SIT), the Alciatore model, and game simplifications

### Takeaway
Use an impulse model: normal impulse with e ≈ 0.93–0.95, plus a tangential friction impulse capped by both Coulomb (μ·Jn) and the "slip stops" limit (m·v_rel/7). Make μ speed-dependent with Alciatore's fit μ(v) = 9.951e-3 + 0.108·e^(−1.088·v). That one rule gives cut-induced throw, spin-induced throw, and the reduced throw of fast shots. It costs a handful of flops per collision.

### Cited Findings
- **Alciatore TP A.14** (posted 2005-07-15, revised 2025-05-19): "The effects of cut angle, speed, and spin on object ball throw."
  - Relative slip speed at contact: v_rel = √((v sinφ − R ω_z)² + (R ω_x cosφ)²).
  - Normal impulse (elastic) F̃n = m v cosφ.
  - Friction-limited tangential impulse F̃t ≤ μ F̃n.
  - Kinematic limit (slip cannot reverse): F̃t,max = m (v sinφ − R ω_z)/7.
  - Hence v_OB,t = min( μ v cosφ / v_rel , 1/7 ) · (v sinφ − R ω_z), and v_OB,n = v cosφ.
  - Throw angle θ = tan⁻¹(v_OB,t / v_OB,n).
  - Typical values: μ = 0.06, R = 0.029 m, v = 1.341 m/s (3 mph). — [TP A.14 PDF](https://billiards.colostate.edu/technical_proofs/new/TP_A-14.pdf)
- **Speed-dependent ball-ball friction.** Fit to Marlow's data (*The Physics of Pocket Billiards*, Table 10, p. 245): μ(v) = a + b·e^(−c·v), with a = 9.951×10⁻³, b = 0.108, c = 1.088 (v = relative slip speed in m/s). Data points: μ = 0.11, 0.06, 0.01 at v = 0.1, 1 and 10 × sin45° m/s. — [TP A.14](https://billiards.colostate.edu/technical_proofs/new/TP_A-14.pdf)
- Throw is largest for a slow stun shot. With a stun, maximum throw is "normally at close to a 1/2-ball hit (30 degree cut angle)", shifting to 50–60° in clingy conditions. "Gearing" outside spin gives no throw. — [TP A.14](https://billiards.colostate.edu/technical_proofs/new/TP_A-14.pdf)
- e and μ "can vary significantly with shot speed, cut angle, and ball condition", and older, dirty balls vary most. Alciatore's model calculations use e = 0.94 and μ = 0.06. — [Alciatore resources via search summary](https://billiards.colostate.edu/technical_proofs/new/TP_A-5.pdf)
- Ranges: e 0.92–0.98, μ 0.03–0.08 — [colostate properties page](https://billiards.colostate.edu/faq/physics/physical-properties/); the same ranges appear in [Kim 2024, arXiv:2402.13258](https://arxiv.org/abs/2402.13258).
- Related Alciatore proofs: TP A.5 "effects of ball inelasticity and friction on the 90° rule" (2005), TP A.6 "…on the 30° rule" (2005, rev. 2021), TP A.4 "Post-impact cue ball trajectory for any cut angle, speed, and spin" (2005, rev. 2008). — [TP A.5](https://billiards.colostate.edu/technical_proofs/new/TP_A-5.pdf), [TP A.6](https://billiards.colostate.edu/technical_proofs/new/TP_A-6.pdf), [TP A.4](https://billiards.colostate.edu/technical_proofs/new/TP_A-4.pdf)
- pooltool's frictionless elastic model (stationary target): v_A = v₀ sinα, v_B = v₀ cosα, with outgoing velocities perpendicular. Moving targets are handled by working in B's frame. Spins are unchanged and **multi-ball collisions are not modeled**. pooltool also ships a "frictional_mathavan" ball-ball resolver. — [Kiefl 2020](https://ekiefl.github.io/2020/04/24/pooltool-theory/); [pooltool frictional_mathavan source](https://pooltool.readthedocs.io/en/v0.4.2/_modules/pooltool/physics/resolve/ball_ball/frictional_mathavan.html)

### Inferences
- **General vector form for the solver.** This generalises TP A.14 to two moving, spinning balls and equal masses. Let n̂ be the unit vector from A to B and v_n = (v_A − v_B)·n̂ > 0.
  1. Normal impulse: Jn = (1+e) · (m/2) · v_n. Apply −Jn n̂ to A and +Jn n̂ to B.
  2. Contact slip velocity: s = (v_A − v_B) − ((v_A − v_B)·n̂)n̂ + R(ω_A + ω_B) × n̂. The sign follows from the contact-point velocity v + ω × (±R n̂) for each ball. Verify it with a unit test: outside "gearing" spin must give zero throw.
  3. A unit impulse at the contact changes that point's velocity by 1/m + R²/I = 7/(2m) per ball, so 7/m for the pair. That gives Jt = min(μ(|s|)·Jn, m|s|/7), applied along −ŝ to A and +ŝ to B.
  4. Update spins with Δω = (R n̂ × J)/I on each ball (sign per side).

  With e = 1, ω = 0 and a stationary target, this reproduces TP A.14's 1/7 limit.
- Computed throw from the TP A.14 formula with μ(v): stun at 0.447 m/s gives about 1.4° at a 10° cut, 4.7° at 30° and 4.95° at 45°. Natural roll at 1.341 m/s gives about 0.35° at 10°, 1.0° at 30° and 1.4° at 45°. These magnitudes are visible to players aiming long shots. Keep throw, but a casual game may scale μ by 0.5–1.0 if testers call pots "unfair".
- The repo's mu_ball = 0.055 is reasonable as a constant. Switching to μ(v) is one exp() per collision. That is cheap and deterministic as long as the same exp implementation is used everywhere (see Q7).
- Use e_ball = 0.93–0.95. The difference is small, but it changes stop shots: with e < 1 a straight centre-ball stun leaves the cue ball creeping forward at (1−e)/2·v. At v = 2 m/s and e = 0.93 that is 0.07 m/s, which rolls about 2 cm after sliding. Computed estimate; check it against the "stop shot within 1 cm" test in pool.md. That test may need e closer to 0.95 or a tolerance tied to e.
- The ball-ball "cling/skid" of dirty balls should be skipped.

### Gaps
- I did not find independent experimental throw-angle tables beyond Alciatore's model and Marlow's data (via TP A.14). The throw numbers above are computed from the model, not measured.
- I did not obtain the Mathavan frictional ball-ball model equations or its validation numbers.

## Q4. Cushion (rail) collision models: Han 2005, Mathavan 2010, simpler approximations

### Takeaway
Use **Han 2005**: a closed-form, instantaneous impulse that accounts for nose height, spin, and both sliding and sticking. It costs about 30 flops, is deterministic, and makes running/reverse english and follow/draw change the rebound angle. Set the contact height from the real nose geometry (sinθ ≈ 0.27–0.4; see the conflict below). Clamp the outgoing v_z to 0 (2.5D) and start from e_c ≈ 0.85, μ_c ≈ 0.14–0.2. Mathavan 2010 is more accurate but needs numerical integration (hundreds to thousands of steps per impact), so keep it as an offline reference only.

### Cited Findings
- **Han 2005** ("Dynamics in carom and three cushion billiards", J. Mech. Sci. Tech., DOI 10.1007/BF02919180), as implemented and corrected by pooltool.
  - Contact angle θ = arcsin(ε/R), where ε is the cushion contact height above ball centre (pooltool text: typical 0.1R ≤ ε ≤ 0.2R).
  - Frame quantities: s_x = v_x sinθ − v_y cosθ + R ω_y; s_y = −v_y − R ω_z cosθ + R ω_x sinθ; c = v_x cosθ.
  - Impulse limits: P_zE = m c (1+e); P_zS = (2m/7)√(s_x² + s_y²).
  - If P_zS ≤ P_zE (sticking): v_x' = −(2/7) s_x sinθ − (1+e) c cosθ; v_y' = (2/7) s_y; v_z' = (2/7) s_x cosθ − (1+e) c sinθ.
  - Otherwise (sliding, with φ the slip direction): v_x' = −c(1+e)(μ cosφ sinθ + cosθ); v_y' = c(1+e) μ sinφ; v_z' = c(1+e)(μ cosφ cosθ − sinθ).
  - Spins: ω_x' = −(mR/I) v_x sinθ; ω_y' = (mR/I)(v_x sinθ − v_z cosθ); ω_z' = (mR/I) v_y cosθ.
  - pooltool notes **two errors in Han's paper**, fixed in its worksheet `ball_cushion_inhwan_han.pdf`. The ω equations as printed on the blog contain a typo (ω_x appears twice), and the blog's ω block is visibly inconsistent: ω' should be ω + Δω, not a pure function of v. Implement from pooltool's current source or worksheet, not from the blog text. — [Kiefl 2020](https://ekiefl.github.io/2020/04/24/pooltool-theory/)
- **Mathavan 2010** (Proc. IMechE Part C 224:1863–1873, DOI 10.1243/09544062JMES1964).
  - It is a 3D impact model with friction at both the cushion contact I and the table contact C, solved numerically over the impulse.
  - Contact height **h = 7R/5 for both snooker and pool**.
  - Best fit to experiment: **e_e = 0.98, μ_w = 0.14** (ball–cushion sliding friction), with μs = 0.212 for the table.
  - The rigid-cushion assumption holds for normal velocity **below 2.5 m/s**.
  - Rebound speed and angle depend strongly on topspin and sidespin (their Figs 8–10). A ball usually reaches the cushion rolling.
  - — [Mathavan et al. 2010 PDF](https://forums.azbilliards.com/attachments/smathavanetalimechemes-pdf.690515/)
- pooltool's Mathavan implementation integrates the compression phase in impulse steps (resolver defaults max_steps = 1000, delta_p = 0.001), finds the crossing by binary search, then integrates restitution until the work equals e²·W_compression. sinθ = (h − R)/R. — [pooltool mathavan_2010/model.py](https://raw.githubusercontent.com/ekiefl/pooltool/main/pooltool/physics/resolve/ball_cushion/mathavan_2010/model.py)
- **Measured cushion restitution** (Mathavan 2009, snooker, rolling ball, perpendicular impact, 0.28–3.5 m/s). A linear fit gives **e = 0.818**. A better fit is rebound = −0.0877x² + 1.131x − 0.0953. The low-speed gradient is about **0.910**; the fall at high speed is due to cushion deformation. Marlow reported 0.55 for pool rails. — [Mathavan et al. 2009](https://forums.azbilliards.com/attachments/application_of_high-speed_imaging_to_determine_the-pdf.691242/)
- Alciatore's range for ball–rail e is 0.6–0.9. — [colostate properties](https://billiards.colostate.edu/faq/physics/physical-properties/). pooltool defaults are e_c = 0.85, f_c = 0.2. — [pooltool params.py](https://raw.githubusercontent.com/ekiefl/pooltool/main/pooltool/objects/ball/params.py)
- **Nose height conflict.** WPA specifies rail height (nose to bed) of **63.5% (±1%) of ball diameter**, i.e. 1.27R above the bed or **0.27R above ball centre** — [WPA via poolroom.com](https://www.poolroom.com/?p=3677). pooltool's default cushion_height = 0.64·2R = 1.28R — [pooltool specs.py](https://raw.githubusercontent.com/ekiefl/pooltool/main/pooltool/objects/table/specs.py). Mathavan uses h = 7R/5 = 1.4R (0.4R above centre) — [Mathavan 2010](https://forums.azbilliards.com/attachments/smathavanetalimechemes-pdf.690515/). pooltool's theory post states 0.1R–0.2R above centre — [Kiefl 2020](https://ekiefl.github.io/2020/04/24/pooltool-theory/).

### Inferences
- **Correction to the brief.** The nose sits about 0.63 × **diameter** above the bed, i.e. about 1.27R above the bed and about 0.27R above ball centre, not "0.63R above centre". Computed θ: asin(0.27) ≈ 15.7° (WPA), asin(0.28) ≈ 16.3° (pooltool), asin(0.4) ≈ 23.6° (Mathavan's 7R/5). Make sinθ a tunable (start 0.27). A higher contact angle converts more topspin into rebound-angle change.
- **2.5D clamp.** Han yields v_z' ≠ 0 (the ball hops). With no jump support, drop v_z' and keep v_x', v_y' and the spins. Optionally scale the horizontal speed down slightly to absorb the lost energy. The ball must not gain speed; enforce that in tests.
- **Speed-dependent e_c (optional).** e(x) = (−0.0877x² + 1.131x − 0.0953)/x on the normal speed x gives about 0.77 at 0.28 m/s, 0.95 at 1 m/s, 0.91 at 2 m/s and 0.84 at 3 m/s (computed). It is negative below about 0.085 m/s, so clamp it, for example e = clamp(e(x), 0.5, 0.95). The data are snooker, so tune by feel. A constant 0.85 is fine for v1.
- After every cushion hit, set the ball to the **sliding** phase (Mathavan 2009 observation). The analytic sliding equations then naturally produce the bending path after a rail with running or reverse english.
- **Cheaper fallback (if Han is cut).** A 2D impulse with θ = 0: v_n' = −e v_n. The tangential slip s = v_t − R ω_z (cushion frame) is reduced by Jt = min(μ_c(1+e)m|v_n|, (2/7)m|s|)·sign(s). This is Han at θ = 0, so it still shows english effects on angle; it just drops the topspin coupling.

### Gaps
- No pool-specific (as opposed to snooker) measurement of cushion e or μ_w was found. The pool-rail "0.82 measured" figure in pool.md traces to Mathavan's **snooker** data.
- I did not fetch the pooltool Han worksheet. The two corrected errors in Han's paper are not itemised here. Fetch `ball_cushion_inhwan_han.pdf` or pooltool's `han_2005` model.py before implementing.

## Q5. Squirt, swerve, massé, jump — include or skip on mobile

### Takeaway
For a casual mobile game, **skip massé and jump** and **skip or fake swerve**. Squirt can be modelled in one line, so make it a tunable (default 0 or a small constant) and do not ship it as a hidden aiming penalty. Spin input should be clamped to 0.5R tip offset (already in pool.md).

### Cited Findings
- **Squirt (Alciatore TP A.31**, 2007-08-02): squirt angle α = atan( (5/2)·b_r·√(1−b_r²) / (1 + m_r + (5/2)(1−b_r²)) ). Here b_r = b/R is the tip offset and m_r = m_ball/m_endmass (about 15 for a high-squirt/break cue, about 40 for a low-squirt shaft). Squirt is nearly linear in tip offset. Example: b_r = 0.5 gives α = 3.466° at m_r = 15 and 1.446° at m_r = 40. — [TP A.31](https://billiards.colostate.edu/technical_proofs/new/TP_A-31.pdf) (the researcher reproduced 3.466° and 1.446° from the formula, confirming the reading)
- The sliding-phase equations produce curved paths whenever the in-plane spin is not aligned with the velocity (k̂ × v). This is the mechanism behind swerve and massé. — [Kiefl 2020](https://ekiefl.github.io/2020/04/24/pooltool-theory/)
- The ball–slate event and airborne balls exist in pooltool (event-based) but add a 3D ballistic phase. — [Kiefl 2020-12-20](https://ekiefl.github.io/2020/12/20/pooltool-alg/)
- Cue-tip parameters: μ 0.6, e 0.71–0.75 (leather). — [colostate properties](https://billiards.colostate.edu/faq/physics/physical-properties/)

### Inferences
- **Cue strike model** (derived from rigid-body impulse, horizontal cue). A strike impulse J along the aim direction at tip offset (side a, vertical b) gives v = J/m and ω = (r × J)/I, so |Rω| = (5/2)(d/R)·v. With b = 0.4R this gives Rω = v, natural roll, consistent with Mathavan's 7R/5 statement. With a horizontal cue, ω_xy is parallel to k̂ × v and the initial slip is collinear with v, so **there is no swerve unless squirt or cue elevation is modelled**. That is a nice simplification: the cue ball goes straight until it hits something.
- If squirt is wanted for "realism", apply α as a rotation of the initial velocity away from the side-spin direction, with m_r ≈ 30 (mid). The aim line should then **not** compensate, or players feel cheated. Recommendation: off for Easy/Medium UX, or show it in the aim line.
- Massé and jump need cue elevation input and 3D/airborne phases, so skip them. Swerve without squirt is invisible anyway.

### Gaps
- No source for player expectations in mobile pool games regarding squirt. The UX decision is not physics-backed.

## Q6. Pocket geometry and capture tests (game-grade)

### Takeaway
Build each pocket from the two cushion noses (the jaw "points", rounded with a small radius), two straight facings angled into the pocket, and a capture circle or line behind the mouth. WPA mouth widths: corner 4.5–4.625 in (11.43–11.75 cm, about 2.0 ball diameters), side 5–5.125 in (12.7–13.0 cm). Facing (cut) angles: 142° corner, 104° side. A ball is potted when its centre crosses the capture boundary. Rattles fall out of normal cushion physics on the facings and jaw arcs.

### Cited Findings
- **WPA** (as reproduced, no date). Corner pocket mouth 4.5–4.625 in; side mouth 5–5.125 in. Corner entrance cut angle **142° (+1)** both sides; side **104° (+1)**. Vertical pocket angle (back draft) 12–15°. Corner shelf 1–2¼ in; side shelf 0–0.375 in. Rail nose height 63.5% of ball diameter. Cushion width 1⅞–2 in. — [poolroom.com WPA specs](https://www.poolroom.com/?p=3677)
- A BCA spec listed by a cloth supplier differs: corner mouth 4⅛–5⅛ in, side angle about 103°. WPA figures may not apply to home tables. — [search summary of pooltablefeltcloth.com BCA pocket specs](https://pooltablefeltcloth.com/billiard-congress-of-america-bca-pocket-specifications.html)
- **pooltool 7-ft default pocket geometry** (m):
  - Corner: width 0.118, angle 5.3°, depth 0.0417, radius 0.062, jaw radius 0.02095.
  - Side: width 0.137, angle 7.14°, depth 0.0685, radius 0.0645, jaw radius 0.00795.
  - — [pooltool specs.py](https://raw.githubusercontent.com/ekiefl/pooltool/main/pooltool/objects/table/specs.py)
- pooltool models pockets as circles; a ball-pocket event is the ball centre entering the pocket circle, solved as a quartic. Pocketing is a removal, not a modelled fall. Cushions are line segments (accepted only if the hit point has 0 ≤ s ≤ 1), with collision-line and circular jaw variants. — [Kiefl 2020-12-20](https://ekiefl.github.io/2020/12/20/pooltool-alg/)

### Inferences
- **Game-grade pocket construction.** Per pocket:
  1. Two jaw-tip arcs (circle obstacles of radius r_jaw ≈ 2 cm corner, 0.8 cm side, from pooltool), placed so the mouth gap between cushion noses equals the WPA mouth.
  2. Two facing segments running from the jaw tips into the pocket, angled per WPA. 142° from the cushion line at a corner means each facing converges about 7° toward the pocket axis relative to a 45° diagonal. 104° at a side means each facing flares about 14° from the perpendicular. This is an inferred interpretation; pooltool's 5.3° and 7.14° "pocket angle" parameters suggest different conventions, so verify visually against `docs/refs/pool/`.
  3. A capture circle (pooltool radius about 6.2–6.5 cm) whose centre sits about one shelf depth (corner 4.2 cm, side 6.9 cm in pooltool) behind the mouth line. A ball is potted on the first substep its centre enters the circle.

  All obstacles reuse the same swept-circle vs segment/circle TOI code as cushions and balls, so there is no special pocket code path.
- **Rattle.** A ball hitting a facing at a shallow angle bounces between facings. This emerges automatically if facings use the cushion model, perhaps with a slightly higher e on the facings to make "jaw rattle" more visible. No source supports a separate facing e; tune by feel.
- **Difficulty knob.** Mouth width is the cleanest difficulty lever: tighter for Hard CPU and practice, WPA-wide for casual. Keep it per-table data, not code.
- The vertical back draft and shelf drop need no simulation in 2.5D. Animate the drop visually after capture.

### Gaps
- The official WPA document was not retrieved, and the exact definition of the 142°/104° angle (the reference line it is measured from) should be verified from a diagram.
- No source gives a measured restitution for pocket facings.

## Q7. Continuous collision detection, event ordering, simultaneous collisions, determinism, tests

### Takeaway
Within a 1/240 s substep the friction-induced position curvature is at most ½·μs g·dt² ≈ 0.017 mm. Linear swept-circle TOI (a quadratic) is therefore accurate enough. Find the earliest TOI over all pairs, cushion segments and jaw arcs; advance all balls analytically to it; resolve; then re-search the remainder of the substep. Break ties by deterministic index order. Store all sim state in GDScript `float` (64-bit) scalars or `PackedFloat64Array`. **Not** `Vector2`/`Vector3`, which are 32-bit.

### Cited Findings
- Godot: "By default, float is 64-bit in GDScript, but Vector2, Vector3 and Vector4 are 32-bit." Making vectors double requires recompiling the editor and every export template with `precision=double`. — [Godot docs, Large world coordinates](https://docs.godotengine.org/en/stable/tutorials/physics/large_world_coordinates.html)
- The exact event approach uses smallest positive real roots of polynomials up to fourth order (closed form exists). Only real positive roots count. Collision planes need an s ∈ [0,1] segment check to avoid "ghost" hits. pooltool does not discuss tie-breaking of simultaneous events. — [Kiefl 2020-12-20](https://ekiefl.github.io/2020/12/20/pooltool-alg/); [Leckie & Greenspan 2006](https://www.springerprofessional.de/en/an-event-based-pool-physics-simulator/1276086)
- Discrete stepping "predicts events only after they occur" (error O(Δt)). At 10 m/s a 0.3 mm tolerance needs Δt ≈ 30 µs. — [Kiefl 2020-12-20](https://ekiefl.github.io/2020/12/20/pooltool-alg/)
- pooltool's ball-ball model handles only pairwise collisions ("multi-ball collisions are not modeled"). — [Kiefl 2020](https://ekiefl.github.io/2020/04/24/pooltool-theory/)

### Inferences
- **Why swept tests are mandatory.** At a 10 m/s break speed a ball moves 4.17 cm per 1/240 s substep. That is more than R (2.86 cm) and close to the diameter, so naive overlap tests would miss or deeply overlap (computed).
- **Ball-ball TOI** (linear relative motion over the substep remainder). Let d = p_B − p_A, w = v_B − v_A. Solve |d + w t|² = (2R)², i.e. a = w·w, b = d·w, c = d·d − 4R².
  - Hit only if b < 0 (approaching) and b² − a c ≥ 0.
  - t = c / (−b + √(b² − a c)). This is the numerically stable "citardauq" form, which avoids cancellation when a is small.
  - Accept 0 ≤ t ≤ τ.
  - If c < 0 already (overlap from round-off) and b < 0, resolve immediately at t = 0. Do not skip it.
- **Segment (cushion/facing) TOI.** The distance from the centre to the cushion line minus R reaches 0, and the foot point must lie on the segment. Otherwise test the endpoint or jaw arc as a circle of radius R + r_jaw (same quadratic as above).
- **Event loop per substep:**

  ```
  τ = dt
  loop:
    find the earliest event among pair TOIs, cushion TOIs and phase transitions
    if t* > τ: advance all balls by τ and stop
    advance all balls by t*
    resolve the event
    τ −= t*
    repeat (cap at, e.g., 64 events/substep, then fall back to positional separation)
  ```

  Treat events within ε_t = 1e-12 s as simultaneous. Resolve them sequentially in a fixed order (lowest ball index first, then the pair's second index), re-checking approach (v_n > 0) before each. This sequential-impulse (Gauss-Seidel style) handling is the standard game approach for breaks and frozen clusters. It is deterministic because the order is fixed.
- **Break shot.** A perfectly tight rack plus sequential pairwise impulses gives an order-dependent but **deterministic** spread. For variety and realism, perturb the rack with seeded `Rng` gaps of about 0.0–0.2 mm and tiny angular jitter. The golden master then fixes the seed. Never use `randf()` (repo rule).
- **Contact tolerance.** After resolving, if two balls are within 1e-9 m of overlap, separate them along n̂ symmetrically. Keep "touching" pairs (frozen balls) from re-triggering zero-time events by requiring v_n > 1e-9 m/s to count as approaching.
- **Floating-point determinism.** The basic IEEE-754 double ops (+, −, ×, ÷, √) are correctly rounded and identical across x86 and ARM if evaluation order is fixed. Avoid summing in hash/dictionary iteration order. Transcendentals (sin, cos, atan2, exp in μ(v)) come from the platform libm and *may* differ in the last ulp between desktop and Android. For a cross-platform golden master at 1e-6, either avoid transcendentals inside the hot sim path or accept platform-specific goldens. Within one device, AI search and live play are bit-identical. The cross-platform libm claim is general numerical knowledge, not verified for Godot specifically; see Gaps.
- **No per-frame allocations.** Store the state in `PackedFloat64Array` (px, py, vx, vy, wx, wy, wz, phase) indexed by ball, and pre-allocate event scratch arrays. This satisfies repo DoD item 4 and avoids Vector2's 32-bit precision.
- **Tests:**
  1. **Energy never increases.** Track E = Σ ½m|v|² + ½I|ω|² after every event and substep: E_after ≤ E_before·(1 + 1e-12). Ball-ball friction is safe because Jt ≤ m|s|/7 never reverses slip. Han's 2.5D clamp (dropping v_z) only removes energy.
  2. **Phase timing.** A stun at v₀ transitions to roll at exactly 2v₀/(7μs g) and at speed 5v₀/7.
  3. **Draw-back.** A ball stopped with backspin rolls back at (2/7)Rω.
  4. **90° rule.** A stun cut with e = 1 and μ = 0 leaves the cue ball and object ball velocities perpendicular (TP A.5 / pooltool model 1).
  5. **30° rule.** A natural-roll half-ball hit deflects the cue ball about 30° (TP A.6 title). Assert roughly 27–34° after the slide-to-roll curve. Use a wide tolerance; this is an inferred check, not a sourced value.
  6. **Outside gearing spin** gives about 0 throw.
  7. **No overlaps** over 10k random shots: min centre distance ≥ 2R − 1e-9.
  8. **Golden-master break.** Fixed seed and cue velocity give identical positions to 1e-6. Note platform caveats.
  9. **Frame-rate independence.** The same shot with the renderer at 30/60/120 fps gives bitwise-identical end state, because the sim only steps on the fixed 1/240 grid.

### Gaps
- No source was found confirming whether Godot 4.7's GDScript `sin`/`exp`/`atan2` give bit-identical results on Android ARM64 vs desktop x86_64. Test this empirically with a golden file generated on both.
- No published data was found on how real break outcomes depend on rack gap size, so the 0–0.2 mm jitter range is a design choice, not a measured value.
- Alciatore's "typical range of ball speeds" page (max break speed) was linked from the properties page but not retrieved. 10 m/s is used here as an illustrative upper bound.
