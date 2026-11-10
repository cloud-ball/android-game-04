---
name: ai-opponent
description: Implement or tune a CPU opponent and report self-play win rates per difficulty.
---
# /ai-opponent <game> <easy|medium|hard>
1. Implement against shared/ai_common (difficulty knobs = sample count, noise, depth, reaction time).
2. Run 200 self-play games headless vs the scripted baseline with fixed seeds.
3. Targets vs baseline: Easy ~25% win, Medium ~50%, Hard ~70%. Report a table and adjust knobs (data only).
4. The AI must use the same simulation/rules code as the player — never a separate "cheating" model.
