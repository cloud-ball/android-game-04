# Name alignment and stale-code cleanup (2026-11-19)

Goal: one name per thing everywhere in the repo, and no code left over from abandoned designs.
Current names: app **Playjar** (was Pocket Arena 8, briefly Octorival), block game **Facetfall**
(was Stack Drop), golf game **Cup Dash** (was Fairway Flick), pool game **Break & Bank** (was Cue
Club; "Break and Bank" in file names). Game ids (snake, blocks, pool,
golf, ...), the package id, save keys and user:// paths do NOT change (saves stay compatible).

## Steps
1. Stale code (long-course golf, replaced by mini-golf on 2026-11-15; no runtime users):
   remove `games/golf/logic/hole_baker.gd`, `games/golf/logic/golf_clubs.gd`,
   `games/golf/data/holes/` and `games/golf/tests/hole_baker_test.gd` (it only tests those two).
   Kept: GolfFlight / GolfParams / GolfBall.strike - mini-golf hops fly through the same solver
   and the golden-hash, carry and timestep tests guard its determinism.
2. Blocks code: `Stack*` classes (from "Stack Drop") become `Blocks*` like every other game's
   id prefix: StackAI, StackDifficulty, StackGestures, StackLogic, StackState and their files
   and tests; `tools/stack_selfplay.gd` -> `tools/blocks_selfplay.gd`.
3. Text: "Fairway Flick" -> "Cup Dash", "Stack Drop" -> "Facetfall", "Pocket Arena 8" ->
   "Playjar", "Cue Club" -> "Break & Bank" in code comments, tools, rules, docs, research and the progress log, except lines
   that record a rename (formerly / was / renamed / history).
4. File names: docs/plans/*fairway-flick* -> *cup-dash*, *stack-drop* -> *facetfall*;
   docs/research/"Fairway Flick ..." -> "Cup Dash ...", "Stack Drop board redesign" ->
   "Facetfall board redesign", "Cue Club ..." -> "Break and Bank ..."; *cue-club* plans ->
   *break-and-bank*; docs/design/PocketArena8_Build_Guide.pdf ->
   Playjar_Build_Guide.pdf (contents unchanged: the original guide). References updated.
5. Build scripts: PA8_KEYSTORE / PA8_KEYSTORE_PASS / PA8_KEY_ALIAS -> PLAYJAR_*; daily seed
   string "pa8-daily" -> "playjar-daily" (nothing shipped yet, so no player sees a change).
6. Local branch fairway-flick -> cup-dash (never pushed).

## Gates
Full test suite green, gdlint clean, import with no new warnings, golf and blocks launch and
screenshot fine, `git grep` for the old names only finds rename-history lines.
