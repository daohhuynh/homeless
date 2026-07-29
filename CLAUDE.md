# Homeless co-op survival game

Godot 4.7, GDScript. 3D with untextured primitives, no art assets.
4-player co-op, ENet, host is authoritative.

## Non-obvious decisions

- Tiredness has no visible number or bar. Players infer it from
  which systems have started failing.
- Tiredness corrupts text into *plausible* wrong values, never
  scrambled or obviously broken. A corrupted street name must
  read like a street name.
- Locations are data rows, not classes. New location types are
  new rows.
- All tunable numbers live in config.gd. Never hardcode a rate,
  cost, threshold, or price.
- Asymmetric starts are deliberately unfair. Do not balance them.