# Garaj v2 — prompturi ChatGPT pentru foile de concept ale masinilor

> **Ce e fisierul asta.** Pasul 1 din refacerea garajului: cate o **foaie de
> concept** (imagine de referinta) per masina, generata cu ChatGPT, din care
> se scrie apoi brieful Blender (dupa `_TEMPLATE.md`) si se construieste GLB-ul.
> Fisierul contine un bloc de CONTEXT (se lipeste o singura data) si 10
> prompturi de masini (se lipesc pe rand, in aceeasi conversatie).

## De ce

Masinile din garaj **nu mai sunt modelele free**: `build_open_garage.py` si
`build_toy_buggy.py` le-au refacut din cutii si grinzi, in cod, pe paleta
noastra, ca decapotabile cu sofer ejectabil. FBX-urile RgsDev (`muscle.fbx`,
`taxi.fbx`, `police_sports.fbx`, `firetruck.fbx`, `bus.fbx`) raman in
`assets/models/vehicles/`, dar nu le mai incarca niciun `.tres`.

Problema reala e deci **forma**, nu licenta: cutii stivuite nu citesc a masina
de calitate (`snapshots/garage_muscle.png`, `garage_c5.png`). Garajul e primul
lucru pe care il vede jucatorul si masinile sunt, prin style bible §1,
singurele suprafete saturate din cadru — merita o silueta desenata, nu
asamblata din primitive.

## Cum se foloseste

1. Conversatie noua in ChatGPT. Lipeste blocul **CONTEXT** (§1) si ataseaza
   imaginea `docs/WhatsApp Image 2026-07-23 at 21.12.16.jpeg` (kitul de desert
   din care a pornit style bible-ul — ancora de stil). **Nu atasa capturile din
   garaj**: ar ancora modelul pe cutii.
2. Lipeste cate un prompt din §2, pe rand. Fiecare intoarce o imagine (foaia)
   plus o lista de cote si culori per piesa.
3. Salveaza imaginile ca `docs/asset_briefs/img/concept_<nume>.png`. Vederile
   ortografice sunt la aceeasi scara, deci cotele se extrag din pixeli (metoda
   de la piste: traseu/cote din imagine cu PIL).
4. Daca o foaie iese cu text, decaluri sau crom, cere refacerea cu
   "same vehicle, remove all lettering/decals, flat colors only" — modelele de
   imagini pun text din reflex, iar textul nu se poate modela pe paleta.

Prompturile sunt in engleza (raspuns mai fidel la generarea de imagini);
notele sunt in romana. Dupa foi vine pasul 2: brief per masina, build Blender,
`verify_glb.py ... --origin=assembly`, `.tres` nou.

## Ce constrangeri intra in context, si de ce (pentru noi)

| constrangere | sursa |
|---|---|
| cockpit deschis la **toate** masinile, soferul se vede si poate fi ejectat | verdictul dezvoltatorului 18 sep 2026 ("toti ragdoll"), `docs/prototip_sofer_ragdoll.md` |
| culori plate, doar sloturile de masina (14-16) + sloturile deja folosite pe vehicule | style_bible §1 (masinile la saturatie 0.85-1.0, mediul la 0.45-0.60); `toy_driver_parts.py` |
| fara text, decaluri, crom, PBR | style_bible §4: masinile raman pe paleta, fara texturi; textul s-ar picta din sloturi, scump si murdar |
| detaliu structural DA, zgomot sub-centimetric NU | **„La masini nu facem economie, trebuie sa arate foarte bine"** (dezvoltatorul, 17 oct 2026). Regula §3 din style_bible („fara detaliu de frecventa inalta") e scrisa pentru decorul vazut in treacat; o masina e o instanta, pe un singur material, mereu in prim-plan (chase cam la 12 m, vitrina de aproape). Brate de suspensie, cusca cu contravantuiri, esapament, motor la vedere: toate DA. Doar suruburi, nituri, cabluri si profil de anvelopa NU — nu se citesc nici in vitrina |
| cote in metri, ancorate pe masina de 4 m | style_bible §2; `body_length`/`body_width` din `CarData` dimensioneaza colizorul |
| roti r 0.37-0.46 | fizica le clampeaza la 0.22-0.42 (`car.gd`, `_susp_wheel_radius`); peste 0.42 e doar vizual — vezi nota la Monster |
| 4 vederi la aceeasi scara: 3/4 hero + lateral/fata/sus ortografic | ca sa putem masura, nu ghici |

## Lista celor 10 (identitate din `.tres` unde exista)

| # | masina | identitate in garaj | masa | L × W × H (m) | roata r | fisier tinta |
|---|---|---|---|---|---|---|
| 1 | Buggy | cea mai usoara, grip mare, suspensie moale | 1.0 | 3.7 × 2.1 × 1.5 | 0.42 | `vehicles/buggy_v2.glb` |
| 2 | Muscle (roadster) | cea mai rapida la viteza maxima, teapana | 1.35 | 4.2 × 1.9 × 1.2 | 0.38 | `vehicles/roadster_v2.glb` |
| 3 | Politia (interceptor) | acceleratie si grip maxime, usoara | 0.9 | 4.2 × 1.9 × 1.35 | 0.37 | `vehicles/police_v2.glb` |
| 4 | Taxi | echilibrata | 1.15 | 3.9 × 2.0 × 1.4 | 0.38 | `vehicles/taxi_v2.glb` |
| 5 | Pompierii (pumper) | grea, lenta, impinge | 2.0 | 4.9 × 2.0 × 2.0 | 0.44 | `vehicles/firetruck_v2.glb` |
| 6 | Autobuzul (tour bus) | cea mai grea, leganata | 2.6 | 5.5 × 2.1 × 2.3 | 0.46 | `vehicles/bus_v2.glb` |
| 7 | Ambulanta | NOUA: grea-medie, inalta, se apleaca in viraj | ~1.8 | 4.6 × 2.1 × 2.2 | 0.40 | `vehicles/ambulance.glb` |
| 8 | Camioneta (pickup) | NOUA: medie, garda mare, off-road | ~1.3 | 4.5 × 2.0 × 1.7 | 0.42 | `vehicles/pickup.glb` |
| 9 | Tow truck | NOUA: grea, lunga, carlig pe brat | ~2.2 | 5.0 × 2.1 × 2.1 | 0.44 | `vehicles/tow_truck.glb` |
| 10 | Monster truck | NOUA: roti uriase, centru de masa sus, saltareata | ~1.6 | 4.4 × 2.6 × 2.4 | 0.62 (vizual, vezi §4) | `vehicles/monster.glb` |

Masele pentru 7-10 sunt propuneri, nu contract: scara din `CarData` e 0.9
(sport) .. 2.6 (autobuz) si cere valori departate intre ele, nu inghesuite.

---

## 1. CONTEXT (se lipeste o singura data, cu imaginea kitului atasata)

```
You are helping me design the car roster for TOY RACER, a mobile 3D arcade
racing game with toy cars. I will ask you, ONE VEHICLE AT A TIME, for a
CONCEPT / REFERENCE SHEET image that a 3D artist will model from in Blender.
Keep this context for every vehicle in this conversation.

== THE GAME'S LOOK ==
- Tone: a hand-made tabletop diorama (think Art of Rally, Reckless Racing 3,
  Beach Buggy Racing). NOT photoreal, NOT a scale model. Low-poly, chunky,
  rounded. The attached image is the desert prop kit the world is built from:
  match its charm, but cars are much cleaner and more saturated than the props.
- Cars are TOYS: oversized wheels, wide track, short overhangs, thick bumpers,
  rounded corners (about 4 cm bevel at real scale), vertical proportions
  exaggerated by ~15-20%. Bodies are CHUNKY: the cabin or tub is at least two
  thirds of the track width, never a narrow spine between wide wheels.
- Cars are the HERO assets of the game: the player's car fills the screen
  and the garage shows it up close on a rotating podium. So structural detail
  is welcome and wanted: suspension arms, roll-cage bracing, exhausts, engine
  parts, mirrors, spoilers, racks, bumpers with shape. Make them look
  great. Keep every part chunky and rounded (nothing thinner than ~4 cm) and
  skip only sub-centimeter noise: bolts, rivets, wires, panel seams, tire
  tread.
- Everything is FLAT COLOR from a fixed palette. No gradients, no metallic
  paint, no chrome, no reflections, no textures, no weathering, no decals,
  no logos, no license plates and NO LETTERING of any kind (where a real
  vehicle would have text, use a plain color block or a stripe).
- OPEN COCKPIT, ALWAYS. Every vehicle is an open-top / open-cab version of
  its type, because a toy driver figurine sits in it and is thrown out on
  big crashes (ragdoll). No roof over the driver, no doors needed, at most
  a short windscreen (~35 cm tall) and a roll hoop or cage. The figurine is a
  toy figure with these proportions, ~1.1 m tall when seated: head ~0.40 m,
  shoulders ~0.50 m wide, simple white helmet, colored shirt, dark pants.
  Draw it with care, it is part of the car's look. It sits on the LEFT,
  unless the vehicle is a single-seater (center). Give it a real seat at
  least 0.6 m wide and a steering wheel.
- Lights: EVERY vehicle has two headlight blocks at the front and two tail
  light blocks at the rear, rectangular or round, in the "glass" color (the
  game makes them glow). Big and obvious.
- Wheels: four identical wheels, fat cylinders: tire in near-black with a
  lighter hub. Radius 0.37-0.46 m on a 4 m car. They stick out past the body
  enough to read as toy wheels.

== PALETTE (hex) — use ONLY these ==
Main body colors (the only saturated colors in the game; cars own them):
  car red #E54839 · car blue #2C82E8 · car yellow #F2D03C
Support colors allowed on vehicles:
  white #E9F2F0 (stripes, trim, white bodies)
  near-black #55535A (tires, cages, bumpers, grilles, chassis)
  light grey #B8B4AC (hubs, bare metal, ladders, booms)
  dark brown #4A3526 (seats, cargo beds, interiors)
  glass turquoise #7FC4C9 (windscreens, light lenses)
  green #3F7A3C (secondary body color)
  orange #E8622D (small hazard accents only)
  steel blue-grey #7692A8 (tanks, work gear)
  rust #91461E (worn work gear, small areas)
Rules: at most 5 colors per vehicle. One dominant body color on 50%+ of the
body. Stripes and checkers are solid blocks at least 15 cm wide, never thin
lines. Each color patch is one flat material.

== SCALE ==
1 unit = 1 m. Reference: a normal car is 4.0 m long and 2.0 m wide. Each
vehicle comes with its length × width × height and wheel radius: respect them,
they are game-physics contracts (collider, mass, suspension travel).

== WHAT TO DELIVER FOR EACH VEHICLE ==
Generate ONE image, 3:2 landscape, light neutral grey background (#D8D8D8),
no scenery, no ground texture, only a soft contact shadow under the wheels,
soft even studio light. Layout:
  - TOP (large): three-quarter FRONT view from the driver's (left) side,
    camera slightly above (~15-20 degrees elevation), WITH the driver
    figurine seated.
  - BOTTOM row (small, all at the same scale): true orthographic SIDE view
    (left side), FRONT view, TOP view — WITHOUT the figurine, so the body
    silhouette is clean for modeling. The wheel diameter must be IDENTICAL
    in pixels across the three orthographic views: they are one drawing seen
    from three sides, and the wheel is our ruler.
All views show the same vehicle with identical colors. No labels, no
captions, no dimension arrows, no text anywhere in the image.
After the image, write a short list: dimensions (L × W × H, wheel radius,
wheelbase, track width, ground clearance), the color of each part (body,
trim, cage, seats, wheels, lights) using the palette names above, and the
seat position (left/center, approximate seat height).
Keep the same figurine, camera angle, lighting and background on every sheet
in this conversation so the roster reads as one family.

Do not produce anything yet. Reply "ready".
```

---

## 2. Prompturile de masini (cate unul pe rand)

### 2.1 Buggy

```
VEHICLE 1/10 — BUGGY (light off-road single-seater)
Garage identity: the lightest, most agile car; high grip, soft bouncy
suspension. It must LOOK light: a bare tub on big exposed wheels, lots of
negative space through the cage.
Dimensions: 3.7 m long × 2.1 m wide over the wheels × 1.5 m to the top of
the cage. Wheel radius 0.42 m, width 0.36 m, fully exposed, no fenders.
The tub is 1.4 m wide — two thirds of the track, a chunky toy stance, NOT a
narrow sand rail — and sits 0.35 m above the ground.
Shape: a roll cage of thick tubes (~8 cm) with real bracing around a single
center seat; short sloped hood with two round headlights on a thick front
nudge bar; chunky suspension arms to the front wheels; behind the seat an
EXPOSED ENGINE, near-black, as tall as the seat back, with visible cylinder
heads and a short fat exhaust; two rectangular tail lights on the back of
the tub.
Colors: tub car yellow; cage, nudge bar, suspension arms, engine and tires
near-black; seat dark brown; hood panel white; hubs and exhaust light grey;
lights glass turquoise.
Memorable feature: the exposed engine behind the driver, and the wheels
being almost as tall as the tub.
Driver: single seat, center.
```

### 2.2 Muscle (roadster)

```
VEHICLE 2/10 — MUSCLE ROADSTER (the fast one)
Garage identity: highest top speed, stiff suspension, planted and heavy-ish.
It must look LONG and LOW: long hood, short rear deck, wide rear haunches.
Dimensions: 4.2 m long × 1.9 m wide × 1.2 m high (top of the roll hoop).
Wheel radius 0.38 m, width 0.34 m, tucked under bulging arches but still
proud of the body. Ground clearance 0.25 m.
Shape: two-seat open roadster, short wraparound windscreen, a single thick
roll hoop behind the seats; a big rectangular hood bulge (scoop) as one
solid block; blunt front with a wide near-black grille block and two
rectangular headlights; small duck-tail lip at the rear; thick bumpers.
Colors: body car red; two wide white racing stripes over hood, scoop and
deck (solid blocks, ~25 cm each); grille, bumpers, hoop and tires
near-black; seats dark brown; hubs light grey; lights glass turquoise.
Memorable feature: the hood scoop and the twin stripes.
Driver: left seat, passenger seat empty on the right.
```

### 2.3 Politia (interceptor)

```
VEHICLE 3/10 — POLICE INTERCEPTOR (the grippy one)
Garage identity: best acceleration and grip, the lightest of the sedans.
Nimble, sharp, slightly nose-down stance.
Dimensions: 4.2 m long × 1.9 m wide × 1.35 m to the top of the light bar.
Wheel radius 0.37 m, width 0.32 m. Ground clearance 0.22 m.
Shape: open two-seat body with a short windscreen and a roll hoop; a chunky
LIGHT BAR mounted on top of the hoop, made of two blocks (one car red,
one car blue) with a white center block; a thick near-black push bar on
the nose; two rectangular headlights; flat trunk.
Colors: body white with a car-blue hood block and a car-blue lower side
band (a solid band ~30 cm tall, no text); push bar, hoop, bumpers and tires
near-black; seats dark brown; hubs light grey; lights glass turquoise.
Memorable feature: the red/blue light bar on the hoop and the push bar.
Driver: left seat.
```

### 2.4 Taxi

```
VEHICLE 4/10 — TAXI CAB (the balanced one)
Garage identity: average everything, friendly and boxy, the "normal car"
of the roster. Upright and tall for its length.
Dimensions: 3.9 m long × 2.0 m wide × 1.4 m to the top of the roof sign.
Wheel radius 0.38 m, width 0.34 m. Ground clearance 0.25 m.
Shape: tall boxy open cab with a bench seat, short windscreen and a wide
roll hoop; a small white rectangular ROOF SIGN block on top of the hoop
(plain, no text); a checker band along the sides at belt height made of
alternating white and near-black squares, each ~18 cm (solid blocks);
upright front with a flat grille block and two round headlights; thick
bumpers.
Colors: body car yellow; checker band white + near-black; hoop, bumpers,
grille and tires near-black; bench seat dark brown; hubs light grey; lights
glass turquoise.
Memorable feature: the checker band and the sign block on the hoop.
Driver: left side of the bench.
```

### 2.5 Pompierii (pumper)

```
VEHICLE 5/10 — FIRE PUMPER (the heavy pusher)
Garage identity: heavy and slow but it shoves everything out of the way.
Must look DENSE: short, tall, thick-walled, big wheels.
Dimensions: 4.9 m long × 2.0 m wide × 2.0 m to the top of the ladder.
Wheel radius 0.44 m, width 0.40 m. Ground clearance 0.35 m.
Shape: open cab at the front with a bench seat and a roll hoop; behind it
a tall rectangular body carrying a horizontal steel tank; a long ladder
laid on top at a slight angle, overhanging the rear; two fat hose reels
(simple drums) on the sides; a thick front bumper and a single big round
bell block on the cab front.
Colors: body car red; a wide white band along the body sides; tank steel
blue-grey; ladder, hose reels, bell and hubs light grey; hoop, bumper and
tires near-black; seats dark brown; lights glass turquoise.
Memorable feature: the ladder silhouette and the tank.
Driver: left side of the bench.
```

### 2.6 Autobuzul (tour bus)

```
VEHICLE 6/10 — OPEN-TOP TOUR BUS (the heaviest)
Garage identity: the heaviest vehicle by far, slow, with soft swaying
suspension. Must look like a wall on wheels: tall flat front, long box.
Dimensions: 5.5 m long × 2.1 m wide × 2.3 m high at the front. Wheel
radius 0.46 m, width 0.40 m. Ground clearance 0.35 m.
Shape: single-deck open-top bus. Tall flat front face with two big
rectangular headlights and a wide near-black grille block; the driver sits
HIGH at the front-left behind a short windscreen; behind the driver three
rows of bench seats visible from above; body sides come up to belt height
(~1.3 m) and the rear is a flat face; thick bumpers front and rear.
Colors: body green; a wide white band along the sides and across the front
below the windscreen; benches dark brown; grille, bumpers and tires
near-black; hubs light grey; lights glass turquoise.
Memorable feature: the tall flat front and the rows of benches.
Driver: front-left, elevated seat.
```

### 2.7 Ambulanta

```
VEHICLE 7/10 — AMBULANCE (tall van, new)
Garage identity: medium-heavy and TOP-HEAVY: a tall box that leans in corners
and rewards careful driving. Must look tall and narrow for its height.
Dimensions: 4.6 m long × 2.1 m wide × 2.2 m to the top of the box. Wheel
radius 0.40 m, width 0.36 m. Ground clearance 0.30 m.
Shape: open cab at the front (bench seat, short windscreen, roll hoop) and
a tall closed cargo BOX behind it, taller than the cab; the box has a flat
rear face with two small square windows; a chunky light block (car red +
car blue) on the front top edge of the box; two rectangular headlights;
thick bumpers.
Colors: box and cab white; a wide car-red band around the lower half of the
box and cab; light block car red + car blue; hoop, bumpers, grille and
tires near-black; seat dark brown; hubs light grey; lights and windows
glass turquoise. No cross symbol, no lettering: the identity is the tall
white box with the red band.
Memorable feature: the box standing well above the open cab.
Driver: left side of the bench.
```

### 2.8 Camioneta (pickup)

```
VEHICLE 8/10 — RANCH PICKUP (lifted off-roader, new)
Garage identity: medium weight, high ground clearance, happy off the road.
Must look LIFTED: visible gap between tires and arches, tall stance.
Dimensions: 4.5 m long × 2.0 m wide × 1.7 m to the top of the hoop. Wheel
radius 0.42 m, width 0.38 m, with chunky square-cut arches. Ground
clearance 0.40 m.
Shape: open single cab (bench seat, short windscreen, roll hoop) and an
open cargo bed behind; in the bed a spare wheel standing upright against
the cab and one big crate; a thick bull bar across the nose with two round
headlights on it; thick rear bumper with a flat tailgate.
Colors: body car blue; tailgate and hood block white; bed interior, bull
bar, hoop, bumpers and tires near-black; crate and seat dark brown; hubs
light grey; lights glass turquoise.
Memorable feature: the standing spare wheel in the bed and the lifted gap
over the wheels.
Driver: left side of the bench.
```

### 2.9 Tow truck

```
VEHICLE 9/10 — TOW TRUCK (heavy, long, new)
Garage identity: heavy and long, slow to turn, strong in contact. The hook
on the boom is its whole silhouette.
Dimensions: 5.0 m long × 2.1 m wide × 2.1 m to the top of the boom. Wheel
radius 0.44 m, width 0.40 m; rear wheels may be doubled (two tires side by
side). Ground clearance 0.35 m.
Shape: open cab at the front (bench seat, short windscreen, roll hoop) with
a small orange warning light block on the hoop; behind the cab a flat
steel deck; from the deck an angled BOOM rises toward the rear and ends in
a big, thick, toy-like HOOK hanging on a short chain made of 3-4 fat links;
a thick front bumper and a thick rear bumper with two orange hazard blocks.
Colors: body car yellow; deck and boom light grey; hook and chain
near-black; hazard blocks and warning light orange; hoop, bumpers and tires
near-black; seat dark brown; hubs light grey; lights glass turquoise.
Memorable feature: the boom and hook rising above the rear.
Driver: left side of the bench.
```

### 2.10 Monster truck

```
VEHICLE 10/10 — MONSTER TRUCK (giant wheels, new)
Garage identity: the bounciest car: huge wheels, soft long-travel
suspension, high center of mass. The wheels are the vehicle; the body is a
small cab perched on top of a visible frame.
Dimensions: 4.4 m long × 2.6 m wide over the wheels × 2.4 m to the top of
the cage. Wheel radius 0.62 m, width 0.55 m, fully exposed, taller than
the cab floor. Ground clearance 0.75 m under the frame.
Shape: four giant wheels on a chunky near-black ladder frame with visible
thick axles; on top a small open pickup cab (single seat, short windscreen,
full roll cage) and a short bed; a thick nudge bar with two round
headlights; nothing hangs below the frame.
Colors: cab and bed car red; a wide white chevron block on the hood and a
white band on the bed sides; frame, axles, cage, nudge bar and tires
near-black; hubs light grey; seat dark brown; lights glass turquoise.
Memorable feature: wheels taller than the cab.
Driver: single seat, center.
```

### 2.11 Soferii (skinuri)

> **Cum stau azi.** Figurina NU face parte din modelul masinii: e un GLB
> separat (`toy_driver*.glb`), instantiat din cod de `Car.apply_data` sub
> `_visual`, la cota `CarData.driver_seat`, doar pe caroserii cu
> `open_cockpit`. Dar **perechea e fixata in fiecare `.tres`**
> (`driver_model`): buggy si muscle → tricou albastru, politia si pompierii →
> galben, taxi → verde, autobuzul → rosu. „Skin" inseamna azi doar culoarea
> tricoului si a dungii de pe casca, pe un singur corp
> (`build_driver(shirt, filename, stripe)` in `toy_driver_parts.py`).
> Nicaieri in garaj nu se alege soferul.
>
> **Contractul care nu se schimba** (il citesc `driver.gd` si
> `toy_ragdoll.gd`): 7 piese rigide cu numele `Hips, Torso, Head, Arm_L,
> Arm_R, Leg_L, Leg_R`, originea fiecarei piese in articulatia ei, originea
> ansamblului pe sezut; cotele corpului (cap cub 0.40 m, trunchi 0.50 lat ×
> 0.48 inalt, solduri 0.22, brat 0.48, picior 0.42 + 0.40) — pentru ca poza
> procedurala roteste piesele din umar/gat/sold, ragdoll-ul face cutii din
> AABB-ul lor, iar `driver_seat` e reglat per masina pe corpul asta. Un skin
> nou schimba **culorile si capul** (casca, accesorii ca blocuri lipite de
> cap), nu proportiile.

```
DRIVER SKINS — a lineup of 6 toy driver figurines (same body, different
characters). All vehicles in this roster share ONE driver body, and each
character is a "skin" on it. The body is a chunky blocky toy figure made of
7 rigid parts (hips, torso, head, left arm, right arm, left leg, right leg),
seated: ~1.1 m tall seated, cube head 0.40 m, torso 0.50 m wide × 0.48 m
tall, arms and legs are simple blocks. The proportions are a contract and
must be IDENTICAL on all 6; what changes is color and the head.

What may change per character:
- Colors: shirt, pants, helmet/hat and skin tone, from this palette only:
  shirt/hat accents: car red #E54839 · car blue #2C82E8 · car yellow #F2D03C ·
  white #E9F2F0 · green #3F7A3C · orange #E8622D · near-black #55535A;
  pants: dark brown #4A3526 · near-black #55535A · steel blue-grey #7692A8;
  skin tones: #E8C074 · #C18446 · #915D27 · #67421F.
- The head: an open-face helmet with a colored stripe (the default look), a
  full-face helmet with a turquoise visor block (#7FC4C9), a flat cap, a
  cowboy hat, a bandana, a beanie; plus at most one accessory as a solid
  block glued to the head: goggles band, sunglasses band, mustache block,
  beard block, ponytail block. Everything stays within ~10 cm of the head
  cube; no thin or dangling parts.
- Each character must be recognizable by SILHOUETTE of the head from 12 m,
  not only by color. No text, no logos, no gradients, no fine detail.
Character 1 is the current default: white open-face helmet with a colored
stripe, colored shirt, dark brown pants, black shoes. Characters 2-6 are
yours to invent: distinct, friendly, toy-like, a mix of genders and skin
tones.

Deliver ONE image, 3:2 landscape, light grey background (#D8D8D8), soft
even studio light, no scenery: the 6 figurines seated in a row on identical
plain grey block seats, three-quarter front view from slightly above; below,
a row of the same 6 as orthographic FRONT views at the same scale. Same
pose for all. No text in the image.
After the image, list for each character: a short working name, the
colors of shirt / pants / hat / skin by palette name, and the head item and
accessory.
```

---

## 3. Lista de rezerva (urmatoarele, cand garajul cere mai mult)

Fiecare are o silueta si o identitate fizica distincte de cele 10 de sus;
altfel nu merita slotul in garaj (CLAUDE.md principiul 4).

| masina | de ce ar intra | identitate |
|---|---|---|
| Hot rod | deschis prin natura, motor la vedere, roti spate mari | rapid, instabil (spate greu) |
| Go-kart | cea mai mica si mai joasa; soferul e jumatate din silueta | foarte usoara, grip enorm, viteza mica |
| Jeep 4x4 | cutie deschisa clasica, roata de rezerva pe spate | medie, garda mare |
| Trophy truck | pickup de desert cu suspensie lunga la vedere | rapida pe off-road, moale |
| Tractor | roti spate uriase, fata mica | cea mai lenta, foarte grea, intoarce pe loc |
| Limuzina descoperita | cea mai lunga; ampatament absurd | grea, intoarce greu, rapida pe drept |
| Autobuz scolar | cutie galbena lunga, varianta a autobuzului | greu, leganat |
| Dubita de inghetata | cutie inalta cu con pe acoperis | medie, top-heavy ca ambulanta |
| Golf cart | mic, deschis, acoperis pe stalpi (fara geam in spatele soferului) | foarte usor, lent |
| Tuk-tuk (exista: Jodhpur) | trei roti, ecartament ingust | 0.34 masa, se rastoarna la impact lateral |
| Plug de zapada (exista: Baikal) | lama in fata = bumper urias | greu, impinge |

---

## 4. Lectii din prima foaie (buggy, 17 oct 2026)

`img/vehicles/concept_buggy.jpeg`, generata cu contextul in forma initiala.
Formatul a iesit cum a fost cerut (layout, fundal, paleta, fara text, figurina
doar in 3/4). Masurat pe vederile ortografice, cu diametrul rotii ca unitate
(scriptul e in istoricul sesiunii; PIL, masca pe intuneric si pe galben):

| ce | foaie | tinta |
|---|---|---|
| lungime / diametru roata (lateral) | 4.38 | 4.4 |
| ecartament / diametru roata (fata) | 2.50 | 2.5 |
| latime cuva / ecartament (fata) | **0.46** | 0.67 |
| diametru roata lateral vs fata | **120 vs 154 px** | identic |

Lungimea si ecartamentul au iesit exact. Cuva era prea ingusta (sand rail, nu
jucarie) si vederile nu erau la aceeasi scara — de aici randurile noi din
context despre „cabina cel putin doua treimi din ecartament" si „roata
identica in pixeli in cele trei vederi". Lipseau stopurile; acum sunt cerute
la toate masinile.

Prima reactie la foaie a fost sa interzicem bratele de suspensie si sa cerem
cusca din 8 tevi groase. **Respinsa de dezvoltator:** masinile sunt hero, nu
decor — detaliul structural ramane, contextul il cere acum explicit.

## 5. Note pentru noi (nu intra in prompt)

- **Monster truck si clampul rotii.** `car.gd` clampeaza raza de suspensie la
  0.22-0.42 m (`_susp_wheel_radius`), iar cursa de cast e `rest + raza`. O
  roata vizuala de 0.62 m cu cast de 0.42 m ar intra 20 cm in sol. Optiuni,
  in ordinea preferintei: (a) ridicam plafonul clampului la ~0.65 si
  verificam cu `ProbeRace --mode=bump` ca nu se schimba nimic la celelalte;
  (b) roata vizuala 0.42 si caroseria "ridicata" pe un cadru vizibil — ramane
  identitatea de lift, se pierde cea de roti uriase. Decizia e a
  dezvoltatorului; brieful Blender se scrie dupa ea.
- **Ambulanta fara cruce rosie.** Emblema crucii rosii pe fond alb e protejata
  (conventiile de la Geneva); in store listing ar fi un risc inutil. Identitatea
  vine din cutia inalta alba cu banda rosie si blocul de girofar.
- **Masele propuse (7-10)** se verifica cu `ProbeRace --mode=bump` inainte de
  `.tres`; regula din `CarData`: valori departate, 0.9 .. 2.6.
- **Contractul Blender** la pasul 2 (din `toy_driver_parts.py` si
  `build_open_garage.py`): fata spre Blender -Y, instantiere cu
  `model_rotation_deg = 180`; rotile noduri separate cu originea in centru si
  numele `<Prefix>_Wheel_Front_Left` etc. (cuvintele "wheel"/"front" sunt ce
  cauta `car.gd`); faruri/stopuri noduri separate `<Prefix>_Lamp_Head` /
  `<Prefix>_Lamp_Tail`; originea ansamblului la sol, `verify_glb.py ...
  --origin=assembly`; scaunul se traduce cu `seat_godot()` in
  `CarData.driver_seat`. **Buget: FARA plafon de triunghiuri la masini**
  („la masini nu facem economie" — dezvoltatorul, 17 oct 2026). O masina e o
  instanta pe un singur material (+ `finish:vehicle` + lampile), deci
  geometria e aproape gratis pe mobil; sase masini a cate 15-20k tri sunt
  sub o zecime din orice pista. Ce conteaza e sa nu aduca materiale sau
  texturi proprii. Cifra din `verify_glb.py` se trece ca masurata, nu ca
  plafon.
- **Soferul se alege separat de masina** (decizia dezvoltatorului, 17 oct
  2026, facuta pe ramura `feat/sofer-ales-in-garaj`): skinurile sunt resurse
  `DriverData` (`scenes/cars/data/drivers/*.tres`, listate in
  `GameState.DRIVER_DATA`), alegerea e `GameState.selected_driver` (persistata
  ca `selected_car`), garajul are randul DRIVER cu sageti si figurina in
  vitrina, iar jucatorul o primeste prin `Car.apply_data(...,
  driver_override)`. AI-ul ramane pe `CarData.driver_model`. **Un skin nou din
  lineup-ul de la §2.11 = un GLB nou + un .tres nou in lista, zero cod.** Toate
  skinurile stau pe acelasi `driver_seat`, deci nimic nu se re-regleaza per
  masina.
- **Asset nou = fisier nou** (memoria `blender-asset-workflow`): v2-urile nu
  suprascriu `open_*.glb`; `.tres`-ul se muta pe fisierul nou intr-un commit
  separat, dupa ce modelul s-a vazut in garaj.
- FBX-urile RgsDev neutilizate se pot sterge intr-un PR separat de curatenie,
  dupa ce `grep -r "\.fbx" scenes scripts tools` confirma ca nu le mai cere
  nimeni.
