# Toy Racer feel checklist

What makes driving and crashing satisfying: sound, camera, body, particles, physics, haptics.
Each item is one sensation. The *Today* line is where the code stood on 22 Oct 2026,
from a read of `car.gd`, `chase_camera.gd`, `audio_manager.gd`, `hud.gd` and the hazards.

## How to use it

- **The PR that ships a feature ticks its box in this file** and adds the PR number at the end of the line, like `(#612)`.
- **Reference the item id** in the PR description, for example `feel: engine-gears`, so `git log --grep` finds it.
- **Partial work stays unticked.** Update the *Today* line instead, so the next person sees what is left.
- **New ideas go in as new unticked lines** in the right section, with a fresh id.

Status today: **Have** in the game and working · **Partial** exists but not scaled, not everywhere, or one-shot · **Missing** nothing in the code · **Optional** nice to have, decide later. ⭐ marks the top gaps.

## Four rules above everything

1. **Every event hits several senses at once.** A hit that changes the car's motion but produces no sound, no particle and no camera reaction reads as a bug. Anything above a small threshold touches physics, sound, a visual and the camera together.
2. **Everything scales with intensity.** Volume, pitch, shake, particle count and body jolt grow with the speed difference of the impact, with a floor below which nothing fires.
3. **Never leave the player stuck.** Being wedged, flipped or pinned for more than a second kills more fun than any missing effect.
4. **Wind-up, then payoff.** Ramp lips that stretch the car, a turbo that spools before it kicks, a drift that builds smoke.

## Top gaps, in order

1. Engine note with gears and load (`engine-gears`)
2. Tire squeal that tracks slip (`slip-squeal`)
3. Impact sound in layers (`impact-layers`)
4. Directional camera kick and hit-stop (`hitstop-shake`)
5. Scrape loop and sparks (`scrape-sparks`)
6. Surfaces that talk (`surface-voice`)
7. Steering that tightens with speed (`steering-speed`)

## Driving feel

- [x] **Weight transfer you can see** `weight-transfer` · Have  
  Roll in corners, squat under throttle, dive under braking. That is how the brain reads mass.  
  *Today:* Comes for free from the raycast suspension, with springs set per car.
- [ ] **Engine note with gears and load** `engine-gears` · Missing · ⭐  
  The ear reads acceleration from a pitch that climbs, drops at a shift and climbs again, and from a note that gets harsher under throttle and softer on lift.  
  *Today:* One linear pitch ramp at fixed volume. No gears, no throttle input. Sounds like a vacuum cleaner at top speed.
- [ ] **Throttle-lift pops** `lift-pops` · Missing  
  A crackle when you lift at high revs, fired at random so it never becomes a pattern.  
  *Today:* The backfire sample is loaded but never played.
- [ ] **A toy sound palette** `toy-sound-palette` · Missing  
  Toy cars do not have a V8. An electric whine with a small gear whirr like Re-Volt's RC cars, plastic clacks on contact, rattles on kerbs, a pull-back spring at rocket start. Cheap, and identity nobody else has.  
  *Today:* Realistic-leaning samples, no toy signature.
- [ ] **Tire squeal that tracks slip** `slip-squeal` · Partial · ⭐  
  Volume and pitch follow how much the tires actually slide, so a light slide whispers and a full drift screams. Off asphalt it turns into gravel hiss.  
  *Today:* The loop is on or off with the handbrake, at one level, on every surface.
- [ ] **Surfaces that talk** `surface-voice` · Missing · ⭐  
  Grass rumble, gravel hiss, puddle spray, and kerbs that tick through the suspension, the sound and the camera as you ride them.  
  *Today:* No rolling sounds. Kerbs are visual only. The stone steps already push noise into the springs, so the mechanism exists.
- [ ] **Sense of speed** `sense-of-speed` · Partial  
  Wider field of view, camera pulling back, wind noise rising with speed, trackside objects near the road streaming past.  
  *Today:* FOV and pull-back are in. No wind sound, no speed lines.
- [ ] **Turbo as a three-part event** `turbo-event` · Partial  
  A click on press, an immediate kick with the camera lagging a beat behind, a sustained whoosh, and a release hiss when it ends.  
  *Today:* One-shot at the start plus flame and a pitch bump. No sustain, no release.
- [ ] **Drift with a snap in and a snap out** `drift-snap` · Partial  
  Clear entry, a held slide you steer against, and an exit that straightens cleanly. Smoke thickens with the slide angle.  
  *Today:* Entry and exit ramps feel good. Smoke and marks are on/off rather than scaled.
- [ ] **Jumps with a skill component** `jump-skill` · Partial  
  Lip stretch on takeoff, a little air control so gas and brake level the nose, then a landing thud scaled by fall speed, a dust puff, squash and a camera dip.  
  *Today:* Stretch, squash, sound and shake are in. No air control, no landing dust, fixed-level thud.
- [x] **Steering that tightens with speed** `steering-speed` · Have  
  Less steering lock at high speed so the car never feels twitchy, snappy lock at low speed, and a short smoothing on input so a button tap does not jerk.  
  *Today:* Lock tapers linearly from full at 50% of max speed to 65% at max (`steer_taper_at_top`), drift exempt. `PlayerController` smooths digital steering: 0.10 s in, 0.06 s out, instant through zero on reversal. Guard: `ProbeSteerSpeed`.
- [ ] **A driver who reacts to the road** `driver-reacts` · Partial  
  A flinch on impacts, a head turn into the corner, arms that shake on kerbs.  
  *Today:* Torso and head lean with cornering and braking forces. No impact or kerb reaction.
- [ ] **Toy-only animation** `toy-animation` · Missing  
  Antenna wobble, a wind-up key spinning faster with speed, plastic bits that rattle. Personality every second of driving.  
  *Today:* None.
- [ ] **Haptics** `haptics` · Missing  
  Short rumble on kerbs, landings and hits on a controller. Phone vibration on the big ones.  
  *Today:* None anywhere.

## Hitting the world

- [x] **Glancing versus head-on** `glancing-vs-headon` · Have  
  A scrape along a wall costs little speed and lets you slide on. A head-on stops you with a bounce. The impact angle decides, and a small yaw nudge away from the wall keeps the nose from pinning.  
  *Today:* Wall hits within 30 degrees of the wall plane (`glance_angle_deg`) cut car friction to `glance_friction` and nudge the nose toward parallel through `_impact_yaw`; head-on keeps the stop-with-bounce. A nose pinned at low speed for 0.4 s is shoved away. Moving hazards (AnimatableBody3D) are skipped. Guard: `ProbeWallGlance`.
- [ ] **Scrape loop and sparks** `scrape-sparks` · Missing · ⭐  
  While sliding along a wall: a continuous grind whose pitch follows speed, sparks from the contact point, a slight pull on the steering.  
  *Today:* A single one-shot clunk. Sparks exist only for car-on-car.
- [ ] **Impact sound in layers** `impact-layers` · Partial · ⭐  
  Soft tap, crunch, big crash chosen by speed difference, with random pitch so repeats never sound like a machine gun.  
  *Today:* Car-on-car already layers two sounds by speed. The wall hit is one fixed-level sound.
- [ ] **Directional camera kick and hit-stop** `hitstop-shake` · Partial · ⭐  
  Shake in the direction of the hit rather than randomly, plus a freeze of a few frames on big hits so the brain registers the weight. The cheapest weight trick in games.  
  *Today:* Shake is scaled by impact but random. No hit-stop.
- [ ] **Body jolt on the visual body** `body-jolt` · Missing  
  Nudge the mesh, not the physics body, in the hit direction and let it spring back. The physics stays safe and the car looks like it took the hit.  
  *Today:* The visual node already does squash and drift roll, so the hook is there. No impact jolt.
- [ ] **Things that fly** `things-fly` · Partial  
  Cones, cups, blocks, signs that scatter with a sound and a few debris chunks. The tax for hitting things should be low where you want chaos.  
  *Today:* Small decor already flies, silently. Barrels are static.
- [ ] **Soft hazards** `soft-hazards` · Partial  
  Bushes that slow you with a leaf burst, puddles and sand that spray.  
  *Today:* Water and sand are in. No bush reaction.
- [ ] **Cosmetic damage** `cosmetic-damage` · Optional  
  Scuff decals, a wobbling bumper, a dented mesh swapped after a few hits, reset each race, no mechanical penalty. Makes crashes feel remembered.  
  *Today:* None.
- [x] **Auto-upright on the roof** `auto-upright` · Have  
  A car on its roof flips back in place with a bounce after a second, instead of waiting for a respawn.  
  *Today:* After 0.3 s near-stopped on the roof or a side the car hops (`upright_hop`) and rolls back onto its wheels in place, about 1 s, keeping position and heading (`Car._tick_upright`, signal `uprighted`). In water, far off-road or below the road it falls back to `recover()` at 1.5 s, as before. Guard: `ProbeUpright`.
- [ ] **A price in the turbo bar** `turbo-price` · Optional  
  A hard wall hit drains some charge, turning the turbo into a risk meter that rewards clean driving.  
  *Today:* None.
- [ ] **Every moving hazard speaks** `hazards-speak` · Partial  
  Each moving hazard gets its own contact sound and shake.  
  *Today:* Train and avalanche crush, shake and sound. The sliding barrier and the bus push you silently.
- [ ] **World reactions** `world-reactions` · Optional  
  Birds flushing, a sign wobbling, dust dropping in caves. Character, not mechanics, and cheap.  
  *Today:* None.

## Hitting other cars

- [x] **Readable mass** `readable-mass` · Have  
  Heavy shoves light, with a visible yaw kick and sideways displacement, capped so nobody goes into orbit.  
  *Today:* Done well: mass ratio from the solver, a clamped yaw kick, a brief loss of grip.
- [ ] **Side-by-side rubbing** `side-rubbing` · Partial  
  Sustained contact needs the scrape loop, continuous sparks, both bodies leaning away, and a steady push apart so cars do not weld.  
  *Today:* The push apart exists. Sparks fire only on the first contact, no loop.
- [x] **Corner hits spin, straight hits shove** `corner-hits` · Have  
  Clipping a rear corner rotates the leading car more than a square push. Being rear-ended wobbles you without stopping you.  
  *Today:* Mostly emergent from the physics.
- [ ] **Spin-out assist** `spinout-assist` · Missing  
  Once a car is turned past sideways, a gentle auto-straighten so the player is back on line in a second instead of facing the wrong way. Arcade standard.  
  *Today:* None.
- [ ] **You know who hit you** `who-hit-me` · Missing  
  A camera kick from the hit side, a positional impact sound from the other car, a horn from the AI.  
  *Today:* Impact sounds are flat 2D and only fire when the player is involved.
- [ ] **Driver reactions to the other car** `driver-social` · Missing  
  A fist shake at the offender, a head whip, a glance at the car alongside.  
  *Today:* Lean only.
- [ ] **Hits between AI cars near you** `ai-ai-hits` · Missing  
  Positional and quieter, so the pack sounds alive.  
  *Today:* Silent.
- [ ] **Position-change feedback** `position-change` · Missing  
  A short stinger and a HUD popup when you overtake or are overtaken.  
  *Today:* None.
- [ ] **Slipstream** `slipstream` · Missing  
  A small speed gain when following closely, with wind lines and a sound. Rewards closeness without contact and makes running in the pack tactical.  
  *Today:* None.
- [ ] **AI that reacts** `ai-reacts` · Missing  
  A wobble when hit, a counter-steer, a momentary grudge against whoever hit it, horns.  
  *Today:* AI gets only the raw physics.
- [ ] **Player's hits big, AI's hits small** `player-big-ai-small` · Partial  
  Hit-stop and shake make your own bumps feel powerful. AI-initiated contact on you stays capped and telegraphed so bumping reads as a mechanic, not punishment.  
  *Today:* Impulses are capped. No asymmetry in feedback yet.
- [x] **Ejections only for walls and landings** `ejections-walls-only` · Have  
  Keeps contact between cars friendly. A bump should never cost you the driver.  
  *Today:* Already excluded from car-on-car contact. Keep it.

Interactive copy with shared ticks: https://claude.ai/artifact/Ns2Sc7VXYfoz4Xxf5dtmxw (private, ask for access). This file is the source of truth.
