# Homeless co-op survival game

Working design doc and decision log. The decision log is the important half.

---

## One-liner

Four friends, homeless, unequal starting hands, a deadline. Get everyone
housed or the run is lost.

Lethal Company adjacent: drop into a hostile world, shared goal, a clock,
scavenge, coordinate badly, mostly fail, run ends, go again. The divergence
is that the pressure is a draining clock rather than a monster, so it is
slower and more strategic, and the comedy comes from planning disasters
rather than jump scares.

## Pillars

Four statements used to say no. If a proposed feature does not serve one of
these, it does not go in.

1. **Friend-slop first.** The fun is four people on voice chat coordinating
   badly. Anything that does not serve that is optional at best.
2. **Straight-faced systems, unserious players.** The game never jokes. The
   players do. Comedy comes from coordination failure, never from mocking
   the condition.
3. **Starting conditions are unfair on purpose.** The group is the balancing
   mechanism, not the dealer.
4. **No simulation for its own sake.** Consequences, not fidelity.

## The core five

Everything else in the game is optional content hanging off these.

1. **A price.** Discoverable, not given. Varies by area, so there is a menu
   rather than a quota. Finding it is the first scavenge of the run.
2. **A deadline.** Known at minute zero, random per run. Short runs are pure
   hustle, long runs make paperwork worth the investment. Loosely correlated
   with price, with real variance, so some runs are visibly cursed.
3. **Somewhere to earn.** Day labor as a discrete event, not a shift. The
   hiring corner is the scene, not the work.
4. **Where you stop.** Sleep is available anywhere, quality varies by spot,
   sets tomorrow's starting tiredness. The car is the top of that spectrum,
   not a separate category.
5. **Other players.** Who can help or lie about any of the above.

## Systems that cut across all five

**Tiredness.** Not energy, not boredom. Corrupts perception in slow systems
(signs, forms, what you remember being told) and corrupts input in real-time
ones. No visible number or bar; the thresholds are the readout. No hard zero,
because a locked-out player is dead air.

**Asymmetric starts.** Two-axis roll, good and bad totals kept separate so a
run can be high-good and high-bad at once (car plus withdrawal). Dealt from
the pool unevenly on purpose. Values are rough tiers, never tuned, because
the value of a condition is a property of the combination and a scalar cannot
hold that. Needs a remainder rule: draw until the next item would exceed the
budget, stop, let the leftover be dead space.

**The access pattern.** The design converged on this three separate times:
car, then sleeping in the car, then the house. One player controls access to
rest, and the cost of generosity is real. This is probably the actual core
mechanic. Time poverty and tiredness are what give it teeth.

## Win condition

Everyone housed before the deadline. A house or larger apartment fits four
and costs more; smaller units fit one to three and cost less. Players choose
per run whether to pool or go separately, so pot size is a player decision
rather than a designer's.

The lever that makes it a real choice: the four-person place is cheaper per
head, but every tenant has to qualify. So the cheap option is gated by the
weakest member's conditions, which is a real argument between friends and
makes the ID chain matter without forcing it.

Housed players stay in the world as infrastructure. Their place is where the
group sleeps, which is the single biggest lever on tiredness. A crime in your
house costs you the house and the deposit, so the housed player's real
decision is who gets a key. Eviction is worse than never having had it, and
is a legitimate run-ender.

---

## Decision log

The reason this document exists. Each entry is a thing that was decided and
why, so it does not get silently re-proposed or reversed.

### Cut

**Driving.** Homeless easy mode. Even a lucky roll makes it too strong, and
a drivable car is physics, collision, camera, parking, damage: months. The
car stays parked and is shelter. Traffic stays as a hazard on rails, with
drunk drivers more common at night, because that makes crossing a decision
and pairs with tiredness (worst at judging the road at the hour the road is
worst).

**Simulated work shifts.** Clocking in and losing the day is the failure
mode. Work is a discrete event with a cost, an outcome, and a thing that can
go wrong. The interesting part was never the labor, it was the getting hired.
A steady job is a status that costs availability, not a place you go.

**Waiting as a mechanic.** Watching a bar fill is dead air. Time poverty is
arithmetic, not duration: an hour must always visibly cost a different hour.
Anything genuinely inert just resolves. Waits that cannot be abandoned are
poison; a wait you can bail on at any moment is a standoff with yourself and
is fine.

**Rerolling the requirement chain.** If the rules change every run, a lie
costs nothing and detects as nothing, and the paranoia layer flattens into
noise. Corruption is only legible against a stable truth. Rules are fixed and
learnable. What rerolls is the surface: which office, what hours, what is
backlogged, what is closed.

**Single-player core first.** Standard advice, wrong for this game.
Friend-slop has no single-player core to prove. A grid of boxes with a time
counter proves nothing except that you can write a time counter.

**Interiors of plazas, and interiors in general as a phase B item.**
Interiors are the largest thing on the list and cannot be evaluated until the
outside works. Outdoor plazas are a whole-block use with paving and benches.

**Real-world specific places.** No Irvine Spectrum. No free model exists, it
would be an IP problem, and real places do not tile into procedural lots.

**Anything justified by "models the real trap."** If a mechanic exists to
prove a point rather than because it is fun, it does not go in. The moment
the game is making an argument it becomes a Serious Empathy Game, which gets
respectful reviews and zero players. Lethal Company is not about anything.

**AI-generated buildings.** Not a quality objection. Lots vary in width, so a
finished mesh does not fit an arbitrary lot. Modular kit pieces tile; AI
output does not. Also drifts in scale and style between generations, and free
tiers are CC BY, which creates attribution paperwork. AI is fine for one-off
props that appear once and align to nothing.

### Settled, with reasons that are easy to lose

**Tiredness has no number.** You know how tired you are by which systems have
started failing. A gauge you feel instead of optimize.

**Corruption is plausible, never scrambled.** A wrong street name reads like
a street name. A wrong shelter is another shelter, never a liquor store. If
it looks broken, players discount it; if it looks fine, they act on it. The
illiterate player knows he cannot read and compensates by asking. The tired
player thinks he can read, and that is the worse condition.

**Corruption is applied at draw time on the tired player's own machine.** The
host is never lied to. Two players can read the same sign differently and
both be reporting honestly. This is where mistrust comes from, and it means
sabotage needs no detection system because the noise floor does the work.
(Taken from the one-shot experiment. Architectural, and better than anything
designed in conversation.)

**Rules fixed, geography shuffled.** Veterans get real knowledge of how the
system works and still have to find the office. Lets people get good without
letting them beat it.

**Every condition must subtract and grant at once.** The test case is *You
Have a Dog*: cannot sleep indoors, but nobody robs you. No compensating buffs
bolted on. Three of four players being the guy who cannot do things is
homework, not friend-slop.

**Locations are data, not classes.** A location is a row: type, label, mesh,
sleep quality, interaction. New location types are new rows. This is what
makes every question about which buildings the game needs deferrable.

**All tunable numbers in one config file.** Tuning mid-playtest while four
people wait is the difference between one session and three.

**Sleep is available anywhere.** Not a place you find. The last decision of
every day is whether to crash here or spend twenty minutes walking somewhere
better while the light goes. Every location gets a second property: what it
is like to sleep there.

**Cursed runs should be short.** Forty minutes of doomed misery is homework;
twelve minutes is a bit. Oregon Trail's unwinnable runs kill you in week two.

**Named locations: one per block, taking the widest lot.** Otherwise they
dilute across ~148 buildings and clump. Side effect: the city is more legible
than a real one, which may sand off some of the intended getting-lost.

**Streetlights do not cast shadows.** A light is cheap; a light's shadow is a
re-render. Light pools on the ground are all night needs.

**Interiors are generated, not modeled.** Same three inputs as the exterior
(footprint, location type, seed), emitted in one pass so shell and rooms
agree by construction. Enterable buildings assemble their shell from wall
segments rather than using a kit model, because the door has to be a real
opening. Generate for the ~26 named locations only; the rest stay solid
shells. Lazy generation on approach is safe because seed determinism already
holds.

### Steals from the one-shot experiment

Kept from the throwaway branch:

- The starting hand format, and *You Have a Dog* as the template.
- Booze clears tiredness symptoms for ~90 seconds while actual tiredness
  climbs faster. A tool with a trap in it, better than a meter to maintain.
- Client-side corruption (see above).
- Determinism from seed with no map data on the wire.

Rejected from it:

- Downed-for-15-seconds revive. Imported co-op convention, and exactly the
  dead air the design refuses.
- Hunger with no felt consequence. A system that exists because survival
  games have one.
- Unexplained pickups.
- Five days against a three-workday requirement with no findable job. Each
  choice locally plausible, the run unplayable.

---

## Open questions

- **What sabotage actually is.** Just lying, or explicit verbs? Client-side
  corruption may have already answered this.
- **The good side of the start pool.** Still nearly empty. Car is the only
  entry. Every candidate must pass the *You Have a Dog* test.
- **Illiteracy plus tiredness.** He has no text left to falsify. Probably the
  relay chain he cannot audit.
- **Whether the negotiation happens at all.** The one question that decides
  whether this game works. Unanswerable from a chair. Needs four people in a
  session.

---

## Build order

**A. Substrate.** Done. Project, git, city grid, lots, networking, player
controller.

**B. A world that reads.** Kenney kit in, asset normalization, meshes wired
into generation, facade shaders, sidewalks and curbs and corner treatments,
streetlights, site treatment on setback ground, parks and plazas and parking
lots as whole-block uses, lighting discipline, occlusion bake, traffic on
rails, traffic light state machines with pedestrian phases (compressed
timings, ~30s max wait, not realistic), day/night, debug teleport key.

*Gate: teleport to a random corner, no map, walk to a specifically named
building and find it. Repeat from a different corner.*

City generation has no natural finish line. The acceptance test defines done,
not the feature list.

**C. Interiors.** Per the settled decisions above.

**D. The core five.** The actual game.

*Gate: four friends, one session. Does the negotiation happen, or does
everyone wander off and play four solo runs in the same city?*

**E. Content depth.** ID chain, illiteracy, addiction, NPCs, sabotage,
housed-player-as-infrastructure.

**F. Ship.** Sound, menus, Steam, balance.

---

## Notes on tooling

- CLAUDE.md stays empty. Procedural knowledge goes in skills, and only after
  a problem has been solved once.
- Add a CLAUDE.md line only when a competent implementer would plausibly do
  the opposite by default, and only after being corrected twice.
- Steam is the eventual target if it ships, because friend-slop needs
  one-click join and Steam's relay solves connectivity. itch.io in between.
  A zip sent to three friends covers the next several months.
