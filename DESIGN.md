# Homeless co-op survival game

Four friends, homeless, unequal starting hands, a deadline. Get everyone
housed or the run is lost. Lethal Company adjacent, except the pressure is a
draining clock rather than a monster.

Nothing here is final. Design decisions get made when there is something to
test them against.

## Pillars

- **Straight-faced systems, unserious players.** The game never jokes. Comedy
  comes from coordination failure, never from mocking the condition.
- **Starting conditions are unfair on purpose.** The group is the balancing
  mechanism, not the dealer.

## Decided

Things settled, one line each, with the reason. The reason is the point: it is
what stops a decision being silently re-proposed, and what lets it be reopened
honestly when the reason stops holding. Empty until something is actually
decided — this section accrues, it is not filled in up front.

## Gates

Nothing advances past a gate until it passes. Gates close no design branch.

**Navigation.** Teleport to a random corner, no map, walk to a named building
and find it. Repeat from a different corner.

**The negotiation.** Four friends, one session. Does the negotiation happen,
or does everyone play four solo runs in the same city?

## Build order

**A. Substrate.** Done. Grid, lots, networking, player controller, debug keys,
invariant suite, preview harness, Kenney kits fetched.

**B. A world that reads.** → navigation gate.

**C. The core five.** → negotiation gate.

**D. Interiors.**

**E. Content depth.**

**F. Ship.**

City gen has no natural finish line. The gate defines done, not the features.

## Working shape

Held loosely. Each is a hypothesis.

**The core five.** A price, discoverable, varying by area. A deadline, known at
minute zero, random per run. Somewhere to earn. Somewhere to stop, where sleep
quality sets tomorrow. Other players who can help or lie.

**Tiredness.** Corrupts rather than slows. Perception in slow systems, input in
real-time ones. No visible number (pinned for consistency across sessions, not
because it's unguessable).

**Asymmetric starts.** Two-axis roll, good and bad separate, dealt unevenly.

**Access to rest.** One player controls it and generosity costs them. Car,
sleeping in the car, the house. Possibly the real core mechanic.

**Win condition.** Everyone housed. Bigger places fit more and cost more, so
pooling is a player decision. Housed players stay in as infrastructure.

**Sabotage** is a supported verb. **Some runs are unwinnable.**

## Findings

Non-obvious, and easy to lose.

- Time poverty is arithmetic, not duration. An hour must visibly cost a
  different hour.
- Corruption is only legible against a stable truth.
- A wrong sign that reads like a sign gets acted on. One that reads broken
  gets discounted.
- The interesting part of work is the getting hired, not the labor.
- A system a player cannot tell is running does not belong.
- A mechanic that exists to prove a point makes this a Serious Empathy Game,
  which gets respectful reviews and zero players.
- Friend-slop has no single-player core to prove. (Contradicts standard
  advice.)

## Codebase facts

- Setback ground is walkable, so players cut across blocks rather than
  following streets. Fewer signs seen.
- Named locations sit one per block on the widest lot, which makes the city
  more legible than a real one.

## Open

- How the player wins, in detail. Everything else depends on this.
- Driving. Deferred until the win condition exists, since whether a car
  trivializes the map depends on what winning requires.
- Whether the requirement chain rerolls per run, or only its surface.
- Whether an unwinnable run needs a way to end itself.
- What sabotage is beyond lying.
- The good side of the start pool. Car is the only entry.
- Illiteracy plus tiredness: nothing left to falsify.

## Unadopted ideas from the one-shot

Liked, not decided.

- Client-side corruption at draw time, so two players read a sign differently
  and both report honestly.
- Booze clears symptoms briefly while real tiredness climbs faster.
- *You Have a Dog*: a condition that subtracts and grants at once.