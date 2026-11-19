# Cup Dash: landmark and framing (visual step 4)

Source: docs/research/Cup Dash mini golf visuals.md, upgrade plan row 4 and "Reviewers reward
themed places". Gate: the play-view screenshot shows the landmark; draw calls ≤ 100; 60 fps on the
test phone.

## Problems seen in today's play-view screenshots
- The windmill stands 70 m out and 35 m to the side, so it is cut off at the frame edge or missing.
- Big trees stand right beside the course and block it near the camera (holes 2 and 3).
- Beyond the 7 m lawn margin there is no ground, only the sky's ground colour; the skyline is a
  thin hill ring 700 m away, so the top third of the frame is empty.

## Changes
1. `logic/mini_framing.gd` (pure, tested): `landmark_spot(hole, view)` puts the landmark straight
   ahead of the tee view, 30 m past the far edge of the course, 3 m to the side away from the cup
   (so it never hides the flag). `clear_of_course(hole, x, z, r)` keeps trees and backdrop pieces
   away from play.
2. `MiniBaker.flow_dir()` replaces golf_game's private `_flow_dir` so the tee view is testable.
3. GolfScenery:
   - (GolfTerrain) a lawn apron of four strips around the baked grid, same material, so the
     ground continues to the horizon without ever covering the course's pits;
   - a mid skyline ring (rolling hills 90-160 m out with a tree line, two draw calls), compressed
     toward the sky colour by fog;
   - trees at least 6 m from play, and never where their shadow falls on the course;
   - an original landmark at the framed spot: a stone windmill-tower on a grassy knoll, with a
     balcony, a door, a window, a coloured cap and lattice sails that turn slowly.
4. Intro fly-over opens on the landmark (an establishing shot over the course), then glides down
   to the aiming view.
5. Ring 1 (0.5-2 m outside the rails): add low stones beside the bushes and flowers, all below
   rail height.

## Out of scope (later steps)
CC0 kit props and vignettes (step 5), ambient life (step 6), other worlds (step 9).

## Tests
`golf_framing_test.gd`: for every meadow hole, the landmark is 30-80 m from the tee, within 12°
of the tee view, and at least 10 m clear of play; tree clearance rejects course cells; the tee view
of "Corner" points up its first leg.
