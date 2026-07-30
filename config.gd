extends Node

## Every tunable number in the game lives here. Nothing else hardcodes a
## rate, cost, threshold, price, or size.

# --- Movement ---------------------------------------------------------------
const WALK_SPEED := 9.0
const SPRINT_SPEED := 16.0
const ACCELERATION := 60.0
const FRICTION := 45.0
const AIR_CONTROL := 0.25
const JUMP_VELOCITY := 6.0
const GRAVITY := 22.0
const EYE_HEIGHT := 1.7
const PLAYER_RADIUS := 0.4
const PLAYER_HEIGHT := 1.9

# --- Camera -----------------------------------------------------------------
const MOUSE_SENSITIVITY := 0.0022
const PITCH_LIMIT := 1.5
const FOV := 90.0
const FOV_SPRINT_BONUS := 8.0
const FOV_LERP_SPEED := 8.0

# --- Keys -------------------------------------------------------------------
## Physical keycodes, so bindings survive non-QWERTY layouts.
const KEY_RESHUFFLE := KEY_R
const KEY_HOST := KEY_H
const KEY_JOIN := KEY_J

# --- Debug tools ------------------------------------------------------------
## Three keys, all local-only and all safe to press in a live session.
const KEY_TELEPORT := KEY_T
const KEY_FREEFLY := KEY_F
const KEY_DEBUG_HUD := KEY_F3
const KEY_FLY_UP := KEY_SPACE
const KEY_FLY_DOWN := KEY_CTRL

## Seed readout starts visible: the seed is the one thing you always want when
## something looks wrong, and you cannot ask for it after the fact.
const DEBUG_HUD_VISIBLE := true
## Lift above the corner's spawn height, so a teleport never lands inside the
## floor and gets pushed sideways by depenetration.
const DEBUG_TELEPORT_CLEARANCE := 0.25

const FLY_SPEED := 24.0
const FLY_SPRINT_MULTIPLIER := 4.0
## Lerp rate toward the wished velocity. High enough to feel direct, low enough
## that a full-speed pass over the city is not nauseating.
const FLY_ACCELERATION := 12.0

# --- Networking -------------------------------------------------------------
const MAX_PLAYERS := 4
const NET_PORT := 27015
const NET_DEFAULT_ADDRESS := "127.0.0.1"
## How often the host broadcasts authoritative player state.
const NET_SYNC_HZ := 30.0
## How fast a remote player's visual position chases the last host state.
const NET_INTERP_RATE := 16.0
## How fast a client's locally-predicted position is pulled back toward the
## host's version. Too high reads as rubber-banding, too low as drift.
const NET_CORRECTION_RATE := 9.0
## Past this error the client stops blending and just teleports.
const NET_SNAP_DISTANCE := 4.0

## Debug aid: put everyone on one intersection, ringed apart, so you can see
## each other the moment you connect. Set false for scattered starts.
const SPAWN_TOGETHER := true
const SPAWN_SPREAD := 2.5

const PLAYER_COLORS: Array[Color] = [
	Color(0.90, 0.76, 0.30),
	Color(0.40, 0.68, 0.90),
	Color(0.85, 0.42, 0.42),
	Color(0.50, 0.82, 0.55),
]
const NAME_TAG_FONT_SIZE := 64
const NAME_TAG_PIXEL_SIZE := 0.006
const NAME_TAG_HEIGHT := 1.35
const NAME_TAG_RANGE := 90.0

# --- City layout ------------------------------------------------------------
## Blocks are rectangular and each column/row draws its own size, so the
## street grid is rectilinear but not uniform.
const GRID_SIZE := 8              # blocks per side
const STREET_WIDTH := 10.0        # gap between blocks
const BLOCK_MIN_WIDTH := 24.0     # block extent along X
const BLOCK_MAX_WIDTH := 40.0
const BLOCK_MIN_DEPTH := 14.0     # block extent along Z
const BLOCK_MAX_DEPTH := 26.0

# --- Lots -------------------------------------------------------------------
## Each block is sliced along its width into lots. A lot may be empty, and a
## building may span two adjacent lots.
const LOTS_MIN := 2
const LOTS_MAX := 6
## Relative slice widths, normalized to fill the block. A wider spread makes
## narrow infill next to broad frontages.
const LOT_WEIGHT_MIN := 0.5
const LOT_WEIGHT_MAX := 2.0
const LOT_EMPTY_CHANCE := 0.15
const LOT_MERGE_CHANCE := 0.20
## Gap between a building and its lot line, drawn per side.
const LOT_SIDE_GAP_MIN := 0.2
const LOT_SIDE_GAP_MAX := 1.8
## Distance from the street, drawn per building for each of the two frontages.
const SETBACK_FRONT_MIN := 0.0
const SETBACK_FRONT_MAX := 5.0
const SETBACK_REAR_MIN := 0.0
const SETBACK_REAR_MAX := 3.5
## Below these a lot is left vacant rather than built with a sliver.
const LOT_MIN_BUILD_WIDTH := 3.5
const LOT_MIN_BUILD_DEPTH := 4.0

const BUILDING_MIN_HEIGHT := 6.0
const BUILDING_MAX_HEIGHT := 34.0
const GROUND_MARGIN := 60.0

# --- Signage ----------------------------------------------------------------
const LABEL_FONT_SIZE := 128
const LABEL_PIXEL_SIZE := 0.012
const LABEL_HEIGHT_ABOVE_ROOF := 1.6
const LABEL_OUTLINE_SIZE := 24
## Named locations are readable from across town; filler blocks only up close.
## The gap is what makes landmarks work as navigation beacons.
const LABEL_LANDMARK_RANGE := 260.0
const LABEL_FILLER_RANGE := 40.0
const LABEL_LANDMARK_SCALE := 1.4

# --- Location table ---------------------------------------------------------
## Locations are data rows, not classes. A new location type is a new row.
## Fields: name, kind. Colors come from KIND_COLORS.
const LOCATIONS: Array[Dictionary] = [
	{"name": "Union Rescue Mission", "kind": "shelter"},
	{"name": "Midnight Mission", "kind": "shelter"},
	{"name": "Hope Street Shelter", "kind": "shelter"},
	{"name": "Weingart Center", "kind": "shelter"},
	{"name": "St. Anselm Soup Kitchen", "kind": "food"},
	{"name": "Loaves & Fishes", "kind": "food"},
	{"name": "Downtown Food Bank", "kind": "food"},
	{"name": "Carter Free Meals", "kind": "food"},
	{"name": "County Public Library", "kind": "civic"},
	{"name": "Sixth Street Library", "kind": "civic"},
	{"name": "Social Security Office", "kind": "civic"},
	{"name": "Department of Public Health", "kind": "civic"},
	{"name": "General Hospital", "kind": "clinic"},
	{"name": "Eastside Free Clinic", "kind": "clinic"},
	{"name": "Needle Exchange", "kind": "clinic"},
	{"name": "Rite Aid", "kind": "store"},
	{"name": "Gonzalez Liquor", "kind": "store"},
	{"name": "99 Cent Market", "kind": "store"},
	{"name": "Laundromat", "kind": "store"},
	{"name": "Pawn & Loan", "kind": "store"},
	{"name": "Day Labor Center", "kind": "work"},
	{"name": "Bottle Redemption", "kind": "work"},
	{"name": "Temp Staffing Co.", "kind": "work"},
	{"name": "Greyhound Station", "kind": "transit"},
	{"name": "Metro Yard", "kind": "transit"},
	{"name": "Fourth Street Underpass", "kind": "transit"},
]

const KIND_COLORS: Dictionary = {
	"shelter": Color(0.85, 0.72, 0.32),
	"food": Color(0.79, 0.36, 0.28),
	"civic": Color(0.36, 0.51, 0.78),
	"clinic": Color(0.44, 0.76, 0.66),
	"store": Color(0.72, 0.44, 0.72),
	"work": Color(0.55, 0.66, 0.35),
	"transit": Color(0.48, 0.48, 0.55),
	"block": Color(0.34, 0.34, 0.38),
}

# --- Filler block names -----------------------------------------------------
## Unnamed blocks still need to read like real addresses.
const FILLER_PREFIX: Array[String] = [
	"Arlington", "Bell", "Corbin", "Delano", "Erwin", "Fig", "Grand",
	"Hobart", "Irolo", "Judah", "Kenmore", "Lorena", "Mateo", "Normandie",
	"Olive", "Palmetto", "Quincy", "Rampart", "Sierra", "Traction",
]
const FILLER_SUFFIX: Array[String] = [
	"Apartments", "Lofts", "Tower", "Offices", "Building", "Plaza",
	"Court", "Arms", "Hotel", "Center",
]

# --- Invariant tests --------------------------------------------------------
## Fixed seeds, so a failure is reproducible and a fix is provable. Add a seed
## here when one turns up a bug; never remove one.
const TEST_SEEDS: Array[int] = [1, 7, 42, 1337, 20260729, 999983, -12345]
## Cell size of the walkability raster. Below the player diameter, or a gap the
## player cannot actually fit through reads as a corridor.
const TEST_CELL_SIZE := 0.4
## Footprints closer than this are touching, not overlapping. Two lots sharing
## an edge is legal; two buildings sharing volume is not.
const TEST_OVERLAP_EPSILON := 0.001
## How far off a building's footprint a walkable cell may sit and still count
## as standing at its door.
const TEST_REACH_MARGIN := 2.0

# --- City preview harness ---------------------------------------------------
const PREVIEW_DIR := "res://previews"
const PREVIEW_WIDTH := 640
const PREVIEW_HEIGHT := 400
## Four fixed compass angles, so the same block appears in the same place in
## every seed's sheet and seeds can be compared rather than merely looked at.
const PREVIEW_YAWS: Array[float] = [45.0, 135.0, 225.0, 315.0]
const PREVIEW_ELEVATION := 34.0
## Camera distance as a multiple of the city's extent.
const PREVIEW_DISTANCE_SCALE := 0.68
const PREVIEW_FOV := 55.0
## The game's fog is tuned for street level and turns an aerial shot into a
## grey rectangle. Previews are for reading the layout, not the mood.
const PREVIEW_DISABLE_FOG := true
## The game's shadow distance is tuned for street level too.
const PREVIEW_SHADOW_DISTANCE_SCALE := 1.5
## Frames to let the renderer settle before grabbing. One is usually enough;
## three costs milliseconds and removes a class of flaky black frames.
const PREVIEW_WARMUP_FRAMES := 3

const PREVIEW_PADDING := 10
const PREVIEW_CAPTION_HEIGHT := 34
const PREVIEW_CAPTION_FONT_SIZE := 20
## Cities per row on the contact sheet.
const PREVIEW_SHEET_COLUMNS := 2
const PREVIEW_BACKGROUND := Color(0.09, 0.09, 0.11)
const PREVIEW_CAPTION_COLOR := Color(0.86, 0.86, 0.90)
