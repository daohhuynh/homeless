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

# --- City layout ------------------------------------------------------------
const GRID_SIZE := 9              # blocks per side
const CELL_SIZE := 18.0           # footprint a block may build inside
const STREET_WIDTH := 10.0        # gap between blocks
const BUILDING_MIN_HEIGHT := 6.0
const BUILDING_MAX_HEIGHT := 34.0
const BUILDING_MIN_INSET := 1.0   # shrink footprint so blocks aren't uniform
const BUILDING_MAX_INSET := 5.0
const EMPTY_LOT_CHANCE := 0.12
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
