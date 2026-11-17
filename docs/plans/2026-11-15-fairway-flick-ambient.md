# Fairway Flick: ambient life (visual step 6)

Source: docs/research/Fairway Flick mini golf visuals.md, upgrade plan row 6. Gate: 60 fps on the
test phone, ambient work under ~10-15% of frame time, no new per-frame allocations, everything
render-only (the solver never sees it).

## Changes
1. KitBatch rewrite: models are de-indexed once at load and placed with native packed-array
   transforms (no index offsets), and each vertex carries a sway weight in COLOR.r (height within
   the model, 0 for props that must not move such as rocks, logs, pots, fences, mushrooms and tree
   trunks). Swaying surfaces use one shared foliage shader: a two-sine wind gust travelling across
   the world, weight squared so bases stay planted. Leaves move up to ~0.2 m at a tree top; bushes,
   grass and flowers ~5 cm.
2. Terrain shader: slow cloud shadows (large soft value-noise blobs drifting with time, at most
   13% darker), on the course and the lawn apron alike.
3. Flag: the cloth gets a ripple shader (subdivided box), travelling away from the pole.
4. AmbientLife node: four or five butterflies looping over Ring 1 flower spots near play, and a
   small flock of birds circling high around the landmark. One MultiMesh each (two draw calls),
   wings flapped in the vertex shader, transforms updated in `_process` with value types only.
5. Reduce motion (Settings): no critters, no sway, no flag ripple, clouds frozen.

## Tests
- KitBatch weights: a swaying model's weights run 0 at its base to 1 at its top; a still model's
  are all 0; vertex counts match index counts after de-indexing.
- AmbientLife paths are pure functions of time and seed: same inputs give the same transform, and
  butterflies stay within their loop radius and above the lawn.
