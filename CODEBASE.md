# Codebase facts

Things true of the build, not of the design. Split out of DESIGN.md because
these rot whenever the code changes, and mixing them in made the design doc feel
stale for reasons that had nothing to do with design.

A fact belongs here if changing the code changes it. If changing the code would
require reopening an argument, it is a decision and belongs in DESIGN.md.

## City generation

- Kit grid unit is ~9m. `STREET_WIDTH` is 9.0 so road tiles are exact. *The
  choice to derive this from cones and barriers rather than streetlights is a
  decision, recorded in DESIGN.md.*
- Blocks are two rows of buildings back to back, each facing its own street.
  Block depth 22 to 32. Block interior is a service alley.
- ~275 buildings per city. Median stretch 1.13, scale 1.02x human.
- Named locations sit one per block, on the widest lot. Makes the city more
  legible than a real one. Cap slated for removal when named locations expand
  from 26 to ~80.
- Setback ground is walkable, so players cut across blocks rather than following
  streets. Fewer signs seen per unit of travel.
- Stores lost `KIND_COLORS` when models landed, so signs are the only marker
  now. Argues for facade shaders sooner. Has a design consequence: see the
  corruption constraint in DESIGN.md.

### Deferred deliberately

`SETBACK_FRONT_MAX` + `SETBACK_REAR_MAX` = 8.5 combined, eating up to 8.5m of an
11 to 19m band. Source of the worst remaining stretch. Not judgeable until
sidewalks exist and more building types are modeled, and the judgement is by eye
on previews.

## Systems in place

- Block/lot city generation.
- ENet networking, host authority.
- Player controller.
- Debug keys: T teleport, F free-fly, F3 seed, F2 session note.
- Invariant suite: 5 checks x 7 seeds, negative-tested.
- Preview harness.
- CI on push.

Only `city-kit-commercial` is wired, to store locations, 5 per city. Everything
else is a colored box. Deliberate: solve scale, origin, and orientation once on
one type.

## Assets

- 15 Kenney kits, 1352 GLBs with textures, in `assets/kenney/`, logged in
  ASSETS.md.
- Kenney GLBs are not self-contained. Textures are a separate folder per kit.
- 14 of 15 kits carry a `.gdignore`. Delete a kit's `.gdignore` in the same
  commit that starts using it, or `load()` fails as a missing resource.
- GeneralUser GS soundfont in `assets/soundfonts/`. Anything rendered through it
  inherits its license.

## Tooling

- `godot` and `blender` on PATH.
- sox, ffmpeg (with libmp3lame), fluidsynth, mido. Python venv at
  `~/.local/share/audio-tools/`, call that interpreter explicitly.
- Skills, global in `~/.claude/skills/`: `asset-fetch`, `asset-import`,
  `godot-verify`, `city-preview`, `scope-check`, `standup`, `wrap`.
- `$FREESOUND_TOKEN` and `$POLY_PIZZA_KEY` in the environment.
- CLAUDE.md is two lines pointing at DESIGN.md.

### Known gaps

- `scope-check` has little to check against, since Decided is nearly empty and
  there are two pillars on purpose.
- The `ask` list in settings.json is bypassable via allowed
  `python3`/`find`/`xargs`/`sed`. The `rm -rf` prompt is theater.

## Next, in order

1. Remaining building types wired to kits
2. Sidewalks and curbs
3. Revisit setbacks by eye on previews
4. Expand named locations 26 to ~80, remove the one-landmark-per-block cap
   (useful-to-filler ratio too low)
5. Rest of phase B
6. Districts last, after the navigation gate: airport ~20 blocks, university ~16

## Parallel experiment

A separate Claude Code session in a worktree at `~/homeless-oneshot` on branch
`oneshot2`, attempting the whole game autonomously. For mining ideas and finding
holes in DESIGN.md, not a build to ship. A previous run produced three mechanics
better than anything designed by hand.

It has not been told the 面白い objective. If the value is hole-finding, a probe
that has not read the objective is arguably the better probe.
