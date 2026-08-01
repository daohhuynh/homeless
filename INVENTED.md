# Where DESIGN.md was too thin, and what was invented to fill it

The brief said DESIGN.md is deliberately thin — `Decided` was empty, only two
pillars, findings inform rather than bind. This is the honest list of every
place a decision had to be made with nothing to lean on, and what the decision
was made from instead.

Ordered by how big the gap was.

---

## 1. The win condition, in detail

**What DESIGN.md had:** "Everyone housed. Bigger places fit more and cost more,
so pooling is a player decision. Housed players stay in as infrastructure." And
in Open: *"How the player wins, in detail. Everything else depends on this."*

**The gap:** everything. There was no money model, no cost, no requirement, no
deadline mechanism, and no answer to what "housed" means mechanically.

**Invented:**
- A shared housing voucher with an expiry date and a fixed pot, spent only on
  move-in, that does not refill.
- Move-in = three times monthly rent (first, last, deposit), which is where the
  title comes from.
- Housing as a listing table: address, capacity, rent, requirements, viewing
  hours — with listings going off the market on their own, because other people
  in this city are also looking.
- "Housed players stay in as infrastructure" resolved as: a leaseholder can add
  the other three as tenants for 12% of monthly rent each, which is the pooling
  arithmetic the design says should be a player decision.

**Derived from, rather than guessed:** the sentence "bigger places fit more and
cost more, so pooling is a player decision" only produces a decision if the
per-head cost curve actually favours pooling *and* pooling has a cost of its
own. So the capacity-4 unit is much cheaper per head and requires everyone to
hold ID and everyone to live in one district.

---

## 2. The whole economy

**What DESIGN.md had:** "Somewhere to earn." Nothing else. No prices, no wages,
no costs, no idea of scale.

**The gap:** every number in the game.

**Invented:** the full table — day labour $95, a temp shift $130 plus a pay
stub, plasma $55 on a two-day cooldown, a two-person dock job at $82 each,
recycling at $0.25 a can, panhandling and busking as per-minute trickles scaled
by district foot traffic and decaying if you do not move on. Against costs: an
ID is $32, a laundry $6, a motel night $55, a bus fare $2.

**How it was pinned:** by working backwards from "the cheapest way to house four
people" and asking whether four players could plausibly earn it. That number is
now an invariant in the test suite — it checks the longest run is affordable at
a conservative earning rate, so a balance change that quietly makes the game
unwinnable fails CI rather than a playtest.

The one thing I would most want playtested: whether the floor (searching bins
for cans) is bad *enough*. It is meant to be the thing that stops a player being
stuck and never the plan.

---

## 3. The requirement chain

**What DESIGN.md had:** the finding "the interesting part of work is the getting
hired, not the labor", and in Open: *"Whether the requirement chain rerolls per
run, or only its surface."*

**The gap:** the chain itself did not exist. There was a finding about it and a
question about how it rerolls.

**Invented:** shelter → mailing address → ID → registered temp work → pay stub →
lease, three levels deep, with a cash-only rooming-house route beside it that
needs no documents at all.

**Derived from:** the finding generalised. If the interesting part of work is
the getting hired, the interesting part of housing is the getting qualified. And
the Open question about rerolling was answered *surface rerolls, shape does not*
— because a chain that reshapes cannot be learned, and a game you cannot get
better at is not one four friends come back to.

---

## 4. Driving

**What DESIGN.md had:** in Open: *"Driving. Deferred until the win condition
exists, since whether a car trivializes the map depends on what winning
requires."*

**The gap:** the design explicitly handed this decision forward to whoever
settled the win condition. That turned out to be me.

**Invented:** there is no driving. The car is a base that sleeps two and can be
relocated once a day. Buses are the traversal system.

**Reasoned from the design's own terms:** winning requires visiting many places
at their opening hours across a large city, so a four-seat car would move the
group as one unit from minute one — and that deletes the unequal starting hands
the second pillar is built on. The bus is the answer that relieves traversal
without collapsing it, because it costs money and can be missed.

---

## 5. The good side of the starting pool

**What DESIGN.md had:** in Open: *"The good side of the start pool. Car is the
only entry."*

**Invented, and this was the most enjoyable gap to fill:** phone, valid ID,
bicycle, cash, a job lead, a warm coat, a toolbox, a storage locker, a backpack,
and the dog.

**The one that took thought:** a phone. It grants the exact time. That turned
"knowing what time it is" into a resource, which turned opening hours into
something players trade information about, and gave the HUD its only piece of
conditional chrome. It is the cheapest good thing in the pool and possibly the
strongest.

The bad side was similarly thin (the design named no burdens at all beyond
implying illiteracy and tiredness), so: no ID, a court date, a garnishment, a
bad knee, illiteracy, an open warrant, a chest infection, a debt collector,
ruined shoes — and the dog again.

---

## 6. What sabotage is

**What DESIGN.md had:** "Sabotage is a supported verb", and in Open: *"What
sabotage is beyond lying."*

**Invented:** withholding, taking a limited thing first, moving the car, and
lying in writing on a notice board.

**The rule I used to decide:** every sabotage verb must be something a friend
can do on purpose and then claim was an accident. That admits taking the last
shelter bed, taking the last day-labour slot, moving the car while somebody is
counting on sleeping in it, and pinning a note with a wrong address on it. It
excludes pickpocketing, which is just a number moving, and it excludes anything
violent, which the first pillar rules out anyway.

The notice board's three player-pinnable slots exist entirely for this. It is
the only mechanism in the game that lets a player be wrong *on purpose*, in
writing, where someone else will find it — and it is deliberately
indistinguishable from the honest use, which is leaving a note about where you
have gone.

---

## 7. Illiteracy

**What DESIGN.md had:** in Open: *"Illiteracy plus tiredness: nothing left to
falsify."*

**Read as:** the idea had been thought through as far as it could be without
building it.

**Invented:** it is in, as an uncommon burden. It corrupts all read text
permanently at a level tiredness barely worsens.

**Why it earns its place:** it is the burden that most forces a player to ask a
friend what a sign says. That is the game working, and it is the one thing a
tiredness tier cannot produce, because tiredness is temporary and this is not.

---

## 8. The unwinnable-run exit

**What DESIGN.md had:** in Open: *"Whether an unwinnable run needs a way to end
itself."*

**Invented:** no. A run ends when the voucher expires or when the last player
signs, and there is no concede button.

**Why:** a group that has worked out the run is lost still has a last day, and
what four people do with a last day they cannot win is more interesting than a
menu. The end screen does say, flatly, what would have made the difference —
computed honestly, not as a taunt.

**Least confident decision in this document.** If playtests show groups sitting
in an alley for ten minutes because they did the arithmetic on day four, this is
the first thing to revisit.

---

## 9. The tone of every word in the game

**What DESIGN.md had:** the pillar. "The game never jokes. Comedy comes from
coordination failure, never from mocking the condition." And the finding that a
mechanic existing to prove a point makes this a Serious Empathy Game with
respectful reviews and zero players.

**The gap:** a pillar is a constraint, not a voice. Every flier, every clerk's
line, every notice and every failure message had to be written.

**The rule I wrote to make it decidable,** now at the top of `data/text.gd`:
officials are neither cruel nor kind, they are busy; every flier is written by
somebody who wanted something; nothing winks. It is a rule the next writer can
apply without asking, which is what the pillar could not do on its own.

The two places the rule was hardest: the police lines (a cruel cop is a joke
about cops) and the losing screen (which had to state a fact and stop).

---

## 10. Everything that is not a mechanic

DESIGN.md is a design doc and correctly says nothing about these. All invented:

- **The title.** *First & Last*, after the deposit the run is arithmetic about.
- **The city's shape** — five districts, their names and characters, one axis of
  streets numbered and one named.
- **The whole location table** — 50 named places across 25 kinds, and which kind
  serves which verb.
- **The interface** — that there is no tiredness meter, no compass, no minimap,
  no quest log, and that the notebook holds *what you perceived* rather than
  what is true. That last one is the interface decision the corruption mechanic
  needed and the design did not ask for.
- **The audio** — an original score, twelve tracks, composed as MIDI and
  rendered through the project's soundfont; nine ambience beds, one per
  district; a low-pass on the master bus that closes as you wear out, which is
  the only tiredness signal that works with your eyes shut.
- **Voice chat.** Not mentioned anywhere in the design. Added because the
  mechanic the design is built on is one player telling another something wrong
  in good faith, and typing that is a different game.

---

## What I did not invent, and left in Open

Four questions are still open in DESIGN.md, and they are there because they are
genuinely undecided rather than unaddressed:

- Whether the voucher's amount should be printed on the voucher or only
  inferable from what a landlord quotes you.
- Whether a housed player should be able to break a lease to free capital. It is
  the obvious next thing players will try.
- Whether the bus should be free after dark.
- How many NPC day-labour applicants is the right number.

Each of them needs a playtest to answer and none of them blocks anything.
