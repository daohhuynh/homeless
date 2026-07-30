# Assets

Every asset in this project, with its license. Nothing ships without a row here.

Every asset here is either CC0-1.0 or permissively licensed with **no attribution
requirement**, so there is still no `## Attribution` section. Add one the moment
a CC-BY asset lands — poly.pizza and Freesound both serve CC-BY routinely, so
this will not stay true for long.

GLB only. The FBX, OBJ, DAE, STL, Unity-package, and isometric-PNG folders in
the source archives were not extracted. `License.txt` is kept inside each kit
directory as the in-tree provenance record; its parenthetical is the pack
version, which is more reliable than the zip filename suffix.

**GLB does not mean self-contained.** Kenney's GLBs reference their textures by
relative URI (`Textures/colormap.png`) rather than embedding them, so a kit
extracted GLB-only imports flat white and Godot logs a warning per model. The
texture folder has to be extracted alongside, into `Textures/` next to the GLBs,
or the relative URI does not resolve. Every kit that needs one now has one; see
"Textures" below.

Nothing here is normalized yet — original scale, orientation, pivot, and
naming convention as shipped by Kenney. See "Known inconsistencies" below.

**Only the kits in use are imported.** Every kit directory except
`city-kit-commercial` carries an empty `.gdignore`, which makes Godot skip it
entirely: no `.import` file, no `.godot/imported/` entry, nothing in the editor's
file tree. Importing all 15 produced 1353 `.import` files, against 14 models
actually wired into generation (the `store` row of `Config.BUILDING_MODELS`), and
turned a cold import into 15 seconds; ignoring all but the one kit in use brings
that to 42 files and 2.4 seconds. **Delete a kit's `.gdignore` in the
same commit that starts using it** — until then `load()` on anything inside it
fails, because Godot never saw the file.

## 3D models

| Directory | GLB files | Source | License | Author | Fetched | Pack version |
|---|---|---|---|---|---|---|
| `assets/kenney/city-kit-suburban/` | 40 | https://kenney.nl/assets/city-kit-suburban | CC0-1.0 | Kenney | 2026-07-29 | 2.0 |
| `assets/kenney/city-kit-commercial/` | 41 | https://kenney.nl/assets/city-kit-commercial | CC0-1.0 | Kenney | 2026-07-29 | 2.1 |
| `assets/kenney/city-kit-industrial/` | 25 | https://kenney.nl/assets/city-kit-industrial | CC0-1.0 | Kenney | 2026-07-29 | 1.0 |
| `assets/kenney/city-kit-roads/` | 72 | https://kenney.nl/assets/city-kit-roads | CC0-1.0 | Kenney | 2026-07-29 | 2.0 |
| `assets/kenney/retro-urban-kit/` | 124 | https://kenney.nl/assets/retro-urban-kit | CC0-1.0 | Kenney | 2026-07-29 | 2.0 |
| `assets/kenney/modular-buildings/` | 108 | https://kenney.nl/assets/modular-buildings | CC0-1.0 | Kenney | 2026-07-29 | 2.1 |
| `assets/kenney/building-kit/` | 79 | https://kenney.nl/assets/building-kit | CC0-1.0 | Kenney | 2026-07-29 | 1.0 |
| `assets/kenney/furniture-kit/` | 140 | https://kenney.nl/assets/furniture-kit | CC0-1.0 | Kenney | 2026-07-29 | 2.0 |
| `assets/kenney/food-kit/` | 200 | https://kenney.nl/assets/food-kit | CC0-1.0 | Kenney | 2026-07-29 | 2.0 |
| `assets/kenney/mini-market/` | 20 | https://kenney.nl/assets/mini-market | CC0-1.0 | Kenney | 2026-07-29 | 1.0 |
| `assets/kenney/survival-kit/` | 80 | https://kenney.nl/assets/survival-kit | CC0-1.0 | Kenney | 2026-07-29 | 2.0 |
| `assets/kenney/nature-kit/` | 329 | https://kenney.nl/assets/nature-kit | CC0-1.0 | Kenney | 2026-07-29 | 2.1 |
| `assets/kenney/car-kit/` | 50 | https://kenney.nl/assets/car-kit | CC0-1.0 | Kenney | 2026-07-29 | 3.1 |
| `assets/kenney/blocky-characters/` | 18 | https://kenney.nl/assets/blocky-characters | CC0-1.0 | Kenney | 2026-07-29 | 2.0 |
| `assets/kenney/mini-characters/` | 26 | https://kenney.nl/assets/mini-characters | CC0-1.0 | Kenney | 2026-07-29 | 1.0 |

Total: 1352 GLB files, 35 MB. Every file verified to carry a valid `glTF` magic
header; every kit's `License.txt` verified to state Creative Commons Zero.

## Textures

Same source, license, author, fetch date, and pack version as the kit directory
each one sits in — the table above is the provenance record; this one records
what landed and what it is. Every entry came out of the archive's
`Models/GLB format/Textures/` folder, which is the copy the GLB URIs expect.

| Directory | PNG files | Size | Contents |
|---|---|---|---|
| `assets/kenney/blocky-characters/Textures/` | 18 | 1024x1024 | `texture-a` .. `texture-r`, one skin per character |
| `assets/kenney/building-kit/Textures/` | 1 | 512x512 | `colormap` |
| `assets/kenney/car-kit/Textures/` | 1 | 512x512 | `colormap` |
| `assets/kenney/city-kit-commercial/Textures/` | 1 | 512x512 | `colormap` |
| `assets/kenney/city-kit-industrial/Textures/` | 1 | 512x512 | `colormap` |
| `assets/kenney/city-kit-roads/Textures/` | 1 | 512x512 | `colormap` |
| `assets/kenney/city-kit-suburban/Textures/` | 1 | 512x512 | `colormap` |
| `assets/kenney/food-kit/Textures/` | 1 | 512x512 | `colormap` |
| `assets/kenney/mini-characters/Textures/` | 1 | 512x512 | `colormap` |
| `assets/kenney/mini-market/Textures/` | 1 | 512x512 | `colormap` |
| `assets/kenney/modular-buildings/Textures/` | 1 | 512x512 | `colormap` |
| `assets/kenney/retro-urban-kit/Textures/` | 22 | 64x64, 128x128 | one tiling texture per material: `asphalt`, `bars`, `concrete`, `dirt`, `doors`, `grass`, `metal`, `metal_wall`, `planks`, `rock`, `roof`, `roof_plates`, `signs`, `tiles`, `treeA`, `treeB`, `truck`, `truck_alien`, `wall`, `wall_garage`, `wall_lines`, `windows` |
| `assets/kenney/survival-kit/Textures/` | 1 | 512x512 | `colormap` |

Total: 51 PNG files, 508 KB. Every file verified to carry a valid PNG signature,
and every texture URI in all 1352 GLBs verified to resolve to a file on disk.

**`furniture-kit` and `nature-kit` need no texture at all** and have no
`Textures/` directory. They are the two 2018–19 packs, and they colour geometry
with a per-material `baseColorFactor` instead of sampling an atlas — flat colour
straight out of the glTF material. Nothing is missing from them.

**The colormaps are palette atlases, not surface textures.** UVs point at flat
swatches, so filtering across a swatch boundary is a real risk at distance;
watch for colour bleed before reaching for a mipmap setting.

**Alternate palettes exist and were not fetched.** Several kits also ship
`Models/Textures/variation-a.png` and `-b.png`: the same UV layout in different
colours, so dropping one in over `colormap.png` recolours a whole kit at once.
Worth remembering when the city needs districts that read differently.

## Soundfonts

| File | Source | License | Author | Fetched | Version |
|---|---|---|---|---|---|
| `assets/soundfonts/GeneralUser-GS.sf2` | https://github.com/mrbumpy409/GeneralUser-GS | GeneralUser GS License v2.0 | S. Christian Collins | 2026-07-30 | 2.0.3 |

32 MB, SF2 (`RIFF`/`sfbk`, SoundFont spec 2.1). SHA-256
`9575028c7a1f589f5770fccc8cff2734566af40cd26ed836944e9a5152688cfe`. Verified by
rendering a MIDI chord through it with `fluidsynth` and confirming the output was
audible, not just non-empty (0.169 peak, 0.019 RMS) — an sf2 that loads and
renders silence is the failure this catches.

`assets/soundfonts/LICENSE.txt` is the upstream licence text, kept in-tree as the
provenance record, byte-identical to what the author shipped (CRLF included) for
the same reason the Kenney `License.txt` files are.

**Anything rendered through this soundfont inherits this licence.** A rendered
sound is a derivative of the samples inside the sf2, not an original work, so it
is *not* `n/a (generated)` — it is GeneralUser GS License v2.0, and its
`## Generated audio` row must name the sf2 in the Command column.

The grant is unusually plain: use "without restriction for your own music
creation, private or commercial", modification allowed, no attribution required.

**The author discloses a sample-provenance caveat, quoted here so it is not lost
in a licence file nobody reopens:**

> Many of the samples are original, but some were taken from other banks freely
> (and legally) available on the Internet from various SoundFont websites.
> Because GeneralUser GS originated as a personal project with no intention for
> publication, I cannot be 100% sure where all of the samples originated,
> although I do know that none of them came from commercially published
> SoundFont packages or sample CDs.

That is a disclosed residual risk, not an unclear licence — the grant itself is
unambiguous, which is why this passes the "no unconfirmable licences" rule. It
has stood unchallenged since 2000. Worth a second look before shipping
commercially; not worth blocking prototype audio on.

The author also asks that his own download links not be hotlinked. We hold a
local copy, which is what he asks for instead.

**Why not FluidR3_GM.** MIT, cleaner provenance, and the usual first choice —
but ~148 MB unpacked (135 MB as Debian's `fluid-soundfont` source package)
against 32 MB here. This repo commits binaries directly and uses no Git LFS, so
FluidR3 would more than quintuple it. Revisit if LFS ever lands, or if the
provenance caveat above ever becomes a shipping blocker.

**Two soundfonts already on the machine must not render anything that ships** —
`fluid-synth`'s bundled `VintageDreamsWaves-v2.sf2`, and macOS's
`gs_instruments.dls`, which is Apple system software licensed for use on the
machine and not for redistribution inside a game. Both are fine for capability
checks only.

## What each kit covers

- **city-kit-suburban / -commercial / -industrial** — whole-building exteriors,
  one mesh per building. The block-scale filler.
- **city-kit-roads** — road tiles, sidewalks, bends, crossings, bridge pillars,
  streetlights, construction barriers and cones.
- **retro-urban-kit** — street-level detail at a finer grain than the city kits:
  awnings, benches, barriers, balconies, fire escapes, ladders.
- **modular-buildings** — building facades as parts (corners, windows, doors,
  sills) for buildings you enter rather than pass.
- **building-kit** — modular interior/exterior shell: walls, floors, roofs,
  stairs, doors, columns, plus boarded-up barricades for doorways and windows.
- **furniture-kit** — indoor furniture, full house coverage including beds,
  bathroom, kitchen.
- **food-kit** — 200 individual food items, containers, bottles, bags.
- **mini-market** — shop interior: shelves, freezers, cash register, displays,
  bottle-return, an employee character.
- **survival-kit** — bedrolls, tents, campfires, barrels, buckets, boxes,
  bottles. Closest kit to this game's actual subject matter.
- **nature-kit** — 329 models: trees, plants, rocks, terrain patches, fences.
- **car-kit** — 50 vehicles and vehicle debris, including an ambulance.
- **blocky-characters** — 18 characters, 27 baked animation clips each.
- **mini-characters** — 26 files: characters plus mobility and medical aids
  (canes, crutches, glasses, masks, defibrillators), 32 animation clips each.

## Known inconsistencies

Not fixed — normalization is deliberately deferred.

- **Naming conventions differ by pack age.** The 2018–2019 packs
  (`furniture-kit`, `nature-kit`) use camelCase: `bathroomCabinetDrawer.glb`,
  `bridge_center_stoneRound.glb`. Newer packs use kebab-case:
  `building-type-a.glb`, `campfire-pit.glb`. Any code that resolves model names
  from data rows has to cope with both, or the files get renamed first.
- **Scale is not guaranteed consistent across kits**, particularly between the
  `mini-*` series and the `city-kit-*` series, which are drawn at different
  chunkiness. Unverified — check before mixing them in one scene.
- **Style split.** `mini-market` and `mini-characters` belong to Kenney's "mini"
  line and read chunkier than the city kits. They were fetched because their
  *content* is on-target (a shop interior; mobility aids), not because they
  match visually. Worth a look before committing to them.

## Deliberately not fetched

- **`3d-road-tiles`** — no GLB. A 2015-era pack shipping OBJ + `.gltf` + a Unity
  package only. Excluded by the GLB-only rule; `city-kit-roads` covers roads
  more thoroughly anyway.
- **`animated-characters-protagonists`, `animated-characters-survivors`** — no
  GLB and no glTF. These ship a single rigged `characterMedium.fbx` plus
  swappable PNG skins. Excluded by the GLB-only rule. Not a loss:
  `blocky-characters` and `mini-characters` ship GLBs with animations already
  baked in (27 and 32 clips respectively, verified by reading the glTF JSON
  chunk), so animated characters are covered without touching FBX.
- **`mini-forest`** — 22 models, overlaps `nature-kit` at lower coverage.
- **`train-kit`** — rail transit, outside the requested categories.
