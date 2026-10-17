class_name CarData
extends Resource
## Identitatea unei masini: statistici + culoare, ca resursa (.tres).
## O masina noua in garaj = un fisier nou, zero modificari in cod.
## Parametrii de feel globali (drift, gravitate) raman pe Car — aici e
## doar ce DIFERENTIAZA masinile intre ele.

@export var display_name: String = ""
## Culoarea de UI (swatch in rezultate/HUD); modelul isi are culorile lui.
@export var color: Color = Color.WHITE
@export var max_speed: float = 34.0     # m/s
@export var acceleration: float = 16.0
@export var grip: float = 8.0
## MASA masinii — cine impinge pe cine la contact. Intra ca 1/m in impulsul de
## coliziune (Car._resolve_bump), deci ce conteaza e RAPORTUL dintre doua masini:
## la contact, delta-v-ul fiecareia e invers proportional cu masa ei. Autobuzul
## (2.6) intrat in Politie (0.9) o trimite de ~3 ori mai tare decat se opreste el.
##
## Nu inghesui valorile: doua masini cu 1.0 si 1.1 se ciocnesc identic, iar
## "identitatea prin masa" dispare. Scara folosita in garaj: 0.9 (sport usor) ..
## 2.6 (autobuz). Verifica orice retunare cu:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRace.tscn -- --mode=bump
@export var mass_factor: float = 1.0
## Plafonul pe iarba/nisip, ca FRACTIE din viteza maxima — identitate off-road
## (pasul 0 din docs/cariera/mod_cariera.md): buggy-ul pierde mai putin pe iarba
## decat restul, deci scurtaturile prin off-road sunt ale lui. Sub 0 =
## implicitul global (Car.OFFROAD_SPEED_DEFAULT, 0.45), ca masinile fara parere
## sa ramana exact cum erau.
@export var offroad_speed_factor: float = -1.0

## Centrul de masa pe verticala (m fata de origine, sub 0 = mai jos, coborat).
## Identitate: majoritatea masinilor stau jos si stabil (-0.15, ca inainte de
## acest camp). Tuk-tuk-ul (Jodhpur, ecartament ingust) il ridica aproape de
## 0 — parghia scurta care il tine pe roti in viraj normal dispare, deci un
## impact lateral tare il poate rasturna. E identitate voita (CLAUDE.md
## principiul 1: contactul intre masini e mecanica, nu bug), nu un defect de
## reglat — vezi tools/probe_jod_tuk.gd pentru cifrele masurate.
@export var center_of_mass_y: float = -0.15

@export_group("Suspensie")
## Frecventa naturala a arcurilor (Hz) — RIGIDITATEA ca identitate: sportiva
## teapana (2.8-3.0), autobuzul moale si leganat (1.8). Compresia statica e
## g/omega^2, deci o frecventa joasa cere si cursa mai lunga (vezi mai jos).
@export var spring_freq: float = 2.5
## Raportul de amortizare (1 = critic): cat de repede se ASAZA caroseria dupa
## o leganare. Jos = balanseaza (autobuz), sus = revine sec (sport).
@export var damping_ratio: float = 0.6
## Cursa arcului in repaus (m). Regula: compresia statica (g/omega^2) sa cada
## in 25-50% din cursa — altfel arcul e ori teapan, ori la fund.
@export var suspension_rest: float = 0.35

@export_group("Model 3D")
## Scena modelului (FBX importat); daca lipseste, se deseneaza cuburi.
@export var model: PackedScene
@export var model_scale: float = 1.0
## Corectie de orientare (modelele RgsDev privesc spre +Z; fata Godot = -Z).
@export var model_rotation_deg: float = 180.0
## Dimensiunile vizuale DUPA scalare — dimensioneaza colizerul si efectele.
@export var body_length: float = 3.8
@export var body_width: float = 2.2
## Modelul e un GLB din pipeline-ul nostru (UV pe atlasul de paleta, AO in
## vertex colors) si primeste `Palette.world_material()` la instantiere.
## Fals pentru FBX-urile RgsDev, care isi aduc materialele lor.
@export var palette_model: bool = false

@export_group("Sofer")
## Masina e DESCHISA (buggy, decapotabila): soferul se vede si poate fi
## aruncat afara la impact (vezi Car._eject). Pe o caroserie inchisa figurina
## ar sta ascunsa in interior, deci nu se ataseaza deloc.
@export var open_cockpit: bool = false
## GLB-ul figurinei: 7 piese rigide ca noduri separate (vezi Driver.PART_NAMES).
## E doar IMPLICITUL (AI-ul il foloseste): jucatorul isi alege soferul in garaj,
## separat de masina (GameState.DRIVER_DATA), si il primeste prin
## `Car.apply_data(..., driver_override)`.
@export var driver_model: PackedScene
## Unde se aseaza SEZUTUL figurinei, in spatiul masinii (fata = -Z, sus = +Y),
## dupa scalarea si rotirea modelului. Cota scaunului, nu a picioarelor.
@export var driver_seat: Vector3 = Vector3(0.0, 0.6, 0.2)
