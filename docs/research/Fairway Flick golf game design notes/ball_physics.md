# Golf ball flight and ground-interaction physics (implementation parameters)

Scope: numeric parameters, formulas and validation targets for a deterministic, fixed-timestep golf simulation (RK4 flight plus a custom bounce/roll model) in an original mobile game. All values are SI unless stated. Unit conversions used: 1 mph = 0.44704 m/s, 1 yd = 0.9144 m, 1 ft = 0.3048 m, rpm x 2*pi/60 = rad/s.

Common constants (used throughout):
- Ball diameter 0.04267 m (r = 0.021335 m) and mass 0.04593 kg are the values used by an open-source flight model, matching the Rules-of-Golf limits (min diameter 1.68 in, max mass 1.62 oz) — [opengolfcoach trajectory.rs](https://docs.rs/crate/opengolfcoach/0.3.0/source/src/trajectory.rs); the 1.68 in / 1.62 oz figures also appear in the WSU sports-ball table — [Kensrud thesis](https://baseball.physics.illinois.edu/kensrudthesis.pdf)
- Ball moment of inertia: treat as I = (2/5) m r^2 (solid sphere). Penner's bounce equations (factor 5/7, 5/2r) and the Stimpmeter derivation (5/7 g sin theta) both assume this — [Penner 2002, Can. J. Phys. 80:931](http://waddengolfacademy.com/putting/Penner_The%20Run%20of%20a%20Golf%20Ball.pdf); [Lee 2025](https://stephenlee.info/golf/physics/2025/11/16/rederiving-aimpoint.html)
- Cup diameter 4.25 in = 108 mm — [Dillon, "Dies at the hole"](https://tkevindillon.substack.com/p/dies-at-the-hole)

---

## 1. Flight aerodynamics: Cd(Re, S), Cl(S), spin decay, air density

### Takeaway
Modern golf balls have Cd of about 0.20-0.25 above Re of about 1e5 (above roughly 35 m/s) and about 0.5 below the drag crisis at Re of about 5e4-8e4 (about 18-28 m/s). Spin adds a smooth, small drag increase, and lift rises roughly linearly with spin ratio S up to S of about 0.25 and keeps rising above it. The proposed "Cd 0.27 -> 0.32 step at S = 0.1, Cl = 0.54 S^0.4 clamped at 0.25, 4 %/s decay" is cheap but biased. In my RK4 check it under-carries a tour driver by about 12 % and flattens iron trajectories (apex and landing angle too low). The 4 %/s spin decay is fine. A smooth sigmoid-plus-spin Cd with a quadratic-then-linear Cl costs about the same and lands within about 3-8 % of TrackMan carries.

### Cited Findings
**Drag**
- Lyu, Kensrud, Smith & Tosaya (WSU, ISEA 2018) measured 13 production balls in still air at 18-91 m/s and 1500-4500 rpm. Non-spinning Cd was about 0.5 at Re = 5e4 and about 0.2 at Re = 1e5. Ball-to-ball Cd spread was >0.1 at Re < 1e5 and <0.05 at Re > 1e5. Spinning balls (1500-2500 rpm) showed the same drag crisis. Drag was fit with two polynomials, one for 50k < Re < 100k and one for 75k < Re < 200k — [Lyu et al. 2018, Proceedings 2(6):238](https://pdfs.semanticscholar.org/595d/3d1f91e240cb47e153b8d0ef586b8caa67c4.pdf)
- Small Cd/Cl differences (about 0.02) changed carry by 18 m across the 13 balls. A Cd uncertainty of 0.0025 is about 2.3 m of carry — [Lyu et al. 2018](https://pdfs.semanticscholar.org/595d/3d1f91e240cb47e153b8d0ef586b8caa67c4.pdf)
- In WSU in-situ tests of a non-spinning golf ball, the drag-crisis onset was at Re of about 70,000 and the minimum Cd was 0.17. Bearman & Harvey (1976) found a minimum Cd of 0.23 on dimpled balls. Bearman & Harvey also found that both Cl and Cd increased with spin at constant airspeed (tests used a 2.5x-scale model to reach flight Re) — [Kensrud 2010 thesis, WSU](https://baseball.physics.illinois.edu/kensrudthesis.pdf)
- Example: 160 mph is Re of about 209,000 at standard conditions — patent cited via search summary — [US patent 6796912](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6796912)
- Open-source model A (opengolfcoach, Rust) uses Cd = logistic blend between 0.5 (subcritical) and 0.225 (supercritical), centred at Re_crit = 80,000 with steepness 0.0002 per unit Re, plus a spin term 0.18 x (1 - exp(-3 S^2)) (capped at +0.18). It cites Bearman & Harvey and Smits & Smith — [opengolfcoach 0.3.0](https://docs.rs/crate/opengolfcoach/0.3.0/source/src/trajectory.rs)
- Open-source model B (libgolf, C++) uses Cd = 0.500 + k*S for Re <= 0.5e5, a linear blend for 0.5e5-1.0e5, and 0.200 + k*S for Re >= 1e5. Forces use air-relative velocity (v - v_wind) — [libgolf aerodynamic model](https://gdifiore.github.io/libgolf/docs/aerodynamic_model.html)

**Lift**
- Lyu et al. 2018 fit Cl vs spin factor S with a 2nd-order polynomial per ball. They only used balls at 32-91 m/s to avoid the reverse-Magnus effect at low speed — [Lyu et al. 2018](https://pdfs.semanticscholar.org/595d/3d1f91e240cb47e153b8d0ef586b8caa67c4.pdf)
- opengolfcoach implements Cl = 1.99 S - 3.255 S^2 for S <= 0.25, described as the Lyu et al. 2018 13-ball-average quadratic. At S = 0.25 this gives Cl = 0.2941 with slope 0.3625. Above S = 0.25 it continues linearly with that slope, matching Bearman & Harvey — [opengolfcoach](https://docs.rs/crate/opengolfcoach/0.3.0/source/src/trajectory.rs)
- libgolf sets Cl = 0 for Re <= 0.3e5 and ramps between 0.3e5 and 0.5e5. It interpolates Bearman dimpled-sphere bins at 50k-70k. Above 70k it uses Cl = ClMax(S)*S*g/(1+S*g), with ClMax lerped from 0.268 to 0.320 depending on spin ratio — [libgolf](https://gdifiore.github.io/libgolf/docs/aerodynamic_model.html)
- For a smooth sphere, Bearman & Harvey measured Cl as high as 0.5 at the highest spin and lowest airspeed — [Kensrud thesis](https://baseball.physics.illinois.edu/kensrudthesis.pdf)
- Smits & Smith (1994, "A new aerodynamic model of a golf ball in flight", Science & Golf II) measured over 40,000 < Re < 250,000 and 0.04 < S < 1.4. Patent excerpts quoting it are OCR-garbled. One shows a lift law "CL = C1*S^2.4", which may be a misread of S^0.4. I could not confirm the "0.54 S^0.4" form from a primary source — [US patent 11230375 (cites Smits & Smith)](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/11230375)

**Spin decay**
- Lyu et al. simulated trajectories with "4 % per second spin decay", citing TrackMan Newsletter #7 — [Lyu et al. 2018 ref. 21](https://pdfs.semanticscholar.org/595d/3d1f91e240cb47e153b8d0ef586b8caa67c4.pdf)
- Smits & Smith spin-down as quoted in patents: dω/dt = -4.0e-6 (v^2/R^2) S, with v in mph (OCR; verify) — [US patent 11230375](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/11230375)
- opengolfcoach decays spin exponentially per metre travelled, with K_SPIN_DECAY = 0.001 /m. Smits & Smith's c = 0.00002 (Slazenger ball) is equivalent to K = 0.00094 /m. The comment notes modern balls are "estimated to decay slightly faster" — [opengolfcoach](https://docs.rs/crate/opengolfcoach/0.3.0/source/src/trajectory.rs)
- libgolf uses tau = 1/(TAU_COEFF * |v| / r) and multiplies spin by exp(-dt/tau). Its example value is TAU_COEFF = 0.00002 — [libgolf](https://gdifiore.github.io/libgolf/docs/aerodynamic_model.html)
- Nathan models (baseball) spin decay as exponential with time constant 50/(k v) s — [Nathan, "Effect of spin-down"](https://baseball.physics.illinois.edu/spindown.pdf)
- Spin axis is set at impact and stays the same through flight (TrackMan) — [TrackMan: Spin axis](https://trackman.com/blog/golf/spin-axis)

**Air**
- opengolfcoach computes humid-air density (R_dry = 287.058, R_vapour = 461.495 J/(kg K), Tetens saturation pressure). Its default atmosphere is 1013.25 hPa, 288.15 K at sea level with a lapse rate of 0.0065 K/m. Viscosity follows Sutherland's law (1.458e-6, 110.4 K). g = 9.81 m/s^2 — [opengolfcoach](https://docs.rs/crate/opengolfcoach/0.3.0/source/src/trajectory.rs). These are ISA sea-level conditions, i.e. rho = 1.225 kg/m^3 and mu of about 1.79e-5 Pa s — [International Standard Atmosphere](https://en.wikipedia.org/wiki/International_Standard_Atmosphere)
- libgolf holds density constant for the whole shot, precomputed from temperature, pressure and humidity at launch — [libgolf](https://gdifiore.github.io/libgolf/docs/aerodynamic_model.html)

**Integration practice**
- opengolfcoach integrates at 500 Hz (dt = 0.002 s). libgolf uses a pluggable acceleration model with exponential spin decay applied each step — [opengolfcoach](https://docs.rs/crate/opengolfcoach/0.3.0/source/src/trajectory.rs); [libgolf](https://gdifiore.github.io/libgolf/docs/aerodynamic_model.html)

### Inferences
- **Force law** (what the open models use): with v_rel = v - v_wind, V = |v_rel| and k = 0.5 rho A / m (A = pi r^2 = 1.430e-3 m^2, so rho A / (2m) = 0.01907 /m at 1.225 kg/m^3):
  - a = -k Cd V v_rel + k Cl V (ω_hat x v_rel) - g y_hat
  - S = |ω| r / V
  - Re = rho V (2r) / mu, which is about 2,890 x V (V in m/s) at ISA.
- **Regimes in play**, from S = ωr/V on TrackMan launch numbers:
  - Tour driver (76.4 m/s, 2545 rpm): S of about 0.074 at launch, Re of about 2.2e5.
  - Tour 7-iron (55 m/s, 7124 rpm): S of about 0.29.
  - Tour PW (46.5 m/s, 9316 rpm): S of about 0.45.
  - All full shots land at about 19-25 m/s (Re of about 5.5e4-7.2e4), inside the drag crisis.
  - So for irons and wedges the clamp at Cl = 0.25 is active most of the flight. The Re-dependence of Cd near landing also matters for short shots and chips.
- **My RK4 check** (a throwaway Python script; ISA air, dt = 1/240 s, still air, flat ground):
  - Recommended model:
    - Cd = 0.225 + 0.275/(1+exp(0.0002 (Re-80000))) + 0.18 (1 - exp(-3S^2))
    - Cl = 1.99S - 3.255S^2 for S <= 0.25, else 0.2941 + 0.3625 (S-0.25)
    - Spin decay exp(-0.001 x distance)
  - Results against TrackMan, model vs measured carry:
    - PGA driver (171 mph, 10.4°, 2545 rpm): 274 vs 282 yd (-3 %), apex 31 yd, landing angle 40.5°.
    - PGA 7i (123/16.1/7124): 174 vs 176 yd (-1 %).
    - PGA PW (104/23.7/9316): 131 vs 142 yd (-7 %).
    - LPGA (older table) driver: 222 vs 218 yd (+2 %), apex 27 vs 25 yd, land 40° vs 37°.
    - LPGA 7i: 141 vs 141 yd, apex 28 vs 26 yd, land 51° vs 47°.
    - LPGA PW: 102 vs 107 yd, apex 24 vs 23 yd, land 51° vs 48°.
  - Proposed model (Cd 0.27/0.32 step, Cl = min(0.25, 0.54 S^0.4), 4 %/s decay):
    - PGA driver 248 yd (-12 %); 3-wood 225 vs 249 (-10 %); 7i 172; PW 144.
    - Iron landing angles about 38-44°, shallower than TrackMan's 47-50°.
    - Iron apexes about 20-27 yd, lower than TrackMan's.
    - Net effect: drives fall short and irons fly flat, which would give too much roll-out.
  - A grid search over Cd0 in {0.21, 0.225, 0.24}, spin-drag gain in {0.18-0.45} and Cl cap in {0.26-0.35, none} found the uncapped quadratic-then-linear Cl with gain 0.18 best. Capping Cl at 0.30-0.35 shortened wedges further. The residual bias of the recommended model is landing angles about 3-4° too steep and wedge carry 5-8 % short.
- **Spin decay**: the per-distance form (ω *= exp(-K V dt), K of about 0.001 /m) gives 2-7.6 %/s across a flight (76 m/s -> 7.6 %/s at launch, 20 m/s -> 2 %/s at landing). That averages close to the 4 %/s TrackMan figure. Either form is cheap. The distance form is more physical; a constant 4 %/s is acceptable.
- **RK4 timestep** (same script): carry changed by less than 0.3 m between dt = 1/30 s and 1/1000 s for driver and PW. RK4 at the physics tick (60 Hz) is therefore ample. Most of the residual error is the landing-crossing interpolation, so interpolate the ground crossing linearly within the step.
- **Determinism**: exp() and the sigmoid are deterministic per platform in IEEE double. For bit-exact cross-device replays, replace the sigmoid with a piecewise-linear Cd(Re), as libgolf does, to avoid any libm differences.

### Gaps
- No primary-source full text of Smits & Smith (1994) or Bearman & Harvey (1976) was retrieved. The "Cl = 0.54 S^0.4" law and the Smits & Smith Cd = f(S) constants remain unverified. Values here come via open-source code comments and a WSU thesis summary.
- The Lyu 2018 per-ball polynomial coefficients are only in figures (not extracted). The 1.99/-3.255 coefficients come second-hand from opengolfcoach.
- No 2024-2026 manufacturer aerodynamic data is public. Ball makers keep it confidential, as Lyu et al. note.

---

## 2. Launch conditions per club (tour and amateur)

### Takeaway
TrackMan's 2023-season tour averages (published May 2024) give a complete driver-to-PW set of ball speed, launch, spin and carry for PGA and LPGA players. Amateur data exists for the driver only, broken down by handicap. Apex and landing angle per club are fully published only in an older LPGA TrackMan sheet. No primary per-club data was found for amateur irons, wedges below PW, or putter launch.

### Cited Findings
**PGA Tour 2023**, from TrackMan's "Introducing Updated Tour Averages" (2 May 2024, tables are images), transcribed by Top Shelf Golf. Columns are club speed mph / ball speed mph / launch ° / spin rpm / attack ° / carry yd — [Top Shelf Golf](https://topshelfgolf.com/blogs/golf/golf-swing-speed-chart); [TrackMan blog](https://www.trackman.com/blog/golf/introducing-updated-tour-averages); same speed/spin/carry figures in [golfgaim](https://www.golfgaim.com/post/how-far-pga-tour-players-hit-every-club)

| Club | Club speed (mph) | Ball speed (mph) | Launch (°) | Spin (rpm) | Attack (°) | Carry (yd) |
|---|---|---|---|---|---|---|
| Driver | 115 | 171 | 10.4 | 2545 | -0.9 | 282 |
| 3-wood | 110 | 162 | 9.3 | 3663 | -2.3 | 249 |
| 5-wood | 106 | 156 | 9.7 | 4322 | -2.5 | 236 |
| Hybrid | 102 | 149 | 10.2 | 4587 | -2.4 | 231 |
| 3-iron | 100 | 145 | 10.3 | 4404 | -2.5 | 218 |
| 4-iron | 98 | 140 | 10.8 | 4782 | -2.9 | 209 |
| 5-iron | 96 | 135 | 11.9 | 5280 | -3.4 | 199 |
| 6-iron | 94 | 130 | 14.0 | 6204 | -3.7 | 188 |
| 7-iron | 92 | 123 | 16.1 | 7124 | -3.9 | 176 |
| 8-iron | 89 | 118 | 17.8 | 8078 | -4.2 | 164 |
| 9-iron | 87 | 112 | 20.0 | 8793 | -4.3 | 152 |
| PW | 84 | 104 | 23.7 | 9316 | -4.7 | 142 |

- **LPGA 2023**, same source. Columns are ball speed / launch / spin / carry:

| Club | Ball speed (mph) | Launch (°) | Spin (rpm) | Carry (yd) |
|---|---|---|---|---|
| Driver | 143 | 12.6 | 2506 | 223 |
| 3-wood | 135 | 11.6 | 2595 | 200 |
| 5-wood | 130 | 12.3 | 4320 | 189 |
| Hybrid | 125 | 13.9 | 4504 | 178 |
| 4-iron | 118 | 13.9 | 4608 | 175 |
| 5-iron | 114 | 14.6 | 4966 | 166 |
| 6-iron | 111 | 16.7 | 5904 | 155 |
| 7-iron | 106 | 18.5 | 6630 | 143 |
| 8-iron | 102 | 20.8 | 7413 | 133 |
| 9-iron | 95 | 23.5 | 7605 | 123 |
| PW | 88 | 25.2 | 8465 | 111 |

  Source: [Top Shelf Golf](https://topshelfgolf.com/blogs/golf/golf-swing-speed-chart)
- Smash factor (PGA/LPGA): driver 1.49/1.49, 3-wood 1.47/1.47, 5-iron 1.41/1.42, 7-iron 1.34/1.38, 9-iron 1.29/1.30, PW 1.24/1.25 — [Top Shelf Golf](https://topshelfgolf.com/blogs/golf/golf-swing-speed-chart)
- **Older LPGA TrackMan sheet** (pre-2019; the only per-club source with max height and land angle). Columns are ball speed mph / launch ° / spin rpm / max height yd / land angle ° / carry yd — [LPGA Tour Averages PDF](https://teeituprva.com/wp-content/uploads/2019/03/LPGA-AVERAGES-INTERACTIVE.pdf)

| Club | Ball speed (mph) | Launch (°) | Spin (rpm) | Max height (yd) | Land angle (°) | Carry (yd) |
|---|---|---|---|---|---|---|
| Driver | 140 | 13.2 | 2611 | 25 | 37 | 218 |
| 3-wood | 132 | 11.2 | 2704 | 23 | 39 | 195 |
| 5-wood | 123 | 12.1 | 4693 | 25 | 46 | 174 |
| 7-wood | 128 | 12.7 | 4501 | 26 | 43 | 185 |
| 4-iron | 116 | 14.3 | 4801 | 24 | 43 | 169 |
| 5-iron | 112 | 14.8 | 5081 | 23 | 45 | 161 |
| 6-iron | 109 | 17.1 | 5943 | 25 | 46 | 152 |
| 7-iron | 104 | 19.0 | 6699 | 26 | 47 | 141 |
| 8-iron | 100 | 20.8 | 7494 | 25 | 47 | 130 |
| 9-iron | 93 | 23.9 | 7589 | 26 | 47 | 119 |
| PW | 86 | 25.7 | 8403 | 23 | 48 | 107 |

- **Older PGA Tour TrackMan** (same era as the LPGA sheet): driver 167 mph ball speed, 10.9° launch, 2686 rpm, 275 yd carry; 6-iron 14.1°, 6231 rpm — [TrackMan "Ball Data" sheet](https://hankhaney.com/app/uploads/2019/01/ball_data.pdf)
- **TrackMan Combine amateur driver** (male). Columns are ball speed mph / launch ° / spin rpm / carry yd (carry from the older sheet; launch and spin also in the 2024 Top Shelf transcription):

| Golfer | Ball speed (mph) | Launch (°) | Spin (rpm) | Carry (yd) |
|---|---|---|---|---|
| Scratch | 161 | 11.2 | 2896 | 252 |
| 5 handicap | 147 | 11.2 | 2987 | 223 |
| 10 handicap | 138 | 11.9 | 3192 | 205 |
| Average (14.5 handicap) | 133 | 12.6 | 3275 | 195 |
| Bogey | 131 | 12.1 | 3127 | 184 |

  Female amateur driver: scratch 131/12.7/2831/197; 15 handicap 111/13.6/3287/149. Sources: [TrackMan Ball Data sheet](https://hankhaney.com/app/uploads/2019/01/ball_data.pdf); [Top Shelf Golf](https://topshelfgolf.com/blogs/golf/golf-swing-speed-chart)
- Tour apex: Golf Monthly reports a 2023 PGA driver max height of 35 yd. Other secondary sources say 30-35 yd through the bag (PGA) and 25-27 yd (LPGA) — [Golf Monthly](https://www.golfmonthly.com/tour/how-far-pga-tour-players-hit-every-club-in-the-bag); [Top Shelf Golf](https://topshelfgolf.com/blogs/golf/golf-swing-speed-chart)
- PGA Tour average driving distance (total, measured holes) in 2026 is reported as about 306 yd (secondary source) — [neogolfclub](https://www.neogolfclub.com/technology/tour-averages)
- Penner's model launches: a 35-55 m/s driver club speed gives 48.8-74.3 m/s ball speed, about 10.7° launch and 253-397 rad/s backspin. Landing speed is nearly constant at 26.8-26.2 m/s, landing angles 68.0°-46.2° from vertical (22°-43.8° from horizontal) and landing backspin 224-315 rad/s. For irons at 40 m/s club speed: 1-iron to 9-iron launch at 56.6-42.5 m/s, 13.8°-35.4°, 372-915 rad/s, and land at 24.7-23.8 m/s, 51.9°-34.0° from vertical, 313-809 rad/s — [Penner 2002](http://waddengolfacademy.com/putting/Penner_The%20Run%20of%20a%20Golf%20Ball.pdf)
- TrackMan's Ball Data sheet says 1 mph of ball speed is worth up to about 2 yd of driver distance — [TrackMan Ball Data sheet](https://hankhaney.com/app/uploads/2019/01/ball_data.pdf)

### Inferences
- **Landing state** from my RK4 recommended model, useful as bounce-model inputs:
  - Tour driver lands at about 25 m/s, 40° from horizontal, with roughly 75 % of launch spin remaining.
  - Tour 7-iron lands at about 22 m/s, 54°; PW at about 21 m/s, 55°.
  - These match Penner's finding that landing speed is about 21-27 m/s for every full shot. Landing angle and spin, not speed, differentiate clubs on the ground.
- **Amateur irons** (no primary data): scale the PGA ball speed per club by the driver ball-speed ratio (133/171 = 0.78 for a 14.5 handicap). Raise launch about 1-2° and keep spin at about 85-95 % of tour. This is a game-design heuristic, not measured.
- **Game presets** can reuse the PGA table as "pro" and the 14.5-handicap driver row scaled through the bag as "casual".

### Gaps
- No primary 2023 PGA per-club max height or land angle (the TrackMan images were not machine-readable). A commonly circulated older PGA table (about 32 yd apex, about 37-38° land for driver; about 50-52° for short irons) could not be verified here.
- No published TrackMan or Foresight averages were found for gap/sand/lob wedges, partial wedges, chips, or putter launch (launch angle, skid distance).
- The sources disagree on whether TrackMan publishes an amateur 7-iron (about 80 mph club speed / 116 mph ball speed / 145 yd is circulated but disputed).

---

## 3. Sidespin / spin-axis tilt and wind

### Takeaway
Curvature comes from tilting the spin axis: the Magnus force (ω x v) gains a lateral component of about Cl x sin(tilt). TrackMan treats -2° to +2° as straight, and 10° of tilt gives about 15 yd of curve on a 200-yd shot. Wind should be modelled as an air-velocity offset in the drag/lift relative velocity. Head/tail winds are strongly asymmetric: about -7.5 % / +5 % carry for 10 mph. With a constant-wind relative-velocity model, my RK4 reproduced published 7-iron wind deltas closely.

### Cited Findings
- TrackMan spin axis: negative = curves left, positive = right, measured relative to the horizon. It is set at impact and stays constant in flight. Wind pushes the ball but does not change the axis. -2° to +2° counts as straight. An example table for an optimized 200-yd shot lists axis 10° as about 15 yd of curve and axis 2° as about 3 yd (table layout jumbled; verify) — [TrackMan: Spin axis](https://trackman.com/blog/golf/spin-axis)
- TrackMan: 1° of face-to-path difference at 300 yd gives about 12 yd of curve. The ball curves toward the face and away from the path (centred strike) — [TrackMan: Face to path](https://trackman.com/blog/golf/face-to-path)
- Wind, tour 7-iron (166 yd, TrackMan-based calculator): a 10 mph tailwind adds 13 yd and a 10 mph headwind costs 17 yd — [Golf Digest](https://www.golfdigest.com/story/weve-taken-the-guesswork-out-of-playing-in-the-wind-with-this-powerful-new-tool)
- Wind, PGA-average 7-iron: 10 mph headwind -19.2 yd, tailwind +14.6 yd. PGA-average drive: 30 mph headwind -75 yd, tailwind +44 yd — [Golfing Focus](https://golfingfocus.com/what-affects-golf-ball-distance-beware-all-the-uncontrollables/)
- Rule of thumb: a 10 mph wind is a "one-club wind", giving +5 % carry downwind and -7.5 % into the wind — [The Golf News Net](https://thegolfnewsnet.com/ryan_ballengee/2024/08/22/how-to-calculate-distances-in-golf-with-the-wind-and-into-the-wind-127728/)
- Crosswind: about 12 yd lateral for a 10 mph crosswind (blog estimate) — [Cubical Golfer](https://www.cubicalgolfer.com/golf-wind-adjustment-chart/)
- libgolf applies a single horizontal wind vector above a height threshold hWind and zero wind below it. Drag and Magnus use v - v_wind. Users can override wind as a function of position to model gradients — [libgolf](https://gdifiore.github.io/libgolf/docs/aerodynamic_model.html)

### Inferences
- **Implementation**: store spin as a vector ω = |ω| x axis. For backspin with tilt τ about the flight direction (x downrange, y up, z = x × y, which points left), use axis = (0, sin τ, cos τ). Then (axis x v_hat) gives lift (0, cos τ, -sin τ): up, plus rightward for positive τ (TrackMan positive = right). Keep the axis constant in flight (TrackMan) and decay only the magnitude.
- **My 3D RK4 check** (recommended aero, constant wind at all heights):
  - Tour 7-iron: 10 mph headwind -20.6 yd, tailwind +14.5 yd. This matches Golfing Focus's -19.2/+14.6 within about 1.5 yd.
  - Tour driver: -19.2 / +15.8 yd.
  - A 10 mph pure crosswind drifted both about 16-17 yd with no carry change.
  - Spin-axis tilt of 2/5/10/20° gave about 4/9/18/35 yd lateral on the 7-iron and 4/10/20/38 yd on the driver; a 5-iron (206 yd) at 10° went about 21 yd.
  - That is about 30 % more than TrackMan's "about 15 yd at 10°, 200 yd". Either damp lateral lift (multiply the side component by about 0.75) or accept the stronger shaping for gameplay readability.
- **Wind gradient** (cheap): scale wind by a power law, w(h) = w_ref x (h / h_ref)^α with α of about 0.14-0.2 and h_ref = 10 m, clamped to >= 0.3 near the ground. Alternatively use libgolf's simpler step (zero below h_wind). Uniform wind overstates the effect on low shots and putts; apply zero wind to rolling balls on the green. α is a standard boundary-layer value, not from a golf source.

### Gaps
- No peer-reviewed measured data on crosswind drift or wind-gradient profiles over golf courses was found. The figures here are TrackMan-calculator or blog derived.
- TrackMan's yards-per-degree table was garbled in extraction.

---

## 4. Landing: bounce on turf (fairway, rough, green, sand, hard)

### Takeaway
The standard cheap model is Penner (2002): a rigid-surface Daish bounce with restitution e and Coulomb friction μ, applied in a frame rotated by an effective crater angle θc that grows with impact speed and angle. With μ = 0.40 (soft green) a ball with enough landing backspin bounces backward. With μ = 0.25 (firm tournament green) it hops forward with backspin and then spins back 1-5 m. Modern data (Biber et al. 2023, about 1000 bounces) show Penner is only modestly better than a rigid bounce, and that a fixed tilt angle β fits as well. Tune per-surface (e, μ, β) to produce target roll-outs rather than trusting any single fit. No published measured parameters were found for rough, sand or cart paths.

### Cited Findings
- **Penner's bounce in the rotated frame** x', y' (y' normal to the equivalent surface tilted by θc; |v_iy'| is the inbound normal speed) — [Penner 2002](http://waddengolfacademy.com/putting/Penner_The%20Run%20of%20a%20Golf%20Ball.pdf)
  - Sliding throughout impact (μ < μc):
    - v_rx' = v_ix' - μ |v_iy'| (1+e)
    - v_ry' = e |v_iy'|
    - ω_r = ω_i - (5μ / 2r) |v_iy'| (1+e)
    - Here the bounce is independent of the inbound spin.
  - Rolling out of impact (μ >= μc):
    - v_rx' = v_ix' - (2/7)(v_ix' + r ω_i) = (5/7) v_ix' - (2/7) r ω_i (ω_i > 0 = backspin). The PDF text extraction of Penner's eq. 3a is garbled; this is the Daish rolling result, and it is consistent with Penner's spin-back condition (eq. 10) and μc (eq. 4).
    - v_ry' = e |v_iy'|
    - ω_r = -v_rx' / r (topspin, rolling)
  - Critical friction: μc = 2 (v_ix' + r ω_i) / (7 (1+e) |v_iy'|)
  - Frame transforms:
    - v_ix' = v_ix cos θc - |v_iy| sin θc
    - |v_iy'| = v_ix sin θc + |v_iy| cos θc
    - v_rx = v_rx' cos θc - v_ry' sin θc
    - v_ry = v_rx' sin θc + v_ry' cos θc
- **Penner's restitution** (fit to his own data on relatively soft turf; impact normal speed in m/s):
  - e = 0.510 - 0.0375 |v_iy'| + 0.000903 |v_iy'|^2 for |v_iy'| <= 20 m/s
  - e = 0.120 for |v_iy'| > 20 m/s
  - Source: [Penner 2002](http://waddengolfacademy.com/putting/Penner_The%20Run%20of%20a%20Golf%20Ball.pdf)
- **Penner's crater angle**: θc = 15.4° x (v_i / 18.6 m/s) x (φ / 44.4°), with φ = atan(|v_ix / v_iy|) measured from vertical. It is calibrated on Haake's single green bounce:
  - Inbound 18.6 m/s at 44.4° from vertical with 484 rad/s backspin.
  - Measured outbound 5.1 m/s at 33.0° with 145 rad/s topspin.
  - Model outbound 4.34 m/s at 34.1° with 154 rad/s topspin.
  - That impact implies e = 0.14 and μ > μc = 0.29.
  - Source: [Penner 2002](http://waddengolfacademy.com/putting/Penner_The%20Run%20of%20a%20Golf%20Ball.pdf)
- **Friction values**: Daish suggests μ = 0.40 for a ball sliding on a green. Penner argues tournament greens behave like μ of about 0.25, because that reproduces the observed bounce-forward-then-spin-back — [Penner 2002](http://waddengolfacademy.com/putting/Penner_The%20Run%20of%20a%20Golf%20Ball.pdf)
- **Spin-back condition**: the ball bounces backward (in x') if ω_i > 5 v_ix' / (2r). For the 9-iron example (23.8 m/s, 34.0° from vertical) the critical spin is 903 rad/s; the actual landing spin was 809 rad/s, and it still bounced backward in world x after the frame rotation.
  - μc for landing spins of 809 / 1000 / 1200 rad/s = 0.28 / 0.33 / 0.38.
  - With μ = 0.25 (firm green) the ball hops forward with backspin, then runs back about 0 / 1.11 / 4.74 m for 809 / 1000 / 1200 rad/s.
  - Source: [Penner 2002](http://waddengolfacademy.com/putting/Penner_The%20Run%20of%20a%20Golf%20Ball.pdf)
- **Penner's run results**:
  - Drives: μc of about 0.18-0.23, so all drives roll out of the first bounce (μ = 0.40). First-bounce height is 2.82 m (35 m/s club speed) down to 1.17 m (55 m/s). Total run decreases with club speed because faster swings land steeper.
  - Irons: first-bounce height 0.97 m (2-iron, landing 42.8° from vertical) to 0.54 m (6-iron, 36.3°).
  - Impact angle is the dominant run factor for drives and long irons; backspin dominates for high-lofted irons.
  - Model run vs launch speed agreed "fairly well" with Cochran & Stobbs and Williams empirical data, slightly long because real ground is not flat.
  - Source: [Penner 2002](http://waddengolfacademy.com/putting/Penner_The%20Run%20of%20a%20Golf%20Ball.pdf)
- **Bounce-to-roll transition**: a ball at rest sits about 2 mm below the green surface (Hubbard & Alaways). Penner switches from bouncing to rolling when bounce height falls below 5 mm; any value from 1 to 10 mm had only a minor effect on run — [Penner 2002](http://waddengolfacademy.com/putting/Penner_The%20Run%20of%20a%20Golf%20Ball.pdf)
- **Biber, Jones (R&A), Champneys, Green & Szalai 2023**: over 1000 bounces with a modern tour ball, inbound speeds up to 56 m/s and spins from -3880 to +16200 rpm. Best fits — [Biber et al. 2023, arXiv:2302.02758](https://arxiv.org/pdf/2302.02758)
  - Campaign A, artificial turf:
    - Rigid model: r = 0.544, μ = 0.997.
    - Penner (β = kP x speed x angle, kP = 1.543e-4): r = 0.448, μ = 0.969.
    - Fixed β = 12.9°: r = 0.420, μ = 0.852.
  - Campaign B, natural tee turf:
    - Rigid model: r = 0.260, μ = 0.998.
    - Penner (kP = 2.973e-4): r = 0.222, μ = 0.999.
    - Fixed β = 18.4°: r = 0.147, μ = 0.998.
  - Errors in horizontal velocity and spin stay large: rigid about 19-25 %, Penner about 9-16 %. A piecewise-affine slip/roll fit was about 5x better.
  - Balls that enter rolling usually lift off slipping the other way (spin reversal). Pure-rolling lift-off was rarely seen.
- **libgolf's simpler bounce**:
  - v_n' = -COR v_n and v_t' = frictionFactor x v_t.
  - A Penner spin term (2 r |ω| / 7) reduces v_t' without reversing it.
  - ω' = spinRetention x ω.
  - frictionFactor = 1 - frictionStatic (1 - firmness).
  - Example only: COR 0.35, tangential retention 0.6.
  - Source: [libgolf bounce model](https://gdifiore.github.io/libgolf/docs/bounce_model.html)

### Inferences
- **Recommended cheap model**: Penner's Daish bounce with a per-surface fixed β (simpler and, per Biber, no worse than Penner's θc formula). Per-surface parameters (e as a function of v_n, μ, β).
- **Defaults derived from the cited fits**:
  - Green (soft): e = Penner e(v_n), μ = 0.40, β = 15°.
  - Green (firm): e = Penner e(v_n) x 1.1, μ = 0.25, β = 10-12°.
  - Fairway: e of about 0.20-0.26 (Biber natural turf, rigid fit), μ = 0.4-0.6, β of about 15-18°.
  - Hard/artificial surface or cart path: e of about 0.42-0.55 (Biber artificial), μ of about 0.5, β of about 0-5° (unsourced for asphalt).
  - Rough: e of about 0.10-0.15, μ of about 0.6-0.8, plus extra tangential damping (unsourced).
  - Sand: e of about 0.0-0.05; plug or stop within 1-2 bounces (unsourced).
  - Validate by first-bounce height: about 1-3 m for drives and about 0.5-1 m for mid irons (Penner).
- **Spin-back sanity checks**:
  - A firm-green wedge with about 1000-1200 rad/s landing spin should run back about 1-5 m.
  - Penner's 809 rad/s 9-iron should roughly stop.
- **Game-feel note**: TrackMan-like tour 7-irons land at about 54-55° in my RK4 (TrackMan's LPGA sheet says 47°). Such balls have v_ix of about 13 m/s, so spin-back needs ω > 5 x 13 / (2 x 0.0213) = about 1500 rad/s in the unrotated frame. The tilted frame (β) is what makes spin-back reachable at realistic spins, so keep β > 0 on greens.

### Gaps
- No measured COR or friction for rough, bunker sand, or hard pan/cart paths was found in the literature searched.
- No published per-club roll-out distances (carry vs total) by surface were found beyond Penner's figures (values only plotted). The PGA 2026 total of about 306 yd vs about 282 yd carry suggests about 20-25 yd of driver roll on tour fairways, but these come from different datasets.
- Haake (1990) and the Biber data repository contain more data but were not retrieved.

---

## 5. Rolling: resistance, Stimpmeter conversion, slopes, break, sleeping

### Takeaway
A rolling ball on a green decelerates at a roughly constant a = v0^2 / (2 x Stimp). v0 is the Stimpmeter exit speed, 6.0-6.27 ft/s (1.83-1.91 m/s). That gives 0.69-0.75 m/s^2 at Stimp 8, 0.55-0.60 at Stimp 10 and 0.46-0.50 at Stimp 12. On slopes, add (5/7) g sin θ along the fall line, because a rolling solid sphere only feels 5/7 of the gravity component. Penner's putting value (ρg = 0.131, so a = 0.92 m/s^2) corresponds to a slow green of about Stimp 6.

### Cited Findings
- Stimpmeter: 36-in bar, release notch 30 in from the tapered end, ball releases at about 20°. There is also a half-length notch at 14 in — [USGA Stimpmeter instructions (MSU archive)](https://archive.lib.msu.edu/tic/holen/article/2000aug24.pdf); [golf.com](https://golf.com/instruction/what-is-stimp-stimpmeter-how-work/)
- Exit speed is about 6.00 ft/s (1.83 m/s) per one source — [Probable Golf Instruction](https://probablegolfinstruction.com/Stimpmeter.htm). Rolling-sphere derivation: a_ramp = (5/7) g sin 20° = 7.87 ft/s^2, giving v_s = sqrt(2 x 7.87 x 2.5) = 6.27 ft/s (1.91 m/s); 6.0 ft/s is the common round value — [Lee 2025](https://stephenlee.info/golf/physics/2025/11/16/rederiving-aimpoint.html)
- Deceleration: a_f = -v_s^2 / (2S), which is -19.7/S ft/s^2 with S in ft. Effective deceleration on a slope with grade X (uphill positive) is a_eff of about -(19.7/S + 23X) ft/s^2. Effective Stimp is S_eff of about S / (1 + 1.17 X S) — [Lee 2025](https://stephenlee.info/golf/physics/2025/11/16/rederiving-aimpoint.html)
- Stimp 12 is about 1.5 ft/s^2 (0.457 m/s^2), and only 5/7 of the slope pull accelerates a rolling ball — [Dillon](https://tkevindillon.substack.com/p/dies-at-the-hole)
- Penner's rolling deceleration is a = -(5/7) ρg g, with ρg = 0.131 measured for "a typical golf green". Penner also used it for fairways while noting fairway ρ should be larger — [Penner 2002](http://waddengolfacademy.com/putting/Penner_The%20Run%20of%20a%20Golf%20Ball.pdf); original [Penner, "The physics of putting", Can. J. Phys. 80:83 (2002)](https://www.researchgate.net/publication/237196126_The_physics_of_putting)
- Break (Lee's approximation, inches): x_break of about 12 g X_s S (sqrt(D+R) - sqrt(R))^2 / (19.7 + 23 S X). Lee's table uses side slopes of 1-3 % and forward slopes of -3 % to +3 %. It gives about 7.5 in of break for a 10-ft putt at Stimp 10 on a 1 % side slope. Note that Lee uses a_lat = g X_s and adds a heuristic 5/7 "damping" factor — [Lee 2025](https://stephenlee.info/golf/physics/2025/11/16/rederiving-aimpoint.html)

### Inferences
- **Stimp to deceleration** (a = v0^2/(2 S_m), S_m = Stimp_ft x 0.3048; range is v0 = 1.83 to 1.91 m/s):

| Stimp (ft) | Deceleration (m/s^2) | μ_eff = a/g |
|---|---|---|
| 7 | 0.79-0.85 | about 0.08 |
| 8 | 0.69-0.75 | |
| 9 | 0.61-0.67 | |
| 10 | 0.55-0.60 | about 0.06 |
| 11 | 0.50-0.54 | |
| 12 | 0.46-0.50 | about 0.05 |
| 13 | 0.42-0.46 | |

  The table is self-consistent with Dillon's 0.457 m/s^2 at Stimp 12 for v0 = 1.83. Penner's 0.918 m/s^2 is equivalent to Stimp of about 6.0-6.5.
- **Fairway and rough**: no sourced deceleration values. Suggested start points are fairway Stimp-equivalent of about 3-5 ft (a of about 1.2-2.0 m/s^2) and rough about 1-2 ft (a of about 3-6 m/s^2). Tune so a tour driver rolls about 15-25 yd on a firm fairway.
- **Rolling integration** (constant-deceleration Coulomb-like model on a slope with unit normal n):
  - g_t = g - (g·n) n is the in-plane gravity component.
  - a = (5/7) g_t - a_roll(surface) x v_hat. Use 5/7 on g_t for a rolling solid sphere, which is consistent with the Stimpmeter derivation.
  - If |v| < v_sleep, set v = 0, and only wake the ball if (5/7)|g_t| > a_static(surface).
  - Starting values: a_static = 1.0-1.2 x a_roll, v_sleep of about 0.02-0.05 m/s, plus a hard cap on roll time (for example 30 s) to guarantee termination.
  - On a green with a_roll = 0.55 m/s^2 the ball can rest on slopes up to about asin(0.55 / 7.0), which is about 7.9 % grade. Real tournament pins sit on much gentler slopes. Raise a_static, or add Penner's 2 mm sink as a small static hold, if balls creep unrealistically.
  - Integrate rolling with the same fixed step, and clamp the deceleration so it cannot reverse velocity within a step. This avoids jitter at stop.
- **Putting speed reference**: to finish 0.4-0.5 m past a cup 3 m away on Stimp 10 (a of about 0.6), v0 = sqrt(2 x 0.6 x 3.45), which is about 2.0 m/s. Arrival speed at the cup is then sqrt(2 x 0.6 x 0.45), about 0.73 m/s, well under the capture limits in section 6.

### Gaps
- No measured speed dependence of green rolling resistance was retrieved. Some studies report non-constant deceleration at very low speeds and an initial skid phase.
- No measured fairway or rough rolling resistance was found.
- No USGA-published official exit speed: 6.0 vs 6.27 ft/s both circulate.

---

## 6. Cup capture and lip-outs

### Takeaway
For a putt rolling straight at the cup centre on a level green, free fall alone captures balls below about 1.31 m/s (Holmes 1991). Including rim-assisted capture off the back lip, the limit is about 1.63 m/s (Penner 2002; a 2025 paper reports 1.626 m/s). The limit falls for off-centre approaches. A cheap geometric free-fall criterion reproduces 1.31 m/s exactly, and extends naturally to offset b and to a rim-assist factor.

### Cited Findings
- Holmes, "Putting: How a golf ball and hole interact", Am. J. Phys. 59, 129-136 (1991; DOI 10.1119/1.16592). Analyses balls falling in at the far lip and balls that run around the rim and jump out — [Cross, Univ. Sydney golf physics page](https://www.physics.usyd.edu.au/~cross/GOLF/GOLF.htm); [Quintic / Sheppard et al. 2016](https://www.quinticballroll.com/research-papers/Quintic-An-Investigation-in-to-Golf-Ball-Speed-at-Hole-Entry.pdf)
- Front-edge free-fall capture requires v < 1.31 m/s (Holmes 1991, as cited) — [Quintic / Sheppard et al. 2016](https://www.quinticballroll.com/research-papers/Quintic-An-Investigation-in-to-Golf-Ball-Speed-at-Hole-Entry.pdf)
- Penner (2002) gives a capture limit of about 1.63 m/s (5.35 ft/s) for a centred approach, level green, flagstick out, including help from the far rim. Free fall alone holds the ball only below about 1.31 m/s. The limit drops for off-centre approaches. Penner's capture boundary is a fit to Holmes's model — [Dillon](https://tkevindillon.substack.com/p/dies-at-the-hole)
- A 2025 mechanics-of-lip-out paper states a ball must travel at <= 1.626 m/s to be captured (full text not retrieved) — [Mechanics of the golf lip out, PMC12585879](https://pmc.ncbi.nlm.nih.gov/articles/PMC12585879/)

### Inferences
- **Geometric free-fall test** (derived; reproduces Holmes):
  - Cup radius R = 0.054 m, ball radius r_b = 0.021335 m, lateral offset b of the ball-centre path from the cup centre.
  - The ball loses support once its centre passes the near edge. It is captured if its centre drops at least r_b before it reaches a point r_b short of the far edge.
  - Chord L(b) = 2 sqrt(R^2 - b^2). Capture if v <= v_ff(b) = (L(b) - r_b) x sqrt(g / (2 r_b)).
  - At b = 0: (0.108 - 0.0213) x sqrt(9.81 / 0.0427) = 0.0867 x 15.16 = 1.31 m/s, which matches Holmes's number.
  - v_ff(b) falls to 0 when L(b) = r_b, i.e. |b| = sqrt(R^2 - r_b^2/4) = 0.053 m.
  - For capture only when the ball's centre passes over the hole, require |b| < R.
- **Rim assist**: scale to v_max(b) = 1.24 x v_ff(b), so 1.63 m/s at b = 0, matching Penner. Between v_ff and v_max, resolve as "hits the back lip and drops". Above v_max, either lip out or hop over: deflect the direction by an angle proportional to b/R and keep about 50-70 % of speed (tuning; unsourced).
- **Edge hang**: a ball stopping with its centre within R of the cup centre should drop; the gravity torque about the rim beats static hold. One stopping beyond R by less than about 1 mm can be given the "hangs on the lip" treatment (cosmetic).
- **Gameplay**: optimum putt arrival speed is well below 1.31 m/s; aim to finish about 0.3-0.5 m past.

### Gaps
- Penner's exact holeout condition as a function of offset (formula) was not retrieved. The original Holmes and Penner papers are behind paywalls, and the 2025 PMC paper failed to load.
- There is no sourced lip-out deflection model; the treatment above is a design heuristic.

---

## 7. Validation tests (what proves the simulation is right)

### Takeaway
Validate against TrackMan tour tables (carry within about 3-5 % for driver through 7-iron; wedges within about 8 %), the older LPGA sheet's apex and landing angle (within about 3 yd and 3-4°), published wind deltas, Penner's bounce and spin-back behaviour, Stimpmeter self-consistency and Holmes/Penner cup limits. Add determinism and symmetry tests.

### Cited Findings
- Carry targets (yd, flat landing, still air) per club for PGA and LPGA 2023 are in section 2 — [Top Shelf Golf / TrackMan 2024](https://topshelfgolf.com/blogs/golf/golf-swing-speed-chart)
- Apex and landing-angle targets (LPGA older sheet): driver 25 yd / 37°, 7-iron 26 yd / 47°, PW 23 yd / 48° — [LPGA Tour Averages PDF](https://teeituprva.com/wp-content/uploads/2019/03/LPGA-AVERAGES-INTERACTIVE.pdf)
- Carry definition: distance to where the trajectory returns to launch height ("carry flat") — [TrackMan Ball Data sheet](https://hankhaney.com/app/uploads/2019/01/ball_data.pdf)
- Wind targets: tour 7-iron, 10 mph, -17 to -19 yd head and +13 to +15 yd tail — [Golf Digest](https://www.golfdigest.com/story/weve-taken-the-guesswork-out-of-playing-in-the-wind-with-this-powerful-new-tool); [Golfing Focus](https://golfingfocus.com/what-affects-golf-ball-distance-beware-all-the-uncontrollables/)
- Bounce targets: Haake inbound (18.6 m/s, 44.4° from vertical, 484 rad/s backspin) -> outbound about 5.1 m/s, 33°, 145 rad/s topspin (Penner's model: 4.34 m/s, 34.1°, 154 rad/s). Spin-back of 1.1 m and 4.7 m for 1000 and 1200 rad/s on a μ = 0.25 green — [Penner 2002](http://waddengolfacademy.com/putting/Penner_The%20Run%20of%20a%20Golf%20Ball.pdf)
- Cup targets: centre-line capture 1.31 m/s (free fall) and 1.63 m/s (with rim) — [Dillon](https://tkevindillon.substack.com/p/dies-at-the-hole); [PMC12585879](https://pmc.ncbi.nlm.nih.gov/articles/PMC12585879/)

### Inferences (suggested headless unit tests for the pure-logic sim)
1. **Carry table**: PGA driver/3W/5i/7i/PW launch rows -> carry within ±5 % (driver-7i) and ±8 % (PW) of 282/249/199/176/142 yd. Also LPGA driver/7i/PW -> 218/141/107 yd ±5 %. In my check the recommended model gave 274/260/206/174/131 and 222/141/102.
2. **Apex and landing angle**: LPGA rows give apex within ±3 yd and landing angle within ±4° of the sheet.
3. **Symmetry**:
   - Zero spin-axis tilt and zero crosswind -> lateral |z| < 1e-9 m.
   - Tilt +τ vs -τ -> mirror-image lateral results, with carries equal to 1e-9.
   - Zero spin (S = 0) -> Cl = 0, and a pure-drag trajectory shorter than with backspin.
4. **Spin monotonicity**: for driver launch, carry vs spin over 1500-4500 rpm should peak (not be monotonic). Verify the optimum is roughly 2000-3000 rpm at 70-77 m/s ball speed (inference; no source retrieved).
5. **Wind**: 10 mph head/tail on the PGA 7-iron -> about -19 ±3 yd / +14 ±3 yd. Headwind loss must exceed tailwind gain (asymmetry). Pure crosswind should change carry by < 1 %.
6. **Curvature**: 10° tilt on a ~200 yd shot -> 15-21 yd lateral (TrackMan about 15, my model about 21; pick a tolerance that matches the game's tuning).
7. **Timestep invariance**: carry at a 60 Hz vs 240 Hz tick differs by < 0.5 m (my check: < 0.3 m). Same seed and inputs -> bit-identical final position across 1000 runs.
8. **Bounce**: Haake inbound -> outbound speed 4-5.5 m/s and topspin out. For a μ = 0.25 green, 1200 rad/s landing spin (23.8 m/s, 34° from vertical) -> net backward run of 3-6 m; 809 rad/s -> about 0 m.
9. **Stimp self-test**: release a rolling ball at 1.83 m/s on a flat green configured at Stimp N -> it stops at N ft ±2 %.
10. **Slope**: a ball at rest on a grade below a_static/((5/7) g) stays asleep; above it, it accelerates downhill at (5/7) g sin θ - a_roll.
11. **Cup**: centre-line ball at 1.30 m/s -> holed with no rim contact. At 1.60 m/s -> holed via the rim. At 1.70 m/s -> lip-out or hop. Offset b = 0.05 m at 0.5 m/s -> holed. Offset b = 0.055 m -> miss (centre outside the cup).

### Gaps
- No public validation data was found for chip/pitch shots (< 60 yd), bunker shots, or putter skid-to-roll transition. These need tuning by feel or against video.
- The driver optimum-spin claim (test 4) is unsourced here.
