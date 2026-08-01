# Every significant decision, and why

DESIGN.md's `Decided` section holds the design decisions in one line each,
because that is what a design doc is for. This file is the longer version, and
it also covers the technical decisions, which do not belong in a design doc but
do need a reason attached.

Ordered by how much of the game hangs off them.

---

## The run

### The win is keys, and the deadline is a document

**Decided:** every player must be holding an apartment key before a shared
housing voucher expires. Both the win and the clock are physical objects.

**Why:** the negotiation gate asks whether four friends actually talk to each
other or play four solo runs in the same city. A win condition that is a number
on a screen gives them nothing to talk about. A voucher is a thing one of you is
carrying, with a date on it that you can misread when you are tired, worth a
fixed amount that runs out — so it is a budget four people share while their
wallets stay separate. Every argument in the game is downstream of that one
asymmetry.

**Reopen if:** playtests show the voucher gets handed to one player in minute
one and never discussed again. The fix would be to make the voucher's amount
discoverable rather than announced.

### A run is four to seven days, ten real minutes a day

**Decided:** `CLOCK_MINUTES_PER_SECOND = 2.0`, day 06:00 → 02:00, deadline
rolled per run.

**Why:** the whole session has to fit in one sitting for four people, which is
forty to seventy minutes. Randomising the deadline is what stops the second run
being the first run replayed, and announcing it at minute zero is what makes it
a plan rather than a surprise.

The consequence worth stating: crossing the city on foot takes about seventy-five
seconds, which is two and a half game hours. Nobody computes that, and it is
wrong in fiction, but what a player feels is "the day is ten minutes and getting
across town costs a chunk of it," which is the arithmetic the design asked for.

### The day ends when everyone is bedded down, and time speeds up per sleeper

**Decided:** `CLOCK_SLEEPER_SPEEDUP = 1.9`, compounding per sleeping player.

**Why:** this is the pressure Lethal Company gets from the ship leaving, and it
is the only mechanic in the game where going to bed is something you do *to*
your friends. Three people asleep at ten o'clock makes the fourth player's last
two hours pass in forty seconds.

### There is no driving. There is a bus.

**Decided:** the car does not drive. It is a base that sleeps two, relocatable
once a day for fuel and twenty minutes. Buses run three routes on a schedule and
cost fare.

**Why:** DESIGN.md deferred driving until the win condition existed, on the
grounds that whether a car trivialises the map depends on what winning requires.
Winning requires visiting many places, at their opening hours, across a large
city — so a four-seat car would move the group as one unit from minute one, and
that deletes the unequal starting hands the second pillar is built on. A bus
relieves traversal without collapsing it, because it costs money and can be
missed. That it is funnier is a bonus, not the reason.

### Some runs are unwinnable, but none is unwinnable before anyone moves

**Decided:** kept from the one-shot. But `START_GUARANTEE_ONE_ID` forces at
least one player to hold a valid ID.

**Why:** a run you can always win makes the negotiation theatre. A run that is
arithmetically lost on day one before anybody has walked anywhere is not an
unwinnable run — it is forty wasted minutes. The runs that are genuinely
unwinnable are lost to listing spread, weather, a debt collector on day three,
and four people who did not talk to each other. The invariant suite checks the
*longest* run is affordable, not the shortest, precisely so the shortest can be
brutal.

---

## The chain

### Shelter → address → ID → registered work → pay stub → lease

**Decided:** three levels deep, every level a building with opening hours.

**Why:** this is the whole game and it comes straight out of two findings. "The
interesting part of work is the getting hired, not the labour" generalises: the
interesting part of housing is the getting qualified. And "time poverty is
arithmetic" needs a chain where each link costs a piece of a day at a specific
hour, so that two errands genuinely cannot both be run.

The shelter is what breaks the loop, because the county office will not issue an
ID without a mailing address and a shelter will let you use theirs once you have
stayed a night. That is why shelter beds are a limited resource and why taking
the last one is the most socially expensive action in the game.

### Day labour pays cash. Temp staffing pays a stub.

**Decided:** two jobs, deliberately in tension, on opposite sides of the city
with overlapping hours.

**Why:** an hour at one buys food and an hour at the other buys the future, and
you cannot do both. That is time poverty as arithmetic expressed as two
buildings rather than as a resource bar. Registration is a separate trip on a
separate day, which is what makes the chain three days deep — nothing about it
is difficult, and that is the point. It is a form and a queue.

### Two routes to housing, and the voucher only helps one

**Decided:** leases are cheaper per head, need paperwork, and the voucher pays
60% of move-in. Rooming houses are weekly, cash only, need nothing, and the
voucher does not apply. Three to five rooming houses exist in the whole city.

**Why:** without this the optimal play is a single line and there is nothing to
argue about. With it, a four-day run pushes the group toward cash and a
seven-day run toward paperwork, and the group has to decide which they are
playing before they know how the days will go. Measured: the cheapest pooled
lease route costs about $1,130 in cash; four rooming-house rooms cost about
$2,016 and no documents at all.

### Requirements reroll per run; the chain does not

**Decided:** which listing wants a reference, which job wants boots, where the
offices are — all reroll. The shape does not.

**Why:** a chain that reshapes every run cannot be learned, and a game you
cannot get better at is not one friends come back to. This answers an Open
question that had been left standing.

---

## Perception

### Corruption runs on the client, at draw time

**Decided:** adopted from the one-shot's unadopted list. `Corrupt` is called by
the thing being drawn, on the machine drawing it, off that player's tiredness.

**Why:** it is the only version where lying and being wrong are
indistinguishable from outside. Two players read one sign, get different
numbers, and both report honestly. That is what makes trust cost something, and
it is why the wallet lives on the host and the price tag lives on the client —
the two must never be the same system.

### Corrupted text stays plausible, and stays stable for a day

**Decided:** digits drift or transpose but never change in count; similar
letters swap but never the first letter of a word; a word may be replaced by
another word from the same vocabulary. Seeded on
`(key, peer, day, tier)`, so the same sign gives the same wrong answer all day.

**Why:** two findings, both load-bearing. "A wrong sign that reads like a sign
gets acted on; one that reads broken gets discounted" — so garbling is the
failure mode, not the feature, and the invariant suite asserts the digit count
survives four hundred corruptions of a price. "Corruption is only legible
against a stable truth" — so a sign that re-rolls per frame is noise, and noise
teaches nobody anything.

The word swap is the dangerous edit and the one the design is actually about: it
produces a sentence that is wrong and completely readable. `First Avenue`
reading as `Ninth Court` is the mechanic working.

### There is no tiredness meter, and the settings cannot turn one on

**Decided:** no number, no bar, no icon, anywhere. What you get instead: the
world goes muffled (a low-pass on the master bus), the camera drifts, inputs
occasionally drop, you stumble, and signs start lying.

**Why:** kept from the one-shot. A slow player just plays less game; a wrong
player plays a different one. The two accessibility switches (head bob,
tiredness sway) remove the *motion* and keep the *mechanic*, and the settings
screen says so in plain language, because a player who turns off "tiredness
sway" must not believe they have turned off tiredness.

### Hunger only multiplies tiredness

**Decided:** hunger has no effects of its own. It makes tiredness climb faster
and nothing else.

**Why:** "a system a player cannot tell is running does not belong." Hunger with
its own effects would be a second invisible meter. Hunger as a multiplier on a
system that is already legible is legible through it, and free food at fixed
hours makes it arithmetic rather than maintenance.

### Booze and the dog

**Decided:** both adopted from the one-shot's unadopted list. Booze subtracts
from *apparent* tiredness while the real number climbs 1.9x faster. The dog
appears on both the good and the bad start lists, and rolling it twice gets you
one dog.

**Why:** booze is the only item in the game that makes you feel better and be
worse, which is the mechanic stated once. The dog subtracts and grants at once —
she improves sleeping rough, finds things in bins, has to eat every day, and no
shelter in the city takes dogs, which closes the entire paperwork route to
whoever has her.

---

## The city

### Five districts, assigned by nearest seed

**Decided:** Voronoi over the block grid, re-seeded until every district holds
at least seven blocks. Each has its own rent index, price index, building kit,
tree density, litter density and police presence.

**Why:** "a price, discoverable, varying by area" needs areas that are
distinguishable without a HUD. And the district is half the answer to the
navigation gate: you know where you are because the buildings changed, the
litter changed, and there are more trees. Quadrants would have been simpler and
would read as a diagram.

### One axis numbered, the other named

**Decided:** avenues are First through Ninth, cross streets are Bell, Corbin,
Delano. Signs on both blades of every corner post.

**Why:** this makes an address arithmetic. From 3rd & Bell to 7th & Bell is four
blocks and you do not need a map to know which way to walk. It is the single
cheapest thing that can be done for the navigation gate, and it directly answers
the codebase fact that players cut across blocks and see fewer signs — corner
posts are on the routes people actually take.

### Four sign ranges, deliberately spaced

**Decided:** landmark 260m, district gateway 90m, fascia with opening hours 55m,
pavement map kiosk 3m.

**Why:** it is a legibility ladder rather than four kinds of decoration. The gap
between the landmark range and the fascia range is what makes a landmark work as
a beacon while still requiring you to walk to it to learn anything — which is
the shape the whole game wants.

### Pavement is a raised pad with a sloped kerb

**Decided:** roads at −0.14m, block pads at 0, kerb as a 22-degree ramp rather
than a step, kerb face darker than the pavement.

**Why:** the street has to read as a place you step down into rather than as a
differently-coloured floor. A 0.14m step stops a `CharacterBody3D` capsule dead
and needs step-up code in the controller; a ramp is climbed by `move_and_slide`
for free, and real kerbs have ramps at the corners anyway.

### Interiors live 800 metres below the city

**Decided:** a pocket, reached by a Door on the building front.

**Why:** two reasons and both are load-bearing. The city kit's buildings are
single meshes with no interior volume, so there is no inside to put a room in.
And a shop that is bigger inside than the box it is entered through is every
real shop — fitting rooms to the shells would have made half the locations in
the game a cupboard.

---

## Technical

### One request verb instead of thirty RPCs

**Decided:** `Game.request(verb, args)`. Clients never write their own state.

**Why:** thirty RPC entry points is thirty places to forget an authority check.
One is one, and the rules live in one `match`. The cost is that a client waits
for the next sync to see its own money change, which at 5 Hz is not perceptible
in a game about walking places.

### Node names are assigned, never auto-generated

**Decided:** every path-addressed node gets a name from a per-build counter.

**Why:** this was a real multiplayer bug, not a style preference. Godot's
`add_child` resolves a name collision with `@StaticBody3D@<counter>`, and that
counter is *process-wide* — so two players who joined in a different order got
different node paths for the same building, and half the request API addresses
objects by path. The determinism invariant caught it because the fingerprint
included node names.

### The tools are scenes, not `--script` runs

**Decided:** `godot --headless --path . tests/invariants.tscn`, and the same for
the preview, fit and eye-level harnesses.

**Why:** under `godot --script`, an autoload's *constants* resolve but its
*instance methods* do not, so `Config.district("downtown")` fails with
`Compile Error: Identifier not found: Config` — which reads like a missing file
rather than a missing singleton and takes the whole preload chain down with it.
Running a scene loads the autoloads properly. The world nodes need `Game`, `Net`
and `Audio` to exist at all, so this stopped being optional the moment the world
had signage in it.

`Config`'s lookup helpers were also made `static`, which is correct anyway:
they are pure reads of constants.

### Batching, and what may not be batched

**Decided:** static repeated props go into MultiMeshes; anything with a light, a
body, an interaction or its own state stays a node. `Kit.batchable()` answers
the question and every call site asks it.

**Why:** a thousand bollards is a thousand draw calls for no gain. But a
MultiMesh holds exactly one mesh, and several kit models are exploded per-part
exports — every car in the car kit is five or six meshes, the poly.pizza bus is
fifty-nine — so batching one renders a single part. The parked cars along every
kerb in the city were single wheels until the guard was added.

### Streetlights are parented to the pool, not to the post

**Decided:** the `OmniLight3D` sits under the light pool and is positioned in
world space.

**Why:** `place_tall` scales a 0.675-unit lamp model by about 9.5x to bring it
to 6.4 metres. A light parented to that node inherits the scale, so an offset of
5.8 metres became fifty-five. Eighty-odd lamp heads per city, all of them
lighting the sky.

### Proximity voice chat, deliberately crude

**Decided:** 12 kHz, 8-bit, mono, gated, push-to-talk, positional. No codec.

**Why:** the mechanic the design is built on is one player telling another
something that is wrong, in good faith, in their own voice. Typing that is a
different game. A codec would mean a GDExtension and a GDExtension would mean
this feature does not ship. 12 KB/s per talker is not a problem for four people,
and it sounds like a phone, which is the right register. Every failure path is
soft: no microphone, no permission, no input driver — voice turns itself off and
says so once.

### Props are sized in metres, never in kit units

**Decided:** `Config.PROP_MODELS` carries each object's real-world size.

**Why:** cross-kit scale is not merely inconsistent, it disagrees by four orders
of magnitude. The city kits are 9 m/unit; the car kit is 1.76; the poly.pizza
models range from a 0.73-unit traffic light to a 27-unit bus shelter. A scale
*factor* written into a table is a fact about one kit. A real-world size is a
fact about the world, and `Kit.place` measures the model and does the division.
