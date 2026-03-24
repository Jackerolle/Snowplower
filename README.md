# Snowplower

Godot 4 prototype for a top-down snowplow game. The current build is an MVP focused on the core loop:

- drive the plow through a neon-lit city crossroads
- collect snow into the blade load
- dump the load into marked edge zones before the truck stalls
- clear 90% of the streets before the shift timer expires

## Open

1. Install Godot 4.x.
2. Open this folder as a Godot project.
3. Run `scenes/main.tscn`.

## Current controls

- `A` / `D` or arrow keys: steer
- Left mouse drag: steer toward pointer
- `R`: restart after win/loss

## Current scope

Included:

- single playable shift
- stylized vector-style world rendering
- snow grid that can be plowed away
- dump zones, black ice, parked car penalties
- HUD, timer, progress target, basic screen shake

Not included yet:

- garage / upgrades
- multiple missions or level selection
- audio / haptics
- mobile export validation
