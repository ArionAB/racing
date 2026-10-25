class_name Car
extends RigidBody3D
## Masina pe FIZICA INTREAGA (pivotul #261, integrata in joc la #258): un
## RigidBody3D sprijinit pe 4 raycasturi cu arc + amortizor, cate unul per
## roata. Ruliul, tangajul si legănarea peste denivelari ies din fizica, nu
## mai sunt efecte desenate. Comenzile vin de la un CarController (player sau
## AI), identitatea (statistici/culoare) dintr-un CarData — neschimbat.
##
## Ce ramane arcade, deliberat: directia scrie viteza unghiulara pe Y direct
## (un torque "realist" ar fi inca un etaj intre jucator si raspuns), grip-ul
## lateral e o forta de amortizare a vitezei laterale, plafonul de viteza e o
## contra-forta. Fortele de cauciuc se aplica LA SOL, nu in centrul de masa —
## de acolo vin ruliul in viraj, squat-ul la accelerare, dive-ul la frana.
##
## Compatibilitate: `velocity` si `is_on_floor()`/`get_floor_normal()` raman
## ca proprietate/metode-shim peste linear_velocity si suspensie, ca tot ce
## vorbeste cu masina (hazarde, sonde, AI) sa nu-si schimbe limbajul.
##
## Turbo model Ignition: o bara care se incarca in timp (mai repede in
## drift) si pe care o arzi CAND VREI TU tinand butonul de turbo — skill de
## decizie (pe ce dreapta, inaintea carei sarituri), nu de timing la viraj.
## Drift-ul e handbrake pur, iar pe fizica intreaga taie aderenta DOAR LA
## SPATE: fata tine, spatele aluneca — unghiul de derapaj e consecinta, nu
## simulare.

signal boost_started(car: Car)
## Frana de mana eliberata dupa un drift de `seconds`. HUD-ul pulseaza bara
## de turbo: rasplata (umplerea 2.5x) se vede in clipa in care se termina.
signal drift_ended(car: Car, seconds: float)
signal wall_hit(car: Car, impact: float)
signal landed(car: Car, fall_speed: float)
signal respawned(car: Car)
## Masina rasturnata s-a intors pe roti PE LOC (vezi `_tick_upright`), fara
## repunere. Pentru camera/sunet/particule: nu e `respawned`.
signal uprighted(car: Car)
## Repunerea cu tranzitie a inceput (#495): masina clipeste `RECOVER_S`
## secunde, fara comenzi, apoi vine `respawned`. Race intuneca ecranul.
signal recovery_started(car: Car, seconds: float)
## Izbitura cu o alta masina, cu delta-v-ul incasat de NOI — cu cat mai mare,
## cu atat mai violent contactul (shake, sunet).
signal bumped(car: Car, other: Car, delta_v: float)
## Strivit de un hazard. `severity` in 0..1, pentru shake proportional.
signal crushed(car: Car, severity: float)
## Aprinsa de o coloana de foc. `seconds` = cat arde, ca sa poata HUD-ul si
## camera sa-si potriveasca efectele pe aceeasi durata.
signal ignited(car: Car, seconds: float)
## Lovit de o masa de apa (valul care spala digul). `strength` in 0..1.
##
## Semnal separat de `crushed` desi amandoua zguduie ecranul: `crushed` inseamna
## si turtire, si plafon de viteza taiat secunde intregi — un val nu te striveste,
## te uda si te impinge. Legate la acelasi semnal, ar fi trebuit tunate impreuna.
signal splashed(car: Car, strength: float)
## Prins de o rafala de abur (fumarolele de pe coasta Stromboli). `seconds` =
## cat tine albirea, ca HUD-ul sa-si potriveasca efectul pe aceeasi durata.
##
## Semnal separat de `splashed` desi amandoua sunt „ti-a intrat ceva in fata":
## valul te si IMBRANCESTE si te uda, deci trebuie tunat impreuna cu fizica.
## Aburul nu atinge masina deloc — daca ar fi legate, prima tunare a valului ar
## fi mutat si comportamentul unui hazard care prin definitie nu costa nimic.
signal blinded(car: Car, seconds: float)
## A intrat pe / a iesit de pe TREPTE (ruina ca si carosabil, Machu Picchu).
## Carligul pentru audio si camera: cine vrea „huruitul rotilor pe piatra" se
## leaga aici, nu citeste suspensia. Se emite doar la tranzitie.
signal steps_changed(car: Car, on: bool)
## Soferul a fost ARUNCAT din masina (buggy deschis, impact dur). `ragdoll` e
## figurina cazuta, deja in lume — camera o urmareste cat tine `eject_hold`,
## apoi masina se repune pe pista si soferul reapare pe scaun.
signal ejected(car: Car, ragdoll: Node3D)
## Feed-ul comun de contact (docs/feel_checklist.md): orice izbitura de perete
## sau de alta masina peste `impact_min_dv`, cu directie si punct. `kind` e
## &"wall" sau &"car"; `normal` e orizontala si arata DINSPRE obstacol SPRE
## masina (directia in care esti impins); `other` e corpul lovit. Il citesc
## camera, caroseria, soferul si sunetul — nu mai adauga consumatori in
## _process_contacts, conecteaza-te aici.
signal impact(car: Car, kind: StringName, strength: float, normal: Vector3,
		point: Vector3, other: Node)

## Efecte vizuale comune (fara class_name: se preincarca).
const SoftVegetation := preload("res://scenes/props/soft_vegetation.gd")
const PropDebris := preload("res://scenes/props/prop_debris.gd")

# --- Statistici (suprascrise de CarData la apply_data) ---
@export_group("Motor")
@export var max_speed: float = 34.0
@export var acceleration: float = 16.0
@export var brake_force: float = 30.0
@export var reverse_speed: float = 10.0
## Atentie la echilibru: viteza maxima reala = min(max_speed, acceleration/drag).
## Drag-ul trebuie tinut destul de mic incat plafonul max_speed sa conduca.
@export var drag: float = 0.35

@export_group("Directie")
@export var steer_speed: float = 1.9
@export var grip: float = 8.0
## Cat din unghiul de volan ramane la viteza maxima (1.0 = fara strangere).
## La viteza mica ai volan plin; de la `steer_taper_start` in sus unghiul scade
## liniar pana la valoarea asta la max_speed, ca masina sa nu devina nervoasa
## pe drepte (feel_checklist: steering-speed). DRIFT-ul e scutit: termenul se
## amesteca spre 1.0 cu `_drift_amount()`, deci frana de mana ramane unealta
## de viraj stransa la orice viteza.
@export_range(0.3, 1.0, 0.01) var steer_taper_at_top: float = 0.65
## De la ce fractie din max_speed incepe strangerea (sub ea: volan plin).
@export_range(0.0, 1.0, 0.01) var steer_taper_start: float = 0.5

@export_group("Drift (handbrake)")
@export var drift_grip: float = 2.0
## Aderenta laterala intr-o balta de furtun: aproape zero, treci prin ea in
## sub o secunda.
const SLIP_GRIP_PUDDLE: float = 0.8
## Aderenta pe o suprafata uda pe care se CONDUCE, nu prin care se trece.
## Intre drift (2.0) si asfalt (7-10): simti ca aluneca, dar poti tine linia.
const SLIP_GRIP_WET: float = 3.6
## Aderenta pe GHEATA (drumul de gheata al Baikalului): sub drift. Aici drift-ul
## nu mai e unealta de viraj, e modul de condus. Tema poate suprascrie prin
## Track.ice_grip(); asta e implicitul.
const SLIP_GRIP_ICE: float = 1.5
## Cat de strans vireaza driftul cand tii volanul SPRE interior, in unitati
## de volan plin (1.0 = virajul normal cu volan plin). Maparea CTR (oct 2026):
## in drift volanul nu mai alege SENSUL — ala e `drift_dir`, fixat la intrare
## — ci doar RAZA, intre `drift_arc_wide` (contravolan plin) si
## `drift_arc_tight` (volan spre interior). Contravolanul largeste alunecarea,
## n-o inverseaza: asa „prinzi" un spate care fuge, ca in orice drift arcade.
@export var drift_arc_tight: float = 1.6
## Acelasi arc strans la viteza maxima (intre ele, liniar pe viteza). Mai mic
## decat 1.6: la 29 m/s un arc de 1.6 inseamna 3 rad/s, adica tromba. Dar NU
## zero, cum era `drift_yaw_at_top` pana in oct 2026: fara rotatie in plus, la
## viteza de cursa frana de mana nu mai era decat o frana cu ruliu. Unghiul de
## derapaj E driftul — ProbeDriftEntry il cere >= 18° la 85% din vmax.
@export var drift_arc_tight_top: float = 1.25
## Arcul cu contravolan plin: aproape drept, dar tot in sensul driftului.
@export var drift_arc_wide: float = 0.2
## Constanta de timp (s) cu care rotatia URMEAZA comanda cat esti in drift. Pe
## asfalt rotatia e scrisa direct (arcade: volanul e rotatia); in drift are
## inertie, ca sa existe ce prinde cu contravolanul. Fara ea, volanul lasat
## liber oprea rotatia in acelasi tick: alunecarea se termina ca un
## intrerupator, nu ca un spate care se aseaza.
@export var drift_yaw_inertia: float = 0.25
## Cat din impulsul inainte pierdut prin frecarea laterala se intoarce ca forta
## pe directia caroseriei cat drifteaza (0 = nimic, 1 = viteza se pastreaza
## intreaga). Scalat cu gazul: ▲+DRIFT tine viteza (powerslide), DRIFT singur
## o pierde pe inertie, ▼+DRIFT franeaza. Fara asta fata, cu aderenta plina,
## „scrubuia" componenta laterala si driftul frana ca un zid: la 62% din vmax
## pierdea 36% din viteza intr-o secunda (masurat, oct 2026).
@export var drift_momentum_keep: float = 0.85
## Rotatie IN PLUS, doar pe model, in sensul driftului (grade la drift plin).
## Trucul din kart-uri: caroseria arata mai intoarsa decat e fizic, iar
## alunecarea se citeste de la prima privire, nu din urmele de pe asfalt.
@export var drift_visual_yaw_deg: float = 10.0
@export var drift_min_speed: float = 9.0
## Secunde in care driftul intra deplin dupa ce tragi frana de mana. Inainte
## era un singur tick: rotatia sarea cu 60% si aderenta spatelui scadea de 4
## ori dintr-un cadru intr-altul — smucitura, nu alunecare.
@export var drift_ramp_in: float = 0.2
## Secunde in care spatele se reaseaza dupa ce eliberezi frana de mana.
@export var drift_ramp_out: float = 0.25
## Driftul se dozeaza pe viteza: la drift_min_speed e pivotul strans, spre
## viteza maxima un arc mai larg (`drift_arc_tight_top`) cu spatele mai ferm.
## Inainte era acelasi pivot la orice viteza — la 29 m/s: 3.3 rad/s (190°/s),
## 42° de derapaj si 11 m/s pierduti in jumatate de secunda.
##
## Aderenta spatelui in drift la viteza maxima (`drift_grip` e cea de la
## drift_min_speed; intre ele, liniar). MAI MARE decat drift_grip, nu mai mica:
## rotatia driftului vine mai ales din dezechilibrul fata-spate (fata tine,
## spatele cedeaza, forta de pe fata suceste caroseria) — un spate mai moale
## inseamna mai multa rotatie, nu un arc mai larg. Masurat in ProbeDriftEntry:
## cu yaw_at_top 0, spatele la 1.2 dadea tot 2.8 rad/s la 29 m/s.
@export var drift_grip_at_top: float = 4.0

@export_group("Turbo (model Ignition)")
## Secunde pana la umplerea barii doar din mers.
@export var turbo_fill_time: float = 10.0
## In drift bara se umple de atatea ori mai repede — driftul ramane rasplatit.
@export var turbo_drift_multiplier: float = 2.5
## Contratimpul de cariera (brief 4.2) il pune pe false: bara NU se mai incarca
## (nici din mers, nici din drift). Pornesti plin si decizi unde arzi rezervorul
## (principiul 2); drift-ul ramane unealta de viraj. Arderea merge ca de obicei.
@export var turbo_recharge: bool = true
## Secunde de ardere continua de la bara plina.
@export var turbo_burn_time: float = 2.2
## Sub pragul asta nu poti porni turbo (previne "sputter"-ul din taste scurte).
@export var turbo_min_to_fire: float = 0.15
@export var turbo_speed_bonus: float = 11.0 # m/s peste plafon cat arde
## Impins suplimentar cat arde turbo — fara el, drag-ul ar anula boost-ul.
@export var turbo_accel_bonus: float = 10.0

@export_group("Diverse")
@export var gravity: float = 28.0
@export var body_color: Color = Color(0.95, 0.45, 0.1)
## MASA, nu un "factor": intra ca 1/m in impulsul de coliziune (_resolve_bump).
@export var mass_factor: float = 1.0
## Implicitul global al plafonului off-road; CarData.offroad_speed_factor il
## suprascrie per masina (buggy-ul), iar o valoare negativa acolo inseamna asta.
const OFFROAD_SPEED_DEFAULT: float = 0.45
@export var offroad_speed_factor: float = OFFROAD_SPEED_DEFAULT
## Centrul de masa pe verticala (m). Vezi CarData.center_of_mass_y — implicitul
## de aici (-0.15) e cel vechi, pastrat pentru orice masina fara CarData.
@export var center_of_mass_y: float = -0.15

@export_group("Imbranceli")
## Cat de "saltarea" e izbitura. 0 = perfect plastica (se lipesc), 1 = bile de
## biliard. Sub 1 = arcade: se simte lovitura, dar nu ricoseaza absurd.
## Pe fizica intreaga intra in PhysicsMaterial-ul corpului.
@export var bump_restitution: float = 0.35
## Plafon pe delta-v-ul incasat dintr-un contact cu alta masina (m/s).
## Solverul imparte impulsul dupa raportul maselor din constructie; peste
## plafon excedentul se taie PASTRAND directia — identitatea prin masa ramane,
## violenta scade. Inlocuieste bump_max_impulse de pe CharacterBody.
@export var bump_max_dv: float = 15.0
## Sub viteza asta de apropiere, contactul e frecare, nu izbitura: masinile care
## se ating mergand alaturi nu trebuie sa-si dea ghionturi.
@export var bump_min_closing: float = 2.5
## Cat nu mai emite ACEEASI pereche un al doilea semnal de bump. Doar pe
## semnal: impingerea fizica sustinuta o rezolva solverul, fara impulsuri
## repetate — catapultarile din vechiul cod nu mai au de unde sa apara.
@export var bump_pair_cooldown: float = 0.12
## Plafon pe rotatia primita dintr-o lovitura (rad/s). Necesar si pe fizica
## intreaga: directia scrie yaw-ul direct, deci rotatia data de solver ar fi
## STEARSA in cadrul urmator — o preluam in _impact_yaw (plafonat, se stinge
## singur) si o adunam peste comanda. Te sucesti, nu faci piruete.
@export var bump_yaw_max: float = 2.4
## Peste acest delta-v incasat, rotile pierd scurt aderenta laterala: lovitura
## se simte in directie, iar cel lovit isi prinde masina din alunecare.
@export var bump_slip_dv: float = 5.0
## Impulsul de separare (reteta SuperTuxKart): in contact SUSTINUT cu alta
## masina, o acceleratie laterala (m/s^2, inainte de scalarea cu masa) impinge
## corpurile unul de langa altul. Fara ea, doua masini pe aceeasi linie se
## lipesc si macina una in alta ("collision deadlock") -- rotatia pe yaw e
## scrisa direct de directie, deci solverul n-are cum sa le roteasca una de pe
## linia celeilalte. Vezi _process_contacts.
@export var bump_separation_accel: float = 6.0
## Pragul feed-ului `impact` (m/s de delta-v orizontal). Sub el contactul e
## frecare: o raspunde starea continua (wall_contact / rub_car), nu semnalul.
@export var impact_min_dv: float = 2.5

@export_group("Perete (razuire)")
## Logica razuire-vs-frontal (feel_checklist: glancing-vs-headon). Oprita =
## comportamentul vechi (un material pentru orice unghi, fara nudge) — sondele
## A/B o stang cu asta.
@export var glance_enabled: bool = true
## O lovitura de perete e „razuire" cand viteza dinainte de contact face cel
## mult atatea grade cu planul peretelui. Peste: frontal (se opreste cu bounce).
@export_range(5.0, 60.0, 1.0) var glance_angle_deg: float = 30.0
## Frecarea masinii cat tine o razuire (implicit 0.4, vezi _ready). Solverul
## combina frecarile corpurilor; fara asta botul infipt in perete ar manca
## viteza pe toata lungimea contactului.
@export_range(0.0, 0.4, 0.01) var glance_friction: float = 0.05
## Nudge-ul de directie spre paralel cu peretele: rad/s per radian de unghi
## intre bot si perete, plafonat de `glance_yaw_max` (si de bump_yaw_max).
## Intra prin _impact_yaw (apply_torque ar fi sters in tick-ul urmator).
@export var glance_yaw_gain: float = 8.0
@export var glance_yaw_max: float = 1.5
## Anti-lipire: cat sta botul in perete, la viteza mica, pana e impins.
@export var stuck_nudge_time: float = 0.4
## Impingerea laterala (m/s, dinspre perete) si rotatia (rad/s) a nudge-ului.
@export var stuck_nudge_speed: float = 2.5
@export var stuck_nudge_yaw: float = 2.4

@export_group("Spin-out assist")
## Masina scapata din mana (slip peste `spinout_slip_deg` fata de directia in
## care se misca, la peste `spinout_min_speed`) e rotita usor spre directia de
## mers — sau spre sosea, cand aproape s-a oprit dupa spin — ca jucatorul sa fie
## inapoi pe linie in ~1 s (feel_checklist: spinout-assist). Intra prin
## _impact_yaw. Marsarierul din voie (frana, viteza mica) si driftul (slip
## 20-35 grade) nu ajung la prag.
@export var spinout_enabled: bool = true
@export var spinout_slip_deg: float = 100.0
## Asistenta se opreste cand botul e la mai putin de atatea grade de tinta.
@export var spinout_release_deg: float = 45.0
@export var spinout_min_speed: float = 6.0
## rad/s per radian de eroare, plafonat la spinout_yaw_max (NU la bump_yaw_max:
## aici e o corectie de ~0,7 s, nu un efect de lovitura).
@export var spinout_yaw_gain: float = 3.0
@export var spinout_yaw_max: float = 3.5

@export_group("Control in aer")
## Doar pentru jucator (PlayerController): in aer gazul apleaca botul in jos si
## frana il ridica, ca sa poti nivela pentru aterizare. Plafonat si bland; fara
## control pe yaw, iar lansarea de pe rampe nu se schimba.
@export var air_control_enabled: bool = true
## Viteza unghiulara maxima de tangaj adaugata de comanda (rad/s).
@export var air_pitch_rate: float = 0.9
## Cat de repede ajunge la ea (rad/s^2).
@export var air_pitch_accel: float = 3.5

@export_group("Slipstream")
## O masina care urmeaza de aproape (`slip_min_gap`..`slip_max_gap` m in spatele
## alteia, in con ingust, amandoua peste `slip_min_speed_frac` din max_speed)
## primeste un plafon de viteza si o acceleratie mai mari, care cresc in
## `slip_build_s` si dispar in `slip_fade_s`. Aceeasi regula pentru oricine.
@export var slipstream_enabled: bool = true
@export var slip_min_gap: float = 2.0
@export var slip_max_gap: float = 14.0
## Latimea conului: jumatatea unei masini + atat pe metru de distanta.
@export var slip_cone: float = 0.15
@export var slip_min_speed_frac: float = 0.5
@export var slip_speed_bonus: float = 1.5 # m/s peste plafon la draft = 1
@export var slip_accel_bonus: float = 0.10 # +10% acceleratie la draft = 1
## Cat de departe in fata se uita (m) si ce schimbare de directie (rad) inseamna
## „drumul se curbeaza": peste ea, aspiratia se retrage.
@export var slip_lookahead_m: float = 45.0
@export var slip_curve_rad: float = 0.15
## Peste atata rotatie (rad/s) masina e in viraj si nu primeste aspiratie.
@export var slip_max_yaw: float = 0.5
@export var slip_build_s: float = 0.5
@export var slip_fade_s: float = 0.25

@export_group("Borduri")
## Bordura scutura suspensia ca treptele (vezi STEP_NOISE_M), proportional cu
## viteza. Oprit = fara scuturat (feel_checklist: surface-voice).
@export var kerb_rumble_enabled: bool = true

@export_group("Auto-upright")
## Rasturnata (pe acoperis sau pe o parte) si aproape oprita, masina se intoarce
## pe roti PE LOC, cu un salt mic, in loc sa astepte repunerea (feel_checklist:
## auto-upright). Oprit = comportamentul vechi (Race o repune dupa 1,5 s).
@export var upright_enabled: bool = true
## Cat sta rasturnata inainte sa se intoarca (s) — sa se opreasca din rostogolit.
@export var upright_delay: float = 0.3
## Viteza verticala a saltului (m/s). Gravitatia jocului e 28, deci ~0,3 s in aer.
@export var upright_hop: float = 2.8
## Cat de repede se roteste spre vertical: rad/s per radian de eroare
## (plafonat la UPRIGHT_MAX_RATE). Rotatia e pe axa botului, deci directia ramane.
@export var upright_turn_rate: float = 7.0
## Cat poate dura incercarea (s); daca nu e pe roti pana atunci, cade pe recover().
@export var upright_max_time: float = 0.9

@export_group("Suspensie")
## Cursa arcului in repaus (m). Raza de cast = rest + wheel_radius.
@export var suspension_rest: float = 0.35
## Frecventa naturala a arcului (Hz). 2-3 = masina de strada arcade;
## rigiditatea se deriva din ea si din masa pe roata, deci tuning-ul nu
## depinde de cat cantareste corpul. Devine per masina in CarData la #260.
@export var spring_freq: float = 2.5
## Raportul de amortizare (1 = critic). 0.5-0.7 = revii asezat.
@export var damping_ratio: float = 0.6

@export_group("Ejectare (sofer)")
## Se aplica doar masinilor cu `CarData.open_cockpit` si figurina atasata.
## Regula de design: ejectarea e VIZUALIZAREA repunerii, nu o pedeapsa noua —
## la capatul lui `eject_hold` masina se repune exact ca la orice ratare.
## Si NU se ejecteaza din imbranceli intre masini: bumping-ul e mecanica
## (principiul 1), nu accident.
@export var eject_enabled: bool = true
## Delta-v ORIZONTAL la un perete (m/s) peste care soferul zboara. 8 e pragul
## la care se aude izbitura. Masurat pe Dunele cu tot garajul deschis
## (ProbeRace, 150 s, seed 1): la 18 zburau 16 soferi in 150 s, adica o
## ejectare pe masina la ~50 s, si cel mai rapid pierdea o jumatate de tur —
## pragul prindea si atingerile oblice la viteza de cursa (20-25 m/s). La 26
## ramane doar izbitura FRONTALA (de la ~19 m/s in sus, cu ricoseul inclus)
## sau una oblica peste ~60° la viteza maxima.
@export var eject_wall_dv: float = 26.0
## Viteza de cadere (m/s) la aterizare peste care soferul zboara.
## Masurat cu ProbeRace pe Alpii (garaj deschis, 150 s): SARITURA PROIECTATA
## peste gol (frac 0.71) ateriza la 24-30 m/s, si la pragul de 24 fiecare
## masina isi pierdea soferul pe ea, tur de tur — 11 ejectari intr-o cursa.
## Saritura e distractia (principiul 1), nu accidentul. La 34 m/s (gravitatia
## jocului e 28, deci o cadere de la ~20 m) ramane doar prabusirea: de pe
## cornisa, in rapa, de pe un pasaj — nu de pe o rampa.
@export var eject_land_speed: float = 34.0
## Cat sta masina fara sofer (comenzi taiate, camera pe figurina) pana la
## repunere. Referinta Ignition: ~1,5-2 s de ecran fara masina.
@export var eject_hold: float = 1.1
## Cu cat e repusa in spate dupa ejectare (m).
@export var eject_backoff: float = 12.0

# --- Stare de cursa (scrisa de Race) ---
var race_active: bool = false
## Pe grila, inainte de GO: corpul e INGHETAT (freeze), deci gravitatia nu
## curge si nimeni nu aluneca la vale in countdown — bug-ul din aug 2026,
## rezolvat pe rigid body din constructie.
##
## Flag SEPARAT de `race_active` desi amandoua sunt false in countdown, fiindca
## `race_active = false` are al doilea inteles: "scoasa din cursa de un hazard"
## (trenul si avalansa il folosesc pentru stun). Acolo fizica TREBUIE sa curga —
## trenul isi arunca victima cu corpul lui solid cat tine stun-ul. Un inghet
## legat de `race_active` ar fi stins tacut explozia trenului.
var on_start_grid: bool = false:
	set(value):
		on_start_grid = value
		freeze = value

## Shim de compatibilitate: CharacterBody3D avea `velocity` si tot ce vorbeste
## cu masina (hazarde, sonde, AI, kickere) il foloseste. Pe rigid body e
## acelasi lucru cu linear_velocity — proprietatea pastreaza limbajul.
var velocity: Vector3:
	get:
		return linear_velocity
	set(value):
		linear_velocity = value
var finished: bool = false
var race_position: int = 1
var is_player: bool = false
var speed_scale: float = 1.0 # variatia onesta a AI (0.88..0.97), 1.0 la player

var car_name: String = "?"
var pilot_name: String = "?" # numele "pilotului", stabil intre curse
var data: CarData
var controller: CarController
var track: Track
var road_index: int = 0
## Pe ce banda e masina: 0 = bucla principala, 1+ = scurtatura. Indexul de mai
## sus se refera MEREU la ruta asta, nu la traseul principal — vezi [TrackRoute].
var route: int = 0
## Ultimul punct de pe traseu unde masina era cu roatele pe asfalt — de aici
## repornim daca ratam o aterizare sau ajungem in nisip.
##
## Se retine si RUTA, nu doar indexul. Fara ea, o repunere de pe scurtatura
## te-ar fi asezat la indexul cu acelasi numar de pe bucla principala, adica
## intr-un punct fara nicio legatura cu locul unde ai gresit.
var last_safe_index: int = 0
var last_safe_route: int = 0

# --- Drift/turbo ---
var is_drifting: bool = false
var drift_dir: float = 0.0
## Cat de „intrat" e driftul, 0..1: urca in drift_ramp_in cu frana de mana
## trasa, coboara in drift_ramp_out dupa. `is_drifting` spune daca e TRASA
## (turbo, stopuri, fum); fizica si ruliul citesc dozajul de aici.
var drift_blend: float = 0.0
## Rotatia COMANDATA, netezita: pe asfalt e chiar comanda, in drift o urmeaza
## cu `drift_yaw_inertia`. Stare separata de angular_velocity, ca loviturile
## (solver, _impact_yaw) sa nu se strecoare in netezire.
var _yaw_cmd: float = 0.0
## Cat a tinut driftul curent (s); raportat in `drift_ended`.
var _drift_time: float = 0.0
## Rotatia vizuala in plus a modelului (rad), netezita spre tinta.
var _drift_visual_yaw: float = 0.0
## Reasezarea de la iesirea din drift: un ruliu scurt in sens opus, pe
## `_visual`. `_snap_dir` e sensul driftului care tocmai s-a terminat.
const DRIFT_SNAP_TIME: float = 0.22
var _snap_left: float = 0.0
var _snap_dir: float = 0.0
## Stopurile aprinse: frana de serviciu (inapoi cu viteza inainte) sau
## handbrake-ul de drift. Citit de [CarLights]; scris o data pe tick.
var brake_lamp: bool = false
var turbo_charge: float = 0.0 # 0..1, bara din UI
var is_boosting: bool = false
var slip_time: float = 0.0 # aquaplanare (setata de WaterHazard sau de o banda uda)
## Ce aderenta laterala are masina cat timp aluneca.
##
## Era o constanta de 0.8 in mijlocul fizicii — corect pentru o balta de furtun
## pe care o traversezi in jumatate de secunda, catastrofal pentru o suprafata
## uda de 200 m. Prima incercare de banc de nisip a folosit chiar 0.8 si a taiat
## AI-ul de la 2.5 la 1.6 tururi, cu 27% din timp in apa. Acum intensitatea vine
## de la cel care cere alunecarea.
var slip_grip: float = SLIP_GRIP_PUDDLE
## Ceasul rafalelor de vant (vezi Track.wind_at) — acumulat din delta, nu din
## ceasul de perete, ca sondele cu --fixed-fps sa fie deterministe.
var _wind_time: float = 0.0
## Strivit: cat mai tine penalizarea, si cat de tare taie din viteza.
##
## Oglindeste slip_time in loc sa inventeze un al doilea mecanism. NU exista
## stare de "distrus" si nici nu vrem una: pedeapsa in jocul asta e mereu TIMP
## PIERDUT, ca la repunere. Bolovanul te turteste si te incetineste; trenul face
## acelasi lucru dus la extrem, plus repunere.
var crush_time: float = 0.0
## Cat mai tine albirea de la o rafala de abur. NU intra in nicio formula de
## fizica, deliberat: e singura penalizare din joc care se vede si nu se simte
## in volan (vezi FumaroleHazard).
var blind_time: float = 0.0
var crush_factor: float = 1.0
## Directia inversata (stanga <-> dreapta) cat mai tine, in secunde. Se pune DOAR
## prin `crush(..., invert_steer = true)` (bolovanul care cade din culoarul E de
## pe Track19); restul hazardelor cu crush n-o ating. Se aplica in Car, pe comanda
## de viraj, deci o simte si AI-ul (fara viteza trisata, fara vedere speciala).
var steer_invert_left: float = 0.0
## Cat strivit (`crush_time` > 0) turbo-ul nu porneste (vezi `_update_turbo`).
## Mereu true in joc; exista ca garda `ProbeCrushTurbo --sabotaj` sa poata scoate
## fix-ul la runtime si sa dovedeasca ca masoara ceva.
var crush_blocks_turbo: bool = true
## TURBO tinut de prea devreme la GO (#491): nu se aprinde pana nu ridici
## degetul. Vezi `hold_turbo_until_release`.
var _turbo_needs_release: bool = false
signal steer_inverted(seconds: float)
## Ars de o coloana de foc (gheizerele din craterul Stromboli, vezi
## `ignite`). Se tine SEPARAT de `crush_time` desi amandoua taie plafonul:
## strivirea e o forma turtita care se vede pe caroserie, arderea e un nor de
## flacari care se vede pe ECRAN. Un singur ceas pentru amandoua ar fi facut
## ca o repunere sa stinga focul, sau ca o piatra sa prelungeasca arderea.
var burn_time: float = 0.0
var _forced_boost: float = 0.0 # rocket start: ardere gratuita, nu goleste bara
## Turtirea care tine cat incetinirea (vezi `_hold_squash`). Tinut ca sa poata fi
## oprit: la repunere masina trebuie sa apara intreaga, nu latita.
var _squash_tween: Tween

## Nodul (din Race) sub care se depun urmele de cauciuc.
var skid_parent: Node3D

var _visual: Node3D
## Invartirea de caroserie data de tromba — vezi spin_body().
var _spin_rate: float = 0.0
var _spin_left: float = 0.0
var _spin_angle: float = 0.0

# --- Reactii VIZUALE de contact (docs/feel_checklist.md: body-jolt, scrape-sparks,
# side-rubbing, drift-snap, landing dust). Nimic de aici nu atinge fizica:
# citesc semnalele `impact` / `landed` si starea de contact a tick-ului.
## Cat de departe e impinsa caroseria VIZUALA (nu corpul fizic) la o izbitura
## maxima, in metri, in directia normalei.
@export var jolt_max_offset: float = 0.08
## Cat se inclina caroseria vizuala, in afara obstacolului, la izbitura maxima.
@export var jolt_max_tilt_deg: float = 5.5
## Delta-v (m/s) la care jolt-ul atinge maximul. Sub el creste cu radacina
## patrata, ca o lovitura mica sa se vada si ea.
@export var jolt_full_dv: float = 14.0
## Frecventa proprie (rad/s) si amortizarea (1 = critic) arcului de revenire.
## 24 rad/s cu 0.4 inseamna ~4 Hz si o stingere sub 5% in 0.35 s.
@export var jolt_freq: float = 24.0
@export var jolt_damping: float = 0.4
## Inclinarea (grade) a caroseriei in afara masinii de care te freci.
@export var rub_lean_deg: float = 3.0
## Sub viteza asta (m/s) de razuire pe perete nu mai sar scantei continue.
@export var scrape_min_speed: float = 4.0
## Sub viteza asta (m/s) de frecare intre masini nu mai sar scantei continue.
@export var rub_min_speed: float = 2.0
## Izbitura de perete (delta-v) de la care apare si rafala de scantei.
@export var wall_spark_burst_dv: float = 6.0
## Viteza de cadere (m/s) de la care aterizarea ridica praf.
@export var land_dust_min_fall: float = 5.0
## Tufe (soft-hazards): cand rotile trec printr-o tufa din `SoftVegetation`
## (chunk-uri de vegetatie fara coliziune) cu cel putin atata viteza (m/s),
## sare o rafala de frunze.
@export var bush_burst_min_speed: float = 6.0
## Franare usoara in tufa, in m/s^2 la centrul ei (scade spre margine). 6 = o
## tufa trecuta cu 25 m/s costa ~0.5 m/s; 0 o opreste. Se aplica tuturor
## masinilor la fel (si AI-ului), deci nu favorizeaza pe nimeni — dar muta
## timpii pe turele cu multa vegetatie langa drum.
@export var bush_drag: float = 6.0
## Radacina de unde se citesc tufele; null = pista. Pentru sonde.
var soft_veg_root: Node3D = null
var _veg_cooldown: float = 0.0
var _veg_depth: float = 0.0
## Jucaria (toy-animation): antena cu arc si cheia de intors. Noduri copil ale
## lui `_visual` (se refac cu el la apply_data); null daca masina n-are model,
## are `toy_animation` stins sau modelul n-a avut unde sa le monteze.
var _toy_antenna: Node3D = null
var _toy_key: Node3D = null
## Antena: aplecarea varfului (vector orizontal in spatiul masinii, lungime =
## unghi in rad) si viteza ei — un arc subamortizat, nu un mers invers.
var _ant_tilt: Vector3 = Vector3.ZERO
var _ant_vel: Vector3 = Vector3.ZERO
var _key_angle: float = 0.0
## Cat de tare se apleaca antena pe m/s^2 de acceleratie, plafonul (rad) si
## arcul ei (rad/s, amortizare: jos = legana mai mult).
const ANT_PER_ACCEL: float = 0.018
const ANT_MAX: float = 0.40
const ANT_FREQ: float = 17.0
const ANT_DAMPING: float = 0.16
## Cheia: rad/s in repaus (aproape stop) si la viteza maxima.
const KEY_SPIN_MIN: float = 0.0
const KEY_SPIN_MAX: float = 18.0
## Zdranganeala (toy-animation: piese de plastic care zornaie). Pe teren aspru
## antena si cheia tremura mic si repede, DOAR vizual (nu intra in starea
## arcului antenei). Sursele: bordura, trepte de piatra, teren afanat (iarba,
## pietris, pamant) si aterizarile; totul scalat cu viteza.
@export_group("Zdranganeala jucariei")
## Comutator (sabotaj pentru sonda: stins, jucaria sta calma pe teren aspru).
@export var toy_rattle_enabled: bool = true
## Unghiul maxim (rad) al tremurului: varful antenei si cheia pe axa ei.
@export var rattle_ant_rad: float = 0.09
@export var rattle_key_rad: float = 0.14
## Cat de tare zdrangane fiecare sursa, la viteza plina (0..1).
@export var rattle_kerb: float = 1.0
@export var rattle_steps: float = 0.9
@export var rattle_loose: float = 0.45
## Sub viteza asta (m/s) nu zdrangane pe teren; la `rattle_full_speed` e la maxim.
@export var rattle_min_speed: float = 2.0
@export var rattle_full_speed: float = 18.0
## Aterizare: cadere (m/s) la care rafala e maxima, si cat dureaza (s) pana moare.
@export var rattle_land_full_fall: float = 12.0
@export var rattle_land_decay_s: float = 0.35
## Netezirea nivelului: urca repede (1/s), coboara mai incet.
@export var rattle_attack: float = 22.0
@export var rattle_release: float = 7.0
@export_group("")
## Nivelul curent de zdranganeala (0..1), pentru sonde si debug.
var toy_rattle: float = 0.0
var _rattle_drive_smooth: float = 0.0
var _rattle_burst: float = 0.0
var _rattle_t: float = 0.0
var _toy_loose: bool = false
## Starea elastica a jolt-ului: deplasare si tilt (vector orizontal in spatiul
## masinii; directia = spre ce se apleaca varful, lungimea = unghiul in rad).
var _jolt_pos: Vector3 = Vector3.ZERO
var _jolt_pos_vel: Vector3 = Vector3.ZERO
var _jolt_tilt: Vector3 = Vector3.ZERO
var _jolt_tilt_vel: Vector3 = Vector3.ZERO
## Aplecarea de la frecare laterala cu alta masina, netezita.
var _rub_lean: Vector3 = Vector3.ZERO
## Strop-ul de ruliu din drift (fostul `_visual.rotation.z`, tinut separat ca
## sa se poata compune cu jolt-ul in loc sa fie scris peste).
var _drift_roll: float = 0.0
## Unghiul de derapaj (grade, 0..90) intre directia de mers si botul masinii,
## fata de SOL, si „cat de tare aluneca" (0..1, netezit) din el si din viteza.
var slip_angle_deg: float = 0.0
var slide_amount: float = 0.0
## Scanteile CONTINUE (razuire pe perete sau frecare intre masini): un singur
## emitator, 8 particule, rata data de ramp-ul de culoare initiala.
var _scrape_sparks: CPUParticles3D
var _scrape_density: Gradient
var _drift_density: Gradient
## Praful de aterizare (rafala o data pe cadere).
var _land_dust: CPUParticles3D
var _drift_particles: CPUParticles3D
var _boost_particles: CPUParticles3D
## Flacarile de pe capota cat masina arde. Emit din FATA masinii, catre
## spate: la camera din spate, fumul trece PESTE parbriz si mananca partea de
## sus a ecranului — asta e pedeapsa, nu cifra taiata din plafon.
var _fire_particles: CPUParticles3D
## Praf de sub roti cand esti pe nisip. Separat de fumul de drift: fumul iese
## din cauciuc si e gri, praful e ridicat din SOL si ia culoarea temei.
var _dust_particles: CPUParticles3D
## APA (v12). Rotile sunt sub luciul unei ape (vad, parau, mare, lac):
## tranzitia fals -> adevarat e „am intrat in apa" (strop, inel, semnal, sunet).
var in_water: bool = false
## Spray continuu de la rotile din FATA cat timp treci prin apa cu viteza.
var _water_spray: CPUParticles3D
## Scantei la ciocnirea cu alta masina (#500): un emitator one-shot per masina,
## mutat la punctul de contact si repornit la fiecare izbitura.
var _sparks: CPUParticles3D
## Stropul de la intrare: o rafala (one_shot) repornita la fiecare intrare.
var _water_burst: CPUParticles3D
## Materialul inelului de unde — al masinii, nu static: culoarea e a apei din
## tema curenta, iar un static ar duce namolul Serengeti pe laguna Okinawei.
var _ring_material: StandardMaterial3D
var _water_color_ready: bool = false
## Siajul: panza plata la nivelul luciului, sub si in spatele masinii, cu
## spuma care curge spre spate (assets/shaders/water_wake.gdshader).
var _water_wake: MeshInstance3D
var _water_rumble: float = 0.0
static var _wake_mesh: ArrayMesh = null
static var _wake_material: ShaderMaterial = null
## Inelul: acelasi mesh pentru toate masinile si toate intrarile.
static var _ring_mesh: ArrayMesh = null
## Pietricelele si bulgarii aruncati de roata pe sol afanat.
##
## Al doilea strat al efectului, si singurul care are MUCHII: in referinta
## (Beach Buggy Racing 2, secventele pe pamant) se vad puncte deslusite care
## sar in urma rotilor, peste ceata joasa. Norul singur da atmosfera, dar nu
## spune ca solul e granular — bucatile fac asta. De aceea aici e corect ce era
## gresit la praf: geometrie mica, opaca, cu gravitatie reala.
var _debris_particles: CPUParticles3D
## Vocile continue (motor, derapaj, suprafete, turbo, vant): vezi car_audio.gd.
const CarAudio := preload("res://scenes/cars/car_audio.gd")
var _audio: Node
## Gazul comandat in ultimul tick (-1..1), dupa taierile din aruncare/repunere.
## Il citeste CarAudio (motorul, rateurile); fizica foloseste variabila locala.
var throttle_input: float = 0.0
var _turbo_full_latch: bool = false

# Rotile modelului (noduri separate in FBX-urile RgsDev).
var _wheels_all: Array[Node3D] = []
var _wheels_front: Array[Node3D] = []
## Transformarea originala a fiecarei roti (FBX-urile au scala "coapta" in
## nod — daca o suprascriem cu o rotatie pura, rotile devin microscopice).
var _wheel_orig: Array[Basis] = []
var _wheel_radius: float = 0.35
var _wheel_spin: float = 0.0
var _wheel_steer: float = 0.0

# Umbra blob: ieftina, mereu pe sol — arata locul aterizarii la sarituri.
var _shadow: MeshInstance3D
var _shadow_mat: StandardMaterial3D
var _was_on_floor: bool = true
var _prev_velocity: Vector3 = Vector3.ZERO
## Viteza SOLULUI de sub roti (media pe rotile cu contact). Zero pe asfalt;
## pe o platforma mobila (telecabina din Chongqing, CablewayHazard) e viteza
## platformei, citita din meta `platform_velocity` de pe corpul lovit de
## raycast. Toate fortele de cauciuc (drag, grip lateral, amortizor, plafon)
## se socotesc fata de EA, nu fata de lume: o roata pe o podea care merge cu
## 25 m/s nu „aluneca" cu 25 m/s — sta pe loc fata de podea. Fara asta,
## guvernatorul de viteza (fwd_speed > vmax) tragea masina inapoi cu 12 m/s^2
## si o dadea jos din cabina pe usa din spate (masurat in ProbeCableway).
var _ground_velocity: Vector3 = Vector3.ZERO
var _wall_cooldown: float = 0.0
var _impact_wall_cooldown: float = 0.0
var _last_static: Node = null
## Frecarea implicita a masinii (PhysicsMaterial din _ready).
const CAR_FRICTION: float = 0.4
var _pmat: PhysicsMaterial
## Razuire in curs (vezi _wall_glance); ramane aprinsa 0.15 s dupa ultimul
## contact, ca un contact care palpaie sa nu reporneasca episodul.
var _glance_episode: bool = false
var _glance_gap: float = 0.0
## Cat timp sta botul infipt in perete la viteza mica (anti-lipire).
var _stuck_t: float = 0.0
var _stuck_cool: float = 0.0
var _stuck_push_left: float = 0.0

# --- Starea de contact a tick-ului (feed comun, vezi semnalul `impact`) ---
## In contact cu un perete/obstacol static ACUM (normala aproape orizontala;
## solul de sub caroserie nu conteaza).
var wall_contact: bool = false
## Normala orizontala medie a peretelui, dinspre perete spre masina.
var wall_normal: Vector3 = Vector3.ZERO
## Punctul mediu de contact cu peretele (global).
var wall_point: Vector3 = Vector3.ZERO
## Viteza de-a lungul peretelui cat il atingi (m/s) — viteza de razuire.
var wall_scrape_speed: float = 0.0
## Peretele atins e un corp MOBIL (AnimatableBody3D: autobuz, bariera, tren,
## avalansa...). Logica de razuire il ocoleste: strivirea si purtarea raman
## exact ca inainte.
var wall_moving: bool = false
## Masina de care te freci ACUM (null daca niciuna).
var rub_car: Car = null
## Punctul mediu de contact cu `rub_car`.
var rub_point: Vector3 = Vector3.ZERO
## Normala orizontala dinspre `rub_car` spre noi.
var rub_normal: Vector3 = Vector3.ZERO
## Viteza relativa TANGENTIALA fata de `rub_car` (m/s) — cat de tare va frecati.
var rub_speed: float = 0.0
## instance_id-ul celeilalte masini -> secunde pana la urmatorul semnal admis.
var _bump_pairs: Dictionary = {}
## Rotatia (rad/s) primita dintr-o lovitura excentrica; se stinge singura si
## se ADUNA peste comanda de directie (care altfel ar sterge-o).
var _impact_yaw: float = 0.0
## Rotatia de SABOTAJ (rad/s) — vartejul de praf din Serengeti (brief §3,
## clasa „sabotaj de control" din ref_notes/sisteme.md). Spre deosebire de
## _impact_yaw, nu e plafonata de bump_yaw_max si nu se stinge exponential:
## tine exact `_yaw_kick_left` secunde, ca sa livreze un unghi precis
## (180° in 0,8 s), apoi dispare. Directia jucatorului ramane activa peste ea
## — sabotajul iti ia orientarea, nu comenzile.
var _yaw_kick: float = 0.0
var _yaw_kick_left: float = 0.0

# --- Suspensia pe raycast (fizica intreaga) ---
## Compresia curenta a fiecarui arc [0, suspension_rest], ordinea FL FR RL RR.
var wheel_compression: Array[float] = [0.0, 0.0, 0.0, 0.0]
## Cate roti au atins solul in tick-ul curent (0-4).
var wheels_on_ground: int = 0
## TREPTELE ca suprafata (Machu Picchu, brief §3 „Treptele Drumului Incas").
##
## Coliziunea de sub roti e panta lina; treapta e doar un termen periodic in
## lungimea raycast-ului: ±STEP_NOISE_M pe un pas de STEP_PITCH_M in lungul
## drumului. Arcul „vede" o denivelare care nu exista in geometrie, deci
## caroseria vibreaza, dar nimic nu se opune inaintarii — media termenului e
## zero, iar forta lui e verticala. Masurat in tools/probe_machu_teren.gd:
## viteza la iesirea din panta identica (< 3%) cu si fara trepte.
##
## Sursa: intervalul de fractie declarat pe pista (`Track.is_steps_at`) SAU
## meta `inca_steps` pe colizorul lovit (geometrie de test, corpuri separate).
const STEP_NOISE_M: float = 0.03
const STEP_PITCH_M: float = 1.2
## Cel putin o roata pe trepte in tick-ul curent (pentru HUD/audio prin
## polling; semnalul `steps_changed` e pentru tranzitii).
var on_steps: bool = false
var _steps_here: bool = false
## Factor extern pe plafonul de viteza (crush-ul are al lui; asta e pentru
## sonde si hazarde care vor sa taie viteza fara sa stie de crush).
var speed_limit_factor: float = 1.0
## Raza rotii fizice (cast = rest + raza); se deriva din model in apply_data.
var _susp_wheel_radius: float = 0.30
## Plafonul razei fizice: roata monster truck-ului (0.62) plus marja.
const SUSP_WHEEL_RADIUS_MAX := 0.65
## Colturile rotilor in spatiul masinii; din dimensiunile CarData.
var _wheel_points: Array[Vector3] = []
## Media punctelor de contact cu solul (offset fata de origine): AICI se
## aplica fortele de cauciuc — la sol, nu in centrul de masa. De aici ruliul
## in viraj, squat-ul la accelerare, dive-ul la frana.
var _contact_offset: Vector3 = Vector3.ZERO
## Cotele rotilor din tick-ul curent, pentru detectorul de lava (vezi finalul
## lui _apply_suspension): cea mai INALTA roata pe lava vs cea mai JOASA pe
## drum — diferenta spune daca doar atingi evazarea sau chiar te-ai catarat.
var _lava_wheel_y: float = -INF
var _road_wheel_y: float = INF
## Acelasi lucru per axa (0 = fata, 1 = spate): driftul taie doar spatele.
var _axle_offset: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _axle_grounded: Array[int] = [0, 0]
## Normala medie a solului de sub roti (shim pentru get_floor_normal).
var _ground_normal: Vector3 = Vector3.UP
## Yaw-ul scris de NOI la finalul tick-ului trecut; diferenta la intrarea in
## tick = rotatia data de solver (lovitura excentrica).
var _commanded_yaw: float = 0.0
## Compresia statica (de repaus) a arcului — reperul fata de care rotile
## vizuale se ridica/coboara. Setata de _rebuild_suspension_geometry.
var _susp_static_comp: float = 0.11
## Pozitia originala a fiecarui nod de roata din model si coltul de suspensie
## de care apartine (0-3, FL FR RL RR in spatiul masinii).
var _wheel_orig_pos: Array[Vector3] = []
var _wheel_corner: Array[int] = []
var _skid_accum: float = 0.0
var _respawn_cooldown: float = 0.0
## Ceasul recautarii globale de index (vezi Track.reacquire_index): o scanare
## completa la cel mult REACQUIRE_PERIOD_S, doar cat masina pare in afara
## drumului. Scanarea e O(n) pe ~1000 de puncte — nu pe fiecare tick, x6 masini.
const REACQUIRE_PERIOD_S: float = 0.25
var _reacquire_left: float = 0.0

# Resurse partajate intre toate urmele de cauciuc (ieftin la instantiere).
static var _skid_mesh: PlaneMesh
static var _skid_mat: StandardMaterial3D

var _collision_shape: CollisionShape3D
## Soferul asezat (doar masinile deschise) si starea aruncarii lui.
var _driver: Driver
var is_ejected: bool = false
var _eject_left: float = 0.0
## Repunerea cu tranzitie (#495): cat mai clipeste pana la teleport, si cu ce
## retragere se va face repunerea.
const RECOVER_S: float = 1.0
## „Rasturnata" = acelasi criteriu ca `Race._watch_recovery` (FLIPPED_COS /
## FLIPPED_SPEED / FLIPPED_S): cos fata de vertical sub 0.3 si sub 4 m/s.
## Bordura: ±KERB_NOISE_M in compresia arcului pe un pas de KERB_PITCH_M. La
## 25 m/s e ~18 Hz — o vibratie, nu un hop. Amplitudinea creste cu viteza.
const KERB_NOISE_M: float = 0.035
const KERB_PITCH_M: float = 1.4
## Citibile de audio/camera: macar o roata pe bordura acum / cate roti.
var on_kerb: bool = false
var kerb_wheels: int = 0
## Cat de „in aspiratie" e masina, 0..1 (vezi _update_draft). Citibil de efecte.
var draft: float = 0.0
var _spinout_on: bool = false
var _spinout_left: float = 0.0
const UPRIGHT_FLIPPED_COS: float = 0.3
const UPRIGHT_FLIPPED_SPEED: float = 4.0
## Daca tot nu s-a putut intoarce dupa atat (s de stat rasturnata), recover().
## Egal cu FLIPPED_S din Race: cele doua plase se intalnesc in acelasi moment.
const UPRIGHT_GIVE_UP_S: float = 1.5
const UPRIGHT_MAX_RATE: float = 10.0
## Peste atata in afara soselei (m), locul nu e bun de intors pe loc.
const UPRIGHT_OFFROAD_M: float = 14.0
## Sub cota soselei cu atat (m) = cazut in groapa/rapa, nu intoarcem pe loc.
const UPRIGHT_BELOW_ROAD_M: float = 3.0
var _roof_t: float = 0.0
var _upright_left: float = 0.0
## De cate ori pe secunda clipeste caroseria in tranzitie.
const RECOVER_BLINK_HZ: float = 7.0
var _recover_left: float = 0.0
var _recover_backoff: float = 14.0
## Ultima ejectare, pentru sonde: ce a declansat-o ("perete" / "aterizare")
## si cu ce marime (delta-v orizontal, respectiv viteza de cadere, m/s).
var last_eject_cause: String = ""
var last_eject_value: float = 0.0

func _ready() -> void:
	# Grupul e pentru cine trebuie sa stie TOATE masinile fara sa treaca prin
	# Race (ragdoll-ul isi exclude coliziunea cu ele).
	add_to_group(&"cars")
	mass = 100.0 * mass_factor
	# Gravitatia proiectului e cea implicita (9.8); jocul cade cu `gravity`.
	var project_g: float = ProjectSettings.get_setting(
		"physics/3d/default_gravity", 9.8)
	gravity_scale = gravity / project_g
	# Centrul de masa sub origine: parghia care tine masina pe roti in viraj.
	# Inaltimea e IDENTITATE (CarData.center_of_mass_y) — vezi apply_data.
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, center_of_mass_y, 0.0)
	# Nu doarme niciodata: un corp adormit pe grila n-ar mai primi fortele
	# suspensiei si s-ar aseza pe colizer cand il trezeste contactul.
	can_sleep = false
	# Amortizarile globale raman mici: franarea reala vine din drag si grip.
	linear_damp = 0.0
	angular_damp = 0.5
	# Imbranceli: contactele se raporteaza (semnal + plafon), restitutia
	# arcade vine din material.
	contact_monitor = true
	max_contacts_reported = 8
	# Decorul bump-abil (#489) sta pe stratul lui: masina il loveste, dar
	# razele suspensiei (masca implicita) nu-l vad — roata nu urca pe un taburet.
	collision_mask |= BumpProp.LAYER
	var pmat := PhysicsMaterial.new()
	pmat.bounce = bump_restitution
	pmat.friction = CAR_FRICTION
	physics_material_override = pmat
	_pmat = pmat
	_build_visual()
	_build_effects()
	# Reactiile vizuale citesc feed-ul de contact; nu adauga nimic in fizica.
	impact.connect(_on_impact_visual)
	landed.connect(_on_landed_visual)
	respawned.connect(_reset_visual_offsets)
	landed.connect(_on_landed_rattle)
	# Colizerul caroseriei NU atinge solul in mers (garda la sol o da
	# suspensia); exista pentru imbranceli si aterizari dure. Talpa lui sta la
	# +0.25 fata de origine (care e la nivelul solului): bordurile si dalele
	# sub inaltimea aia sunt treaba ROTILOR (raycasturile trec peste ele), nu
	# a caroseriei. Cu talpa la +0.1, ca pe CharacterBody, o dala de 16 cm era
	# un zid frontal — masurat cu testul de denivelari: masina se oprea in
	# prima dala in loc sa o calce. move_and_slide pasea peste; solverul nu.
	_collision_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.0, 3.8)
	_collision_shape.shape = box
	_collision_shape.position = Vector3(0, 0.75, 0)
	add_child(_collision_shape)
	_rebuild_suspension_geometry(0.85, 1.45)


## Punctele de prindere ale arcurilor, din dimensiunile vehiculului.
##
## Inaltimea lor e aleasa EXACT astfel incat, la echilibru static, originea
## masinii sa cada la nivelul solului — acelasi contract ca pe CharacterBody.
## Toata aritmetica de efecte construita pe el (talpa colizerului la +0.1,
## urmele, umbra, pozitiile particulelor) ramane valabila fara nicio ajustare.
## Compresia statica nu depinde de masa: comp = g / omega^2.
func _rebuild_suspension_geometry(wheel_x: float, wheel_z: float) -> void:
	var omega := TAU * spring_freq
	_susp_static_comp = gravity / (omega * omega)
	var attach_h := suspension_rest + _susp_wheel_radius - _susp_static_comp
	_wheel_points = [
		Vector3(-wheel_x, attach_h, -wheel_z),
		Vector3(wheel_x, attach_h, -wheel_z),
		Vector3(-wheel_x, attach_h, wheel_z),
		Vector3(wheel_x, attach_h, wheel_z),
	]

func set_controller(new_controller: CarController) -> void:
	controller = new_controller
	add_child(new_controller)
	new_controller.setup(self)

## „Fara culoare de inlocuire" pentru `apply_data`: alfa 0 = ramane
## `CarData.color`. Cine vrea doar al treilea argument (soferul) paseaza asta.
const NO_COLOR := Color(0, 0, 0, 0)

## `driver_override`: figurina aleasa in garaj, separat de masina
## (`GameState.selected_driver_model()`); doar jucatorul o primeste. Null =
## perechea din .tres, care e implicitul pentru AI.
func apply_data(new_data: CarData, color_override: Color = NO_COLOR,
		driver_override: PackedScene = null) -> void:
	data = new_data
	car_name = data.display_name
	max_speed = data.max_speed
	acceleration = data.acceleration
	grip = data.grip
	mass_factor = data.mass_factor
	mass = 100.0 * mass_factor # identitatea prin masa, direct in solver
	# Off-road per masina (buggy-ul); -1 in CarData = implicitul global. Se
	# scrie MEREU, nu doar cand e pozitiv: `_swap_player_car` aplica alta
	# CarData pe acelasi corp, si valoarea buggy-ului ar ramane pe taxi.
	offroad_speed_factor = data.offroad_speed_factor \
		if data.offroad_speed_factor >= 0.0 else OFFROAD_SPEED_DEFAULT
	center_of_mass_y = data.center_of_mass_y
	center_of_mass = Vector3(0.0, center_of_mass_y, 0.0)
	body_color = data.color if color_override.a == 0.0 else color_override
	if _visual != null:
		_visual.queue_free()
	_build_visual()
	# GLB din pipeline-ul nostru: materialul de clasa (atlas + AO din vertex
	# colors), ca orice alt asset al lumii. FBX-urile RgsDev raman cu ale lor.
	if data.palette_model and _visual.get_child_count() > 0:
		Palette.apply_world_material(_visual.get_child(0))
	# Stopuri si faruri, din nodurile `*_Lamp_*` ale modelului (dupa materialul
	# de clasa, care le-ar fi acoperit lentilele).
	if data.model != null and _visual.get_child_count() > 0:
		var lights := CarLights.new()
		lights.name = "Lights"
		_visual.add_child(lights)
		lights.setup(self, _visual.get_child(0) as Node3D)
	# Soferul, doar pe caroserii deschise (vezi CarData.open_cockpit). Skinul
	# vine din garaj pentru jucator si din .tres pentru AI; scaunul e acelasi,
	# fiindca toate skinurile stau pe acelasi corp (DriverData).
	_driver = null
	is_ejected = false
	_eject_left = 0.0
	var driver_scene := driver_override if driver_override != null \
		else data.driver_model
	if data.open_cockpit and driver_scene != null:
		_driver = Driver.new()
		_driver.name = "Driver"
		_visual.add_child(_driver)
		_driver.position = data.driver_seat
		_driver.setup(driver_scene, self)
	# Colizerul, suspensia si efectele urmeaza dimensiunile vehiculului.
	if _collision_shape != null:
		var box := _collision_shape.shape as BoxShape3D
		box.size = Vector3(data.body_width * 0.9, 1.0, data.body_length * 0.85)
	# Suspensia e IDENTITATE (#260): rigiditatea, amortizarea si cursa vin din
	# CarData — sportiva teapana, autobuzul moale si leganat. Raza fizica a
	# rotii vine din model (via _build_visual); ecartamentul si ampatamentul
	# din corpul masinii — autobuzul calca mai lat si mai lung.
	spring_freq = data.spring_freq
	damping_ratio = data.damping_ratio
	suspension_rest = data.suspension_rest
	# Plafonul era 0.42; monster truck-ul (garaj v2) are roata de 0.62 si cu
	# plafonul vechi raza ar fi iesit cu 20 cm sub roata desenata — cast-ul
	# (rest + raza) ar fi atins solul cu janta, nu cu anvelopa. Decizia
	# dezvoltatorului, 25 oct 2026 (garaj_prompturi_chatgpt.md §4, varianta a).
	_susp_wheel_radius = clampf(_wheel_radius, 0.22, SUSP_WHEEL_RADIUS_MAX)
	_rebuild_suspension_geometry(
		data.body_width * 0.42, data.body_length * 0.38)
	if _drift_particles != null:
		_drift_particles.position.z = data.body_length * 0.5
	if _water_spray != null:
		_water_spray.position.z = -data.body_length * 0.42
		_water_spray.emission_box_extents.x = data.body_width * 0.6
		_boost_particles.position.z = data.body_length * 0.5 + 0.1
	if _shadow != null:
		_shadow.scale = Vector3(data.body_width * 0.62, 1.0, data.body_length * 0.5)

func _physics_process(delta: float) -> void:
	if track != null:
		# Intai PE CE banda suntem, abia apoi unde pe ea. Ordinea conteaza:
		# cautarea de index e locala (fereastra de ~72 m), deci pe ruta gresita
		# ar ramane agatata in urma si fractia de tur ar ingheta.
		var resolved := track.resolve_route(route, road_index, global_position)
		if resolved.x != route:
			route = resolved.x
			road_index = resolved.y
		else:
			road_index = track.closest_index(road_index, global_position, route)
		# Fereastra locala poate ramane agatata in urma dupa o taietura prin
		# iarba (#496): pe asfalt, `is_on_road` ar raspunde „iarba" si plafonul
		# ar ramane la 45%. Cat parem in afara drumului, verificam rar, global.
		_reacquire_left -= delta
		if _reacquire_left <= 0.0 \
				and not track.is_on_road(road_index, global_position, route):
			_reacquire_left = REACQUIRE_PERIOD_S
			road_index = track.reacquire_index(road_index, global_position, route)
		# Banda uda: se reinnoieste in fiecare cadru, deci efectul tine exact cat
		# stai pe ea. Refoloseste acelasi slip_time ca WaterHazard — un al doilea
		# mecanism de aquaplanare ar fi insemnat doua feluri de a pierde grip-ul,
		# care s-ar fi tunat separat si ar fi divergat.
		# Doua surse de ud, acelasi efect: banda (scurtatura declarata uda) si
		# INTERVALUL de pe traseul principal (#246). A doua e cea care lipsea —
		# se putea uda un ocol intreg, dar nu 80 m din linia pe care oricum mergi.
		#
		# Grip-ul vine de la pista cand tema il declara: „ud" inseamna altceva pe
		# un drum de munte decat pe un dig batut de valuri. Fara declaratie,
		# ramane implicitul masinii, deci nimic nu se schimba pe pistele actuale.
		var wet_route := track.route_is_wet(route)
		var frac_here := track.frac_at(road_index)
		var wet_here := route == 0 and track.is_wet_at(frac_here)
		# GHEATA (Baikal): acelasi mecanism, alt grip — mult sub ud. Se
		# verifica INAINTEA udului: pe un interval care e si ud si gheata,
		# gheata castiga (e suprafata, udul e o stare).
		var ice_here := route == 0 and track.is_ice_at(frac_here)
		# AFANAT (cenusa, nisip negru adanc): al treilea nivel, cel mai bland.
		# Se verifica ULTIMUL — pe o portiune si udă si cu cenusa, udul
		# castiga, la fel cum gheata castiga in fata udului.
		var loose_here := route == 0 and track.is_loose_at(frac_here)
		# TREPTE: nu schimba grip-ul, se citeste in _apply_suspension.
		_steps_here = route == 0 and track.is_steps_at(frac_here)
		if ice_here:
			var gi := track.ice_grip()
			apply_slip(gi if gi > 0.0 else SLIP_GRIP_ICE)
		elif wet_route or wet_here:
			var g := track.wet_grip()
			apply_slip(g if g > 0.0 else SLIP_GRIP_WET)
		elif loose_here:
			var gl := track.loose_grip()
			if gl > 0.0:
				apply_slip(gl)
		# VANTUL temei (doar pe gheata, vezi Track.wind_at): forta centrala,
		# proportionala cu masa — toate masinile deriveaza la fel, dar cea
		# grea o simte in acelasi mod ca pe cea usoara (e o acceleratie). Doar
		# cu rotile pe sol: in aer vantul ar fi inca un mecanism de zbor.
		_wind_time += delta
		if wheels_on_ground > 0:
			var wind := track.wind_at(frac_here, _wind_time)
			if wind != Vector3.ZERO:
				apply_central_force(wind * mass)

	# Pe grila de start corpul e INGHETAT (freeze, prin on_start_grid), deci
	# gravitatia nu curge si nimeni nu aluneca la vale in countdown — bug-ul
	# masurat in aug 2026 (3.9-5.0 m pe Dunele), rezolvat aici din constructie.
	# Efectele vizuale de mai jos ruleaza oricum: masina nu pare obiect mort.

	# Bilantul solverului INTAI, cat _prev_velocity e inca "ieri": ce s-a
	# schimbat intre tick-uri e opera coliziunilor, nu a fortelor noastre.
	_process_contacts(delta)

	var steer := 0.0
	var throttle := 0.0
	var drift_pressed := false
	var turbo_pressed := false
	if controller != null and race_active and not finished:
		controller.update(delta)
		steer = clampf(controller.get_steer(), -1.0, 1.0)
		if steer_invert_left > 0.0:
			steer = -steer
		throttle = clampf(controller.get_throttle(), -1.0, 1.0)
		drift_pressed = controller.is_drift_pressed()
		turbo_pressed = controller.is_turbo_pressed()
	# Fara sofer nu conduce nimeni: comenzile se taie cat tine aruncarea, iar
	# la capat vine repunerea. Fizica curge (masina isi continua izbitura).
	if _eject_left > 0.0:
		steer = 0.0
		throttle = 0.0
		drift_pressed = false
		turbo_pressed = false
		_tick_eject(delta)
	# La fel in tranzitia de repunere: nu mai conduci o masina care urmeaza sa
	# dispara de aici.
	if _recover_left > 0.0:
		steer = 0.0
		throttle = 0.0
		drift_pressed = false
		turbo_pressed = false
		_tick_recover(delta)

	throttle_input = throttle
	_tick_upright(delta)
	_apply_suspension()

	var forward := -global_transform.basis.z
	var fwd_h := Vector3(forward.x, 0.0, forward.z).normalized()
	# Viteza fata de SOL (vezi _ground_velocity): pe asfalt e identica cu cea
	# fata de lume, deci nimic nu se schimba pe pistele fara platforme.
	var rel_vel := velocity - _ground_velocity
	var fwd_speed := Vector3(rel_vel.x, 0.0, rel_vel.z).dot(fwd_h)

	_update_drift(drift_pressed, steer, fwd_speed, delta)
	_update_turbo(turbo_pressed, delta)
	_update_draft(delta)
	brake_lamp = (throttle < 0.0 and fwd_speed > 1.0) or is_drifting

	_apply_driving(steer, throttle, fwd_h, fwd_speed, delta)

	slip_time = maxf(slip_time - delta, 0.0)
	crush_time = maxf(crush_time - delta, 0.0)
	steer_invert_left = maxf(steer_invert_left - delta, 0.0)
	_update_invert_marker()
	blind_time = maxf(blind_time - delta, 0.0)
	if crush_time <= 0.0:
		crush_factor = 1.0
	burn_time = maxf(burn_time - delta, 0.0)
	_detect_landing()
	_update_visual_tilt(delta, steer, fwd_speed)
	_update_wheels(delta, steer, fwd_speed)
	_update_shadow()
	_update_effects(delta)
	_update_water(delta)
	_wall_cooldown = maxf(_wall_cooldown - delta, 0.0)
	_respawn_cooldown = maxf(_respawn_cooldown - delta, 0.0)
	# Checkpoint: aici, cu roatele pe asfalt, eram in siguranta.
	if track != null and is_on_floor() \
			and track.is_on_road(road_index, global_position, route):
		last_safe_index = road_index
		last_safe_route = route
	# Reperele pentru bilantul urmatorului tick.
	_prev_velocity = velocity
	_commanded_yaw = angular_velocity.y


## Shim de compatibilitate: "pe sol" inseamna cel putin o roata cu contact.
func is_on_floor() -> bool:
	return wheels_on_ground > 0


## Shim de compatibilitate: normala medie a solului de sub roti.
func get_floor_normal() -> Vector3:
	return _ground_normal


## Viteza solului de sub roti (platforma mobila), pentru sonde si hazarde.
func ground_velocity() -> Vector3:
	return _ground_velocity


## Un raycast per colt; arcul impinge LA COLT, si exact asta produce ruliul si
## tangajul: rotile incarcate imping mai tare decat cele usurate.
func _apply_suspension() -> void:
	wheels_on_ground = 0
	_lava_wheel_y = -INF
	_road_wheel_y = INF
	var contact_sum := Vector3.ZERO
	var normal_sum := Vector3.ZERO
	var ground_vel_sum := Vector3.ZERO
	var axle_sum: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
	_axle_grounded = [0, 0]
	var space := get_world_3d().direct_space_state
	var up := global_transform.basis.y
	var cast_len := suspension_rest + _susp_wheel_radius
	# Axa in lungul careia se numara treptele: directia masinii pe orizontala
	# (pe trepte drumul si masina merg in acelasi sens; o mica abatere doar
	# muta faza vibratiei, nu o schimba).
	var fwd_along := -global_transform.basis.z
	fwd_along.y = 0.0
	fwd_along = fwd_along.normalized()
	var steps_wheels := 0
	var kerb_count := 0
	var kerb_speed := Vector2(linear_velocity.x, linear_velocity.z).length()
	# Rigiditatea pe roata din frecventa si masa pe roata (k = m(2*pi*f)^2),
	# amortizarea din raport — tuning independent de cat cantareste masina.
	var wheel_mass := mass * 0.25
	var omega := TAU * spring_freq
	var k := wheel_mass * omega * omega
	var c := 2.0 * damping_ratio * sqrt(k * wheel_mass)
	for i in _wheel_points.size():
		var attach := to_global(_wheel_points[i])
		var query := PhysicsRayQueryParameters3D.create(
			attach, attach - up * cast_len)
		query.exclude = [get_rid()]
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			wheel_compression[i] = 0.0
			continue
		var ground := hit.collider as Node
		if ground != null and ground.has_meta(&"lava"):
			_lava_wheel_y = maxf(_lava_wheel_y, (hit.position as Vector3).y)
		else:
			_road_wheel_y = minf(_road_wheel_y, (hit.position as Vector3).y)
		var ground_vel := Vector3.ZERO
		if ground != null and ground.has_meta(&"platform_velocity"):
			ground_vel = ground.get_meta(&"platform_velocity") as Vector3
		ground_vel_sum += ground_vel
		wheels_on_ground += 1
		var axle := 0 if i < 2 else 1
		contact_sum += hit.position as Vector3
		normal_sum += hit.normal as Vector3
		axle_sum[axle] += hit.position as Vector3
		_axle_grounded[axle] += 1
		var dist := attach.distance_to(hit.position as Vector3)
		var compression := clampf(cast_len - dist, 0.0, suspension_rest)
		# Treptele: termen periodic in lungimea razei, vezi STEP_NOISE_M.
		if _steps_here or (ground != null and ground.has_meta(&"inca_steps")):
			steps_wheels += 1
			var along := (hit.position as Vector3).dot(fwd_along)
			compression = clampf(compression
				+ STEP_NOISE_M * sin(TAU * along / STEP_PITCH_M),
				0.0, suspension_rest)
		# Bordura: acelasi truc ca treptele, dar pe un pas mai fin si cu amplitudine
		# care creste cu viteza; oprit nu scutura. Doar pe bucla principala.
		if (kerb_rumble_enabled and track != null and route == 0
				and kerb_speed > 2.0
				and track.kerb_at(road_index, hit.position as Vector3)):
			kerb_count += 1
			var along_k := (hit.position as Vector3).dot(fwd_along)
			compression = clampf(compression + KERB_NOISE_M
				* clampf((kerb_speed - 2.0) / 18.0, 0.0, 1.0)
				* sin(TAU * along_k / KERB_PITCH_M), 0.0, suspension_rest)
		wheel_compression[i] = compression
		var offset := attach - global_position
		var point_vel := linear_velocity + angular_velocity.cross(offset)
		# Amortizorul masoara viteza RELATIVA la sol: pe o platforma care urca
		# cu 3 m/s, arcul nu e „comprimat cu 3 m/s" — se misca odata cu ea.
		var spring_vel := (point_vel - ground_vel).dot(up)
		var force_mag := k * compression - c * spring_vel
		# Arcul doar IMPINGE — daca ar si trage, orice creasta ar smulge
		# masina in jos nefiresc.
		if force_mag > 0.0:
			apply_force(up * force_mag, offset)
	kerb_wheels = kerb_count
	on_kerb = kerb_count > 0
	if (steps_wheels > 0) != on_steps:
		on_steps = steps_wheels > 0
		steps_changed.emit(self, on_steps)
	if wheels_on_ground > 0:
		_contact_offset = contact_sum / float(wheels_on_ground) - global_position
		_ground_normal = normal_sum.normalized()
		_ground_velocity = ground_vel_sum / float(wheels_on_ground)
	else:
		_ground_velocity = Vector3.ZERO
	for axle in 2:
		if _axle_grounded[axle] > 0:
			_axle_offset[axle] = axle_sum[axle] / float(_axle_grounded[axle]) \
				- global_position
	# Roata URCATA pe crusta de lava = ars. Nu orice atingere de raza: marginea
	# crustei e evazata la baza (~0.55 m la sol), iar o roata care o atinge la
	# firul drumului e frecatura, nu incendiu — cu ars-la-orice-atingere poarta
	# de 4 m se ingusta efectiv la ~3.3 si pedepsea o trecere curata (masurat in
	# ProbeLavaStages, cu AI la volan). Arde cine calca VIZIBIL mai sus decat
	# rotile de pe drum — adica s-a catarat pe limba — sau cine nu mai are nicio
	# roata pe altceva (crusta l-a inghitit; si zidul peste care incerci sa
	# treci, masurat: fara asta il urcai cu 13 m/s).
	if _lava_wheel_y > -INF \
			and (_road_wheel_y == INF or _lava_wheel_y > _road_wheel_y + 0.35):
		scorch()


## Motor, frana, plafon, drag si directie — ca FORTE, cu aceleasi reguli de
## feel. Fortele de cauciuc se aplica la punctele de contact (vezi nota de la
## _contact_offset); grip-ul lateral e per axa, ca driftul sa taie doar
## spatele.
func _apply_driving(steer: float, throttle: float,
		fwd_h: Vector3, fwd_speed: float, delta: float) -> void:
	# Tractiunea cere contact: cu rotile in aer nu se accelereaza si nu se
	# vireaza. Drag-ul lipseste si el — lectia sariturii din aug 2026 (in aer
	# nu exista nicio rezistenta modelata) e pastrata de constructie.
	var ground_frac := float(wheels_on_ground) / 4.0
	if ground_frac == 0.0:
		_air_control(throttle)
		return

	var rel_vel := velocity - _ground_velocity
	var hvel := Vector3(rel_vel.x, 0.0, rel_vel.z)
	var vmax := _current_max_speed()

	# --- Motor / frana ---
	if throttle > 0.0 and fwd_speed < vmax:
		var accel := acceleration
		if is_boosting:
			accel += turbo_accel_bonus
		accel *= 1.0 + draft * slip_accel_bonus
		apply_force(fwd_h * accel * throttle * mass * ground_frac,
			_contact_offset)
	elif throttle < 0.0:
		if fwd_speed > 2.0:
			apply_force(fwd_h * brake_force * throttle * mass * ground_frac,
				_contact_offset)
		elif fwd_speed > -reverse_speed:
			apply_force(
				fwd_h * acceleration * 0.6 * throttle * mass * ground_frac,
				_contact_offset)
	# Plafonul: peste vmax nu se taie viteza, se trage inapoi — echivalentul
	# lui move_toward(12.0) de pe CharacterBody. Central, nu la sol: e un
	# guvernator de joc, nu o forta fizica, n-are voie sa adauge tangaj.
	if fwd_speed > vmax:
		apply_central_force(-fwd_h * 12.0 * mass)

	# --- Rezistenta la rulare, doar pe sol ---
	apply_force(-hvel * drag * mass * ground_frac, _contact_offset)

	# --- Grip lateral, per axa: fata tine, spatele aluneca in drift ---
	# Dozat cu rampa (drift_blend) si cu viteza: cu cat mai repede, cu atat
	# spatele cedeaza mai putin, deci se roteste mai putin — arc larg.
	var drift_amt := _drift_amount()
	var drift_t := _drift_speed_t(fwd_speed)
	# Puterea pierduta prin frecarea laterala, adunata pe axe: pentru o forta
	# de amortizare -k·lat, F·v = -k·|lat|². In drift o parte se intoarce ca
	# impuls inainte — vezi `drift_momentum_keep`.
	var scrub_power := 0.0
	for axle in 2:
		if _axle_grounded[axle] == 0:
			continue
		var grip_axle := grip
		if axle == 1 and drift_amt > 0.0:
			grip_axle = lerpf(grip,
				lerpf(drift_grip, drift_grip_at_top, drift_t), drift_amt)
		if slip_time > 0.0:
			grip_axle = slip_grip
		# Viteza laterala A AXEI (cu componenta din rotatie): spatele care se
		# roteste in jurul fetei chiar simte ca aluneca, si e amortizat acolo.
		var offset: Vector3 = _axle_offset[axle]
		var point_vel := linear_velocity + angular_velocity.cross(offset) \
			- _ground_velocity
		var lat := Vector3(point_vel.x, 0.0, point_vel.z)
		lat -= fwd_h * lat.dot(fwd_h)
		var axle_frac: float = float(_axle_grounded[axle]) / 2.0
		var k := grip_axle * mass * 0.5 * axle_frac
		apply_force(-lat * k, offset)
		scrub_power += k * lat.length_squared()

	# --- Impulsul inainte intors in drift (powerslide) ---
	# O forta pe directia caroseriei a carei putere (F·fwd_speed) egaleaza
	# fractia `keep` din cea pierduta lateral: viteza se ROTESTE spre bot in
	# loc sa se piarda — trucul din kart-uri, scris ca forta. Centrala, ca
	# plafonul: e un guvernator de joc, nu un motor, n-are voie sa adauge
	# tangaj. Plafonata la de trei ori acceleratia, ca un derapaj extrem sa nu
	# devina catapulta, si stinsa cat tine alunecarea de la balta/T-bone
	# (slip_time): aia e pedeapsa, nu drift.
	if drift_amt > 0.0 and throttle > 0.0 and fwd_speed > 3.0 \
			and slip_time <= 0.0:
		var keep_force := scrub_power / fwd_speed \
			* drift_momentum_keep * drift_amt * throttle
		keep_force = minf(keep_force, acceleration * 3.0 * mass)
		apply_central_force(fwd_h * keep_force * ground_frac)

	# --- Directia: in drift volanul alege RAZA, nu sensul (maparea CTR) ---
	var speed_frac := clampf(absf(fwd_speed) / (max_speed * 0.5), 0.0, 1.0)
	var effective_steer := steer
	if drift_amt > 0.0:
		# +1 = volan spre interiorul alunecarii, -1 = contravolan plin.
		var into := clampf(steer * drift_dir, -1.0, 1.0)
		var tight := lerpf(drift_arc_tight, drift_arc_tight_top, drift_t)
		var arc := lerpf(drift_arc_wide, tight, (into + 1.0) * 0.5)
		effective_steer = lerpf(steer, drift_dir * arc, drift_amt)
	var reverse_sign := -1.0 if fwd_speed < -0.5 else 1.0
	var yaw_rate := effective_steer * steer_speed * speed_frac * reverse_sign \
		* _steer_taper(fwd_speed, drift_amt)
	# Pe asfalt comanda se scrie direct (arcade: volanul e rotatia). In drift
	# rotatia o URMEAZA cu inertie, ca sa existe ce prinde cu contravolanul;
	# rampa de iesire duce tau la zero, deci revenirea pe asfalt e continua.
	var tau := drift_yaw_inertia * drift_amt
	if tau > 0.001:
		_yaw_cmd = lerpf(_yaw_cmd, yaw_rate, 1.0 - exp(-delta / tau))
	else:
		_yaw_cmd = yaw_rate
	_spinout_assist(throttle, fwd_h, hvel)
	# Comanda + rotatia ramasa din lovituri (se stinge singura, plafonata).
	var kick := _yaw_kick if _yaw_kick_left > 0.0 else 0.0
	angular_velocity = Vector3(
		angular_velocity.x, _yaw_cmd + _impact_yaw + kick, angular_velocity.z)


## Strangerea virajului cu viteza: 1.0 sub `steer_taper_start` din max_speed,
## coboara liniar la `steer_taper_at_top` la max_speed (si ramane acolo cu
## turbo). Scutita in drift: se amesteca spre 1.0 cu dozajul driftului.
func _steer_taper(fwd_speed: float, drift_amt: float) -> float:
	var start := max_speed * steer_taper_start
	var t := clampf(inverse_lerp(start, max_speed, absf(fwd_speed)), 0.0, 1.0)
	return lerpf(lerpf(1.0, steer_taper_at_top, t), 1.0, drift_amt)


## Spin-out assist (feel_checklist: spinout-assist): vezi grupul de exporturi.
## Declansare: unghiul dintre bot si viteza (orizontala, fata de sol) peste
## `spinout_slip_deg`, la peste `spinout_min_speed`, fara sa fie marsarier din
## voie (fara gaz la viteza de marsarier: frana, sau rulat de-a-ndaratelea pe o
## panta). Odata pornita (cel mult 2 s),
## tine pana botul e la `spinout_release_deg` de tinta: directia de mers, iar
## sub 3 m/s directia soselei (daca exista pista). Rotatia intra prin
## _impact_yaw, ca orice alt impuls de yaw — niciodata cuplu.
func _spinout_assist(throttle: float, fwd_h: Vector3, hvel: Vector3) -> void:
	if not spinout_enabled:
		_spinout_on = false
		return
	var speed := hvel.length()
	var target := Vector3.ZERO
	if speed > 3.0:
		target = hvel / speed
	elif _spinout_on and track != null:
		var ahead := track.point_at(road_index + 3, route) - track.point_at(road_index, route)
		ahead.y = 0.0
		if ahead.length_squared() > 1e-4:
			target = ahead.normalized()
	if not _spinout_on:
		if speed < spinout_min_speed:
			return
		var by_choice := throttle <= 0.0 and speed <= reverse_speed * 1.3
		if fwd_h.dot(target) < cos(deg_to_rad(spinout_slip_deg)) and not by_choice:
			_spinout_on = true
			_spinout_left = 2.0
		return
	_spinout_left -= get_physics_process_delta_time()
	if (target == Vector3.ZERO or _spinout_left <= 0.0
			or fwd_h.dot(target) > cos(deg_to_rad(spinout_release_deg))):
		_spinout_on = false
		return
	var err := atan2(fwd_h.cross(target).y, fwd_h.dot(target))
	var want := clampf(err * spinout_yaw_gain, -spinout_yaw_max, spinout_yaw_max)
	if absf(want) > absf(_impact_yaw):
		_impact_yaw = want


## Control in aer: gazul apleaca botul, frana il ridica. Doar jucatorul; AI-ul
## ramane neutru in aer. Se ADAUGA la viteza unghiulara pe axa dreapta a
## masinii pana la `air_pitch_rate`, fara sa franeze rotatia din lansare.
func _air_control(throttle: float) -> void:
	if (not air_control_enabled or not (controller is PlayerController)
			or throttle == 0.0 or not race_active):
		return
	var right := global_transform.basis.x
	var along := angular_velocity.dot(right)
	# Pozitiv in jurul axei dreapta = bot in sus; gaz (throttle > 0) = bot in jos.
	var want := -signf(throttle) * air_pitch_rate
	var step := air_pitch_accel * get_physics_process_delta_time()
	var new_along := along
	if want < 0.0 and along > want:
		new_along = maxf(along - step, want)
	elif want > 0.0 and along < want:
		new_along = minf(along + step, want)
	angular_velocity += right * (new_along - along)


## Slipstream: cea mai buna masina din fata, in con, da `draft` tinta 1.
func _update_draft(delta: float) -> void:
	var target := 0.0
	if slipstream_enabled and race_active and not finished and wheels_on_ground > 0:
		target = _draft_target()
	var rate := 1.0 / maxf(slip_fade_s, 0.01)
	if target > draft:
		rate = 1.0 / maxf(slip_build_s, 0.01)
	draft = move_toward(draft, target, rate * delta)


func _road_curves_ahead() -> bool:
	if track == null or track.curve == null:
		return false
	var step := maxf(track.curve.bake_interval, 0.1)
	var n := maxi(int(slip_lookahead_m / step), 2)
	var t0 := track.point_at(road_index + 1, route) - track.point_at(road_index, route)
	var t1 := track.point_at(road_index + n + 1, route) - track.point_at(road_index + n, route)
	t0.y = 0.0
	t1.y = 0.0
	if t0.length_squared() < 1e-6 or t1.length_squared() < 1e-6:
		return false
	return t0.angle_to(t1) > slip_curve_rad


func _draft_target() -> float:
	var v := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	if v.length() < max_speed * slip_min_speed_frac:
		return 0.0
	# Aspiratia e un lucru de DREAPTA: in viraj conul se strange si nimeni nu
	# mai e „in spatele" nimanui. Fara portita asta, bonusul de acceleratie facea
	# masinile sa intre mai tare in viraje (ProbeRace: loviturile de perete
	# se dublau pe Transfagarasan).
	if absf(angular_velocity.y) > slip_max_yaw or brake_lamp:
		return 0.0
	# Drumul din fata se curbeaza: bonusul se retrage INAINTE de viraj, ca plafonul
	# in plus sa nu intre in curba (AI-ul isi planifica franarea pe viteza de
	# dinaintea aspiratiei). Unghiul dintre tangenta de acum si cea de la
	# `slip_lookahead_m` mai departe pe ruta masinii.
	if _road_curves_ahead():
		return 0.0
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	for node in get_tree().get_nodes_in_group(&"cars"):
		var other := node as Car
		if other == null or other == self or other.finished or not other.race_active:
			continue
		var rel := other.global_position - global_position
		rel.y = 0.0
		var along := rel.dot(fwd)
		if along < slip_min_gap or along > slip_max_gap:
			continue
		var lat := (rel - fwd * along).length()
		if lat > 0.9 + along * slip_cone:
			continue
		var ov := Vector3(other.linear_velocity.x, 0.0, other.linear_velocity.z)
		if ov.length() < other.max_speed * slip_min_speed_frac:
			continue
		if ov.dot(fwd) < ov.length() * 0.8:
			continue
		return 1.0
	return 0.0


## Bilantul contactelor raportate de solver: izbituri cu alte masini (plafon,
## rotatie, slip, semnal), pereti (wall_hit) si popice (imprastiate).
func _process_contacts(delta: float) -> void:
	_scan_contact_state()
	_impact_wall_cooldown = maxf(_impact_wall_cooldown - delta, 0.0)
	var cars_hit: Array[Car] = []
	var static_hit := false
	for body in get_colliding_bodies():
		if body is Car:
			cars_hit.append(body as Car)
		elif body is RigidBody3D:
			# Popice & co: imprastiate cu un impuls scalat cu masa noastra —
			# autobuzul le trimite mai departe decat un sport.
			var dir := (body as Node3D).global_position - global_position
			dir.y = 0.0
			if dir.length_squared() < 0.01:
				dir = -global_transform.basis.z
			(body as RigidBody3D).apply_central_impulse(
				dir.normalized() * clampf(
					horizontal_speed() * 0.5 * mass_factor, 1.0, 16.0)
				+ Vector3.UP * 1.5)
		elif body is StaticBody3D:
			static_hit = true
			# Lava (Stromboli): contactul e distrugere, nu perete. Meta vine de
			# la LavaFlowHazard, pe colizorul stadiului curent.
			if body.has_meta(&"lava"):
				scorch()

	var dv_vec := velocity - _prev_velocity
	if not cars_hit.is_empty():
		var dv := dv_vec.length()
		# Plafonul de violenta: excedentul se taie pastrand DIRECTIA, deci
		# raportul de mase (identitatea) supravietuieste taierii.
		if dv > bump_max_dv:
			velocity = _prev_velocity + dv_vec * (bump_max_dv / dv)
			dv = bump_max_dv
		# Rotatia data de solver din lovitura excentrica, preluata cu plafon.
		# DOAR la izbituri reale (dv peste pragul de inchidere) — acelasi
		# criteriu ca semnalul: sub el, contactul e frecare, nu lovitura. In
		# contactul SUSTINUT solverul se opune in fiecare tick rotatiei
		# comandate (corpul celuilalt freaca de al nostru), iar diferenta —
		# mereu de semn opus comenzii — s-ar acumula aici pana la plafon si
		# ti-ar anula directia cat tine contactul. Masurat in
		# ProbeContactSteer: impins bara-n bara, virajul cadea la jumatate.
		var solver_yaw := angular_velocity.y - _commanded_yaw
		if dv >= bump_min_closing and absf(solver_yaw) > 0.1:
			_impact_yaw = clampf(_impact_yaw + solver_yaw,
				-bump_yaw_max, bump_yaw_max)
		# Lovitura mare pe lateral taie scurt aderenta (mecanismul de
		# aquaplanare, refolosit): un T-bone te face sa derapezi.
		var fwd := -global_transform.basis.z
		var fwd_hn := Vector3(fwd.x, 0.0, fwd.z).normalized()
		var lat_dv := (dv_vec - fwd_hn * dv_vec.dot(fwd_hn)).length()
		if lat_dv >= bump_slip_dv:
			slip_time = maxf(slip_time, clampf(0.15 + lat_dv * 0.02, 0.0, 0.55))
			slip_grip = SLIP_GRIP_WET
		# Semnalul, cu prag (frecarea nu e ghiont) si cooldown per pereche.
		if dv >= bump_min_closing:
			for other in cars_hit:
				var key := other.get_instance_id()
				if _bump_pairs.has(key):
					continue
				_bump_pairs[key] = bump_pair_cooldown
				bumped.emit(self, other, dv)
				var away_n := global_position - other.global_position
				away_n.y = 0.0
				impact.emit(self, &"car", dv,
					away_n.normalized() if away_n.length_squared() > 1e-4
						else -dv_vec.normalized(),
					_contact_point_with(other, (global_position
						+ other.global_position) * 0.5), other)
				_emit_sparks(other, dv)
				# Sunetul (bufnitura `bump` + tabla `metal_hit`, plus straturile
				# tap/crunch/crash) nu mai e aici: il da ImpactSound, pe semnalul
				# `impact` de mai sus (feel_checklist: impact-layers).
		# Impulsul de separare (reteta SuperTuxKart): contactul sustinut nu
		# are voie sa lipeasca masinile. O acceleratie LATERALA le impinge una
		# de langa alta -- centrala (fara rotatie: directia ramane a soferului),
		# pe orizontala, scalata cu raportul maselor (usoara e maturata, grea
		# abia se clinteste -- identitatea prin masa ramane) si cu cat de
		# "alaturi" e contactul: bara-n bara aproape deloc (plutonul ramane
		# pluton, impingerea din spate e mecanica legitima), umar la umar din
		# plin. Doar cu rotile pe sol: in aer ar fi inca un mecanism de zbor.
		if wheels_on_ground > 0:
			for other in cars_hit:
				var away := global_position - other.global_position
				away.y = 0.0
				var dist := away.length()
				if dist < 0.05:
					continue
				var lat := away - fwd_hn * away.dot(fwd_hn)
				var lat_len := lat.length()
				if lat_len < 0.05:
					continue
				var side_frac := lat_len / dist
				var mass_share := 2.0 * other.mass / (mass + other.mass)
				apply_central_force(lat / lat_len
					* bump_separation_accel * side_frac * mass_share * mass)
	elif static_hit:
		# Perete/bariera: impact = schimbarea ORIZONTALA de viteza (aterizarea
		# dura pe sol are dv vertical si nu e izbitura de perete).
		var dv_h := Vector3(dv_vec.x, 0.0, dv_vec.z).length()
		if dv_h >= impact_min_dv and _impact_wall_cooldown <= 0.0:
			_impact_wall_cooldown = 0.2
			var n := wall_normal
			if n == Vector3.ZERO:
				n = Vector3(dv_vec.x, 0.0, dv_vec.z).normalized()
			impact.emit(self, &"wall", dv_h, n,
				wall_point if wall_contact else global_position - n * collider_half_width(),
				_last_static)
		if dv_h > 8.0 and _wall_cooldown <= 0.0:
			_wall_cooldown = 0.35
			wall_hit.emit(self, dv_h)
			# Sunetul peretelui il da ImpactSound (strat dupa putere, nu un nivel fix).
		# Izbitura dura de perete arunca soferul. Directia de zbor e viteza de
		# DINAINTE de impact: figurina continua drumul pe care masina nu l-a
		# mai putut face, peste bariera.
		if dv_h >= eject_wall_dv:
			# 0.6 din viteza inainte + 7.5 m/s in sus: peste o bariera de 1,2 m
			# trece; intr-o faleza se izbeste si cade — amandoua sunt corecte.
			var fling := Vector3(_prev_velocity.x, 0.0, _prev_velocity.z) * 0.6
			_eject(fling + Vector3.UP * 7.5, "perete", dv_h)

	for key: int in _bump_pairs.keys():
		var left := float(_bump_pairs[key]) - delta
		if left <= 0.0:
			_bump_pairs.erase(key)
		else:
			_bump_pairs[key] = left
	_impact_yaw *= exp(-4.0 * delta)
	if absf(_impact_yaw) < 0.05:
		_impact_yaw = 0.0
	if _yaw_kick_left > 0.0:
		_yaw_kick_left -= delta
		if _yaw_kick_left <= 0.0:
			_yaw_kick = 0.0
	_wall_glance(delta)


## Razuire vs frontal (feel_checklist: glancing-vs-headon) + anti-lipire.
##
## Problema: botul infipt in perete la un unghi mic NU se roteste singur
## (directia scrie yaw-ul direct), iar grip-ul lateral il impinge in zid cu
## zeci de m/s^2 — frecarea de perete mananca viteza cat tine contactul.
## Raspunsul are trei parti:
##   1. EPISODUL incepe cand viteza de DINAINTE de tick (`_prev_velocity`, adica
##      inainte ca solverul sa aplice bounce-ul) face cel mult `glance_angle_deg`
##      cu planul peretelui si merge cu peste 5 m/s. Un frontal nu intra: se
##      opreste cu bounce, ca pana acum.
##   2. cat tine episodul, frecarea masinii scade la `glance_friction`: se pierde
##      componenta normala (cu bounce-ul din material), tangentiala ramane.
##   3. botul e rotit spre paralel prin `_impact_yaw` (rad/s ~ unghiul), deci
##      grip-ul nu mai impinge in zid si contactul se termina singur.
## Hazardele mobile (AnimatableBody3D) nu intra: strivire/purtare neschimbate.
##
## Anti-lipire, separat: botul in perete (> ~17 grade) la sub 3 m/s mai mult de
## `stuck_nudge_time` primeste o impingere dinspre perete + o rotatie spre
## tangenta. Fara ea, un jucator cu gaz tinut sta lipit pana la repunere.
func _wall_glance(delta: float) -> void:
	_stuck_cool = maxf(_stuck_cool - delta, 0.0)
	var live := glance_enabled and wall_contact and not wall_moving \
		and rub_car == null and wheels_on_ground > 0 and race_active \
		and not finished and _eject_left <= 0.0 and _recover_left <= 0.0
	if not live:
		_stuck_t = maxf(_stuck_t - delta * 2.0, 0.0)
		_stuck_push_left = 0.0 # fara contact nu mai exista „perete de ocolit"
		_glance_gap += delta
		if _glance_gap > 0.15:
			_glance_episode = false
		_set_car_friction(glance_friction if _glance_episode else CAR_FRICTION)
		return
	_glance_gap = 0.0
	var n := wall_normal
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var into_h := -fwd.dot(n) # +1 = botul drept in perete
	var vref := Vector3(_prev_velocity.x, 0.0, _prev_velocity.z)
	var speed := vref.length()
	if not _glance_episode:
		if speed > 5.0:
			var into_v := -vref.dot(n) / speed
			if absf(into_v) <= sin(deg_to_rad(glance_angle_deg)):
				_glance_episode = true
		elif into_h > 0.05 and into_h <= sin(deg_to_rad(glance_angle_deg * 2.0)):
			# Aproape oprita, cu botul oblic in perete: tot razuire (altfel
			# gazul o tine lipita, cu grip-ul lateral impingand in zid).
			_glance_episode = true
	_set_car_friction(glance_friction if _glance_episode else CAR_FRICTION)

	# Nudge spre paralel, doar cat botul e inca spre perete (nu si cand te
	# departezi) si nu e un frontal (peste 2x unghiul de razuire).
	var fwd_speed := Vector3(velocity.x, 0.0, velocity.z).dot(fwd)
	if _glance_episode and fwd_speed > 0.0 and into_h > 0.03 \
			and into_h <= sin(deg_to_rad(glance_angle_deg * 2.0)):
		var want := _toward_parallel(fwd, n) * clampf(
			asin(into_h) * glance_yaw_gain, 0.0, glance_yaw_max)
		if absf(want) > absf(_impact_yaw):
			_impact_yaw = clampf(want, -bump_yaw_max, bump_yaw_max)

	# Anti-lipire.
	var slow := Vector3(velocity.x, 0.0, velocity.z).length() < 3.0
	if slow and into_h > 0.3:
		_stuck_t += delta
	else:
		_stuck_t = maxf(_stuck_t - delta * 2.0, 0.0)
	if _stuck_t >= stuck_nudge_time and _stuck_cool <= 0.0:
		_stuck_t = 0.0
		_stuck_cool = 0.6
		_stuck_push_left = 0.3
		linear_velocity += n * stuck_nudge_speed
	if _stuck_push_left > 0.0:
		# Rotatia se REAFIRMA cat tine impingerea: peretele se opune la un
		# singur impuls (masurat: jumatate din unghiul calculat).
		_stuck_push_left -= delta
		_impact_yaw = clampf(_toward_parallel(fwd, n) * stuck_nudge_yaw,
			-bump_yaw_max, bump_yaw_max)


## +1 / -1: in ce sens trebuie rotit botul (yaw pozitiv = stanga) ca sa se
## aseze paralel cu peretele de normala `n`, pe latura cea mai apropiata.
func _toward_parallel(fwd: Vector3, n: Vector3) -> float:
	var t := fwd - n * fwd.dot(n)
	if t.length_squared() < 1e-4:
		t = Vector3(-n.z, 0.0, n.x) # frontal exact: alege o tangenta oarecare
	var s := signf(fwd.cross(t).y)
	return s if s != 0.0 else 1.0


func _set_car_friction(value: float) -> void:
	if _pmat != null and _pmat.friction != value:
		_pmat.friction = value


## Auto-upright (feel_checklist: auto-upright). Rasturnata si aproape oprita
## `upright_delay` secunde, masina sare (`upright_hop`) si se roteste spre
## vertical pe axa botului, deci pozitia si directia ramane. Se foloseste
## viteza unghiulara pe X/Z (yaw-ul e al directiei, scris in _apply_driving; in
## aer _apply_driving nici nu ruleaza), nu o teleportare: fizica o aseaza.
##
## Locuri in care NU se intoarce pe loc — raman pe plasa veche (Race o repune
## la 1,5 s, iar noi apelam recover() la acelasi prag): in apa, cu mult sub
## sosea, sau la peste UPRIGHT_OFFROAD_M de ea. Aceleasi hazarde, aceleasi
## declansatoare de repunere ca inainte.
func _tick_upright(delta: float) -> void:
	if not upright_enabled or finished or not race_active or on_start_grid \
			or _eject_left > 0.0 or _recover_left > 0.0:
		_roof_t = 0.0
		_upright_left = 0.0
		return
	if _upright_left > 0.0:
		_run_upright(delta)
		return
	var flipped := global_transform.basis.y.dot(Vector3.UP) < UPRIGHT_FLIPPED_COS \
		and horizontal_speed() < UPRIGHT_FLIPPED_SPEED
	if not flipped:
		_roof_t = 0.0
		return
	_roof_t += delta
	if _roof_t >= UPRIGHT_GIVE_UP_S:
		_roof_t = 0.0
		recover() # nu s-a putut intoarce (loc invalid sau incercare ratata)
	elif _roof_t >= upright_delay and _upright_spot_ok():
		_upright_left = upright_max_time
		# Doar sus: ce mai aluneca pe orizontala (sub 4 m/s) se opreste, ca masina
		# sa ramana unde a fost rasturnata.
		linear_velocity = Vector3(0.0, maxf(linear_velocity.y, upright_hop), 0.0)


func _run_upright(delta: float) -> void:
	_upright_left -= delta
	var up := global_transform.basis.y
	var cos_up := up.dot(Vector3.UP)
	if cos_up > 0.85 and wheels_on_ground >= 2:
		_upright_left = 0.0
		_roof_t = 0.0
		uprighted.emit(self)
		return
	if _upright_left <= 0.0:
		# Incercarea s-a terminat si tot nu e pe roti: plasa veche.
		_upright_left = 0.0
		_roof_t = 0.0
		if cos_up < 0.6:
			recover()
		return
	var axis := up.cross(Vector3.UP)
	if axis.length_squared() < 1e-4:
		axis = global_transform.basis.z # exact pe acoperis: ruleaza pe axa botului
	axis = axis.normalized()
	var theta := acos(clampf(cos_up, -1.0, 1.0))
	var rate := minf(theta * upright_turn_rate, UPRIGHT_MAX_RATE)
	angular_velocity = Vector3(axis.x * rate, angular_velocity.y, axis.z * rate)


## Se poate intoarce pe loc aici? (Fara pista — sonde — mereu da.)
func _upright_spot_ok() -> bool:
	if in_water:
		return false
	if track == null:
		return true
	var rp := track.point_at(road_index, route)
	if global_position.y < rp.y - UPRIGHT_BELOW_ROAD_M:
		return false
	if not track.is_on_road(road_index, global_position, route):
		var dh := Vector2(global_position.x - rp.x, global_position.z - rp.z).length()
		if dh > UPRIGHT_OFFROAD_M:
			return false
	return true


## Plafonul de viteza al momentului: taiat de iarba, ridicat de turbo.
## Turbo-ul merge SI pe iarba — scurtatura cu turbo e o alegere valida.
func _current_max_speed() -> float:
	var vmax := max_speed * speed_scale * speed_limit_factor
	if track != null and not track.is_on_road(road_index, global_position, route):
		vmax *= offroad_speed_factor
	elif track != null and route != 0:
		# Pe o banda secundara, plafonul ei: drumul de tara e mai lent decat
		# asfaltul (TrackBranch.speed_factor). `elif`, ca sa nu se cumuleze cu
		# offroad-ul cand esti pe iarba de LANGA banda.
		vmax *= track.route_speed_factor(route)
	if is_boosting:
		vmax += turbo_speed_bonus
	vmax += draft * slip_speed_bonus
	# Strivirea taie plafonul, nu viteza curenta: pierzi timp reaccelerand, exact
	# ca la offroad. Se aplica DUPA turbo, ca sa nu poti sterge pedeapsa cu boost.
	return vmax * crush_factor

# ------------------------------------------------------------------- drift

## Handbrake pur: alunecare controlata pentru viraje, fara boost la iesire.
func _update_drift(drift_pressed: bool, steer: float, fwd_speed: float,
		delta: float) -> void:
	if not is_drifting:
		if drift_pressed and fwd_speed > drift_min_speed and absf(steer) > 0.25:
			is_drifting = true
			drift_dir = signf(steer)
			_drift_time = 0.0
			if is_player:
				AudioManager.play_sfx(&"drift_start")
	elif not drift_pressed or fwd_speed < drift_min_speed * 0.55:
		_end_drift()
	if is_drifting:
		_drift_time += delta
		drift_blend = move_toward(drift_blend, 1.0,
			delta / maxf(drift_ramp_in, 0.001))
	else:
		drift_blend = move_toward(drift_blend, 0.0,
			delta / maxf(drift_ramp_out, 0.001))


## Iesirea din drift, cea JUCATA (frana de mana eliberata sau viteza prea
## mica): spatele se reaseaza pe rampa, caroseria tresare o data in sens
## opus, cauciucul ciripeste cand se prinde iar, iar HUD-ul afla ca sa
## pulseze bara. Repunerea si aruncarea sting driftul direct, fara nimic
## din astea — acolo nu s-a terminat un drift, a disparut masina.
func _end_drift() -> void:
	is_drifting = false
	_snap_left = DRIFT_SNAP_TIME
	_snap_dir = drift_dir
	# Un drift de sub 0.3 s e o atingere de buton, nu o alunecare: fara
	# ciripit, altfel fiecare tap pocneste.
	if is_player and _drift_time > 0.3:
		AudioManager.play_sfx(&"drift_end")
	drift_ended.emit(self, _drift_time)


## Dozajul driftului aplicat fizicii: rampa netezita (smoothstep), ca intrarea
## sa nu porneasca nici ea cu o treapta de panta.
func _drift_amount() -> float:
	return smoothstep(0.0, 1.0, drift_blend)


## 0 la drift_min_speed, 1 la viteza maxima a masinii — driftul se dozeaza pe
## viteza PROPRIE, ca tuk-tuk-ul (18 m/s) sa-si aiba si el driftul rapid.
func _drift_speed_t(fwd_speed: float) -> float:
	return clampf(inverse_lerp(drift_min_speed, max_speed, fwd_speed), 0.0, 1.0)

# ------------------------------------------------------------------- turbo

func _update_turbo(turbo_pressed: bool, delta: float) -> void:
	_forced_boost = maxf(_forced_boost - delta, 0.0)
	# Poti PORNI turbo doar cu bara peste prag; odata pornit, arzi pana la 0.
	var can_fire := turbo_charge > (0.02 if is_boosting else turbo_min_to_fire)
	# Cat arzi nu ai ce arde: focul ti-a consumat combustibilul (vezi
	# `ignite`). Fara clauza asta bara s-ar umple in timp ce masina e in
	# flacari, si golirea de la impact ar fi fost recuperata inainte sa se
	# stinga focul — adica pedeapsa ar fi existat doar pe hartie.
	if burn_time > 0.0:
		is_boosting = _forced_boost > 0.0
		return
	# Strivit = turbo BLOCAT (4-B, 6 oct 2026). `crush()` stinge boost-ul o
	# singura data, dar daca butonul ramane apasat, tick-ul urmator il reaprindea:
	# `_current_max_speed` adauga +turbo_speed_bonus INAINTE sa inmulteasca cu
	# `crush_factor` (deci plafonul urca de la 0.7*vmax la 0.7*(vmax+11)), accelerarea
	# primea +turbo_accel_bonus, `_start_boost` dadea +4 m/s si `_punch_scale`
	# suprascria turtirea tinuta. Jucatorul iesea din strivire cu un buton. Cat
	# `crush_time` > 0 turbo-ul nu porneste; bara NU se goleste (nu ai ars nimic) si
	# continua sa se incarce, ca sa-l ai gata cand expira strivirea.
	var crush_blocked := crush_blocks_turbo and crush_time > 0.0
	if _turbo_needs_release:
		if turbo_pressed:
			turbo_pressed = false
		else:
			_turbo_needs_release = false
	if turbo_pressed and can_fire and not crush_blocked:
		if not is_boosting:
			_start_boost()
		turbo_charge = maxf(turbo_charge - delta / turbo_burn_time, 0.0)
		is_boosting = true
	else:
		is_boosting = _forced_boost > 0.0
		# Bara se umple din mers; drift-ul o hraneste mult mai repede.
		var fill := delta / turbo_fill_time
		if is_drifting:
			fill *= turbo_drift_multiplier
		if turbo_recharge:
			turbo_charge = minf(turbo_charge + fill, 1.0)

func _start_boost() -> void:
	var forward := -global_transform.basis.z
	velocity += Vector3(forward.x, 0.0, forward.z).normalized() * 4.0
	_punch_scale(Vector3(0.85, 0.9, 1.2))
	boost_started.emit(self)
	if is_player:
		AudioManager.play_sfx(&"boost")

func grant_turbo(amount: float) -> void:
	turbo_charge = clampf(turbo_charge + amount, 0.0, 1.0)

## TURBO apasat de dinainte de GO, prea devreme pentru rocket start (#491):
## butonul trebuie ridicat si apasat din nou. Altfel, tinut de pe ecranul de
## incarcare, aprindea la GO bara plina — masina tasnea singura, fara gaz, iar
## „Prea devreme..." de pe ecran contrazicea ce vedeai.
func hold_turbo_until_release() -> void:
	_turbo_needs_release = true

## Ardere gratuita (rocket start): boost fara sa goleasca bara.
func force_boost(seconds: float) -> void:
	_forced_boost = seconds
	is_boosting = true
	_start_boost()

# ------------------------------------------------------------- imbranceli

## Refresh-uit de WaterHazard cat timp esti in apa (conducta sau val).
## Cere alunecare pentru urmatoarea fractiune de secunda.
##
## `grip_value` e aderenta laterala cat timp tine: SLIP_GRIP_PUDDLE pentru o
## balta (practic zero directie), SLIP_GRIP_WET pentru o suprafata uda pe care
## se poate totusi conduce. Reper: asfalt 7-10, drift 2.0.
func apply_slip(grip_value: float = SLIP_GRIP_PUDDLE) -> void:
	slip_time = 0.25
	slip_grip = grip_value


## Prins de o rafala de abur: vezi prost cateva zecimi de secunda, si ATAT.
##
## Nicio atingere de viteza, grip, turbo sau caroserie — e intentia, nu o
## scapare. Fumarola e clasa „hazard-teatru, cost zero" din brief: sperie,
## invata un ritm, si nu rupe singura dreapta pe care se mai poate depasi.
##
## Se APELEAZA IN FIECARE CADRU cat esti in nor (ca `apply_slip`), deci ceasul
## se prelungeste cat stai in el; `maxf` face ca o a doua gura sa nu-l scurteze
## pe al primeia. Semnalul se emite doar la INTRARE, altfel HUD-ul ar primi
## zeci de mesaje pe secunda.
func blind(seconds: float = 0.5) -> void:
	if blind_time <= 0.0:
		blinded.emit(self, seconds)
	blind_time = maxf(blind_time, seconds)

## Ghiont de la un obstacol care iti schimba traiectoria: caruselul te matura
## pe tangenta, deviatorul te trimite pe cealalta banda. Impactul in sine
## (shake + sunet) vine din coliziunea solida, prin _handle_bumping.
## Strivit de un hazard: turtit, incetinit, si scos din boost.
##
## `factor` inmulteste plafonul de viteza (0.55 = 55%), `keep_speed` cat din
## viteza orizontala ramane pe loc, iar `squash` e forma de turtire.
## `hold_squash` tine caroseria turtita CAT TINE incetinirea, in loc s-o lase sa
## revina in 0.25 s ca la un simplu punch.
##
## Diferenta e de citire, nu de cosmetica. La tren sau la o izbitura, turtirea e
## un accent pe IMPACT — s-a intamplat ceva, gata. La bolovanul care te striveste
## (#242), turtirea e chiar EXPLICATIA pentru care mergi mai incet trei secunde:
## masina e latita, deci se tarie. Daca sare inapoi la forma normala in doua
## zecimi si tu ramai lent, penalizarea devine invizibila si se citeste ca bug.
##
## `invert_steer` (implicit false) inverseaza directia (stanga <-> dreapta) cat
## tine strivirea (`seconds`). Il activeaza doar bolovanul din culoarul E.
func crush(seconds: float, factor: float, squash: Vector3,
		keep_speed: float, hold_squash: bool = false,
		invert_steer: bool = false) -> void:
	if invert_steer and seconds > 0.0:
		steer_invert_left = maxf(steer_invert_left, seconds)
		steer_inverted.emit(seconds)
	crush_time = maxf(crush_time, seconds)
	crush_factor = minf(crush_factor, factor)
	velocity.x *= keep_speed
	velocity.z *= keep_speed
	is_boosting = false
	_forced_boost = 0.0
	if hold_squash:
		_hold_squash(squash, seconds)
	else:
		_punch_scale(squash)
	crushed.emit(self, 1.0 - factor)


## Ars de lava (Stromboli): "contact = distrugere" din brief, tradus in
## limbajul jocului — pedeapsa e TIMP, nu o stare de distrus (vezi nota de la
## `crush_time`). Turtire + shake plin (semnalul `crushed` la severitate 1),
## apoi repunere DIN STAND: spre deosebire de repunerea obisnuita, nu primesti
## avansul de 9 m/s — repornirea de la zero E costul (brief §3: ~2 s + ~2
## pozitii). Cooldown-ul repunerii taie contactele repetate din acelasi tick.
func scorch() -> void:
	if _respawn_cooldown > 0.0 or track == null or finished:
		return
	crush(0.0, 1.0, Vector3(1.4, 0.35, 1.3), 0.0)
	if is_player:
		AudioManager.play_sfx(&"avalanche_hit", 1.15)
	respawn(12.0)
	velocity = Vector3.ZERO
	_prev_velocity = velocity


## Aprinsa de o coloana de foc (gheizerele din crater, [FireballGeyser]).
##
## NU e `scorch()`: arderea de lava te repune din stand, si craterul n-are
## nevoie de a doua pedeapsa identica cu limba de lava. Aici ramai in cursa si
## PLATESTI ALTFEL:
##
##   - flacari pe capota, `seconds` de zile — la chase cam ele urca prin
##     dreptul parbrizului si iti mananca partea de sus a ecranului, adica
##     exact banda in care vezi urmatorul gheizer. Pedeapsa e INFORMATIONALA;
##   - plafonul de viteza taiat cu `factor` (imprumuta `crush_factor`, ca sa
##     existe UN singur loc care taie viteza — vezi `_current_max_speed`);
##   - bara de turbo GOLITA, si nu se mai incarca pana nu se stinge focul
##     (vezi `_update_turbo`). Focul consuma combustibilul: tematic, si
##     loveste exact resursa care e centrul designului.
##
## Nu turteste caroseria: turtirea e limbajul loviturilor de MASA (bolovan,
## tren, aripa de moara). O coloana de gaz care te arde si te arunca nu te
## indoaie, si daca ar folosi acelasi vocabular n-ai mai putea citi din
## silueta masinii ce ai patit.
func ignite(seconds: float, factor: float, keep_speed: float) -> void:
	burn_time = maxf(burn_time, seconds)
	# Prin `crush_time`, nu printr-un al doilea plafon: `_current_max_speed`
	# trebuie sa ramana cu O singura taietura de citit.
	crush_time = maxf(crush_time, seconds)
	crush_factor = minf(crush_factor, factor)
	velocity.x *= keep_speed
	velocity.z *= keep_speed
	is_boosting = false
	_forced_boost = 0.0
	turbo_charge = 0.0
	if is_player:
		AudioManager.play_sfx(&"avalanche_hit", 1.05)
	ignited.emit(self, seconds)
	# Semnalul de strivire ramane cel care zguduie camera (race.gd il asculta
	# deja). Severitate moderata: te-a lovit un jet, nu ti-a cazut muntele.
	crushed.emit(self, 0.55)


## Indiciul vizual al directiei inversate: un "<=>" galben care pulseaza
## deasupra masinii (billboard), vizibil pentru toti — si pentru jucator (chase
## cam), si pentru cine il depaseste. Un singur Label3D, creat la prima
## inversare si doar aratat/ascuns dupa aceea. Nu aduce niciun material nou
## (Label3D isi deseneaza propriul text), deci nu intra in numaratoarea de
## materiale a pistei.
var _invert_marker: Label3D = null

func _update_invert_marker() -> void:
	if steer_invert_left <= 0.0:
		if _invert_marker != null:
			_invert_marker.visible = false
		return
	if _invert_marker == null:
		_invert_marker = Label3D.new()
		_invert_marker.text = "<=>"
		_invert_marker.font_size = 72
		_invert_marker.pixel_size = 0.012
		_invert_marker.outline_size = 14
		_invert_marker.modulate = Color(1.0, 0.85, 0.15)
		_invert_marker.outline_modulate = Color(0.25, 0.1, 0.0)
		_invert_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_invert_marker.no_depth_test = true
		_invert_marker.top_level = false
		_invert_marker.position = Vector3(0.0, 2.3, 0.0)
		_invert_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_invert_marker)
	_invert_marker.visible = true
	var pulse := 1.0 + 0.2 * sin(float(Time.get_ticks_msec()) * 0.018)
	_invert_marker.scale = Vector3.ONE * pulse


## Cat din efectul unui hazard „de aruncare" (rotire, ridicare, impins, viteza
## taiata) primeste masina asta. 1.0 pentru tot ce e cel mult cat Muscle
## (135 = masina implicita a jucatorului, pe care s-au masurat contractele
## gimmick-urilor), mai putin pentru cele grele: Pompierii 0.68, Autobuzul
## 0.52. Doar REDUCE, nu amplifica: usoarele platesc deja prin contact (1/m in
## `_resolve_bump`), iar un hazard mai dur pe Politie ar muta contractele
## masurate. Pasul 0 din docs/cariera/mod_cariera.md, decizia (a). Hazardele
## din Kyoto (Gion, Shishimai, Shishi-odoshi, Daruma) si turma au deja
## raportul lor (referinta 100, clamp 0.4..1.4) si raman cum sunt.
func hazard_mass_ratio(reference_mass: float = 135.0) -> float:
	return clampf(reference_mass / maxf(mass, 1.0), 0.4, 1.0)


func apply_sweep(push: Vector3) -> void:
	velocity += push


## Am intrat intr-o masa de apa: doar semnalul (shake + orice mai asculta).
## Efectele pe fizica le aplica hazardul, ca sa ramana toate intr-un loc.
func splash(strength: float) -> void:
	splashed.emit(self, strength)


## Uda masina pentru `seconds` (Fiordland: cascada Stirling / torentul).
##
## Nu inventeaza un nou emitator: refoloseste `_water_spray` (aceeasi panza de
## stropi care iese de la rotile din fata cand esti IN apa) — o cascada te lasa
## ud, nu iti creeaza o a doua sursa de apa. `_update_water` tine emisia vie
## cat `_douse_left > 0`, INDIFERENT de `in_water` (esti pe asfalt uscat dupa
## cascada, dar tot picuri). Se poate reinnoi: o a doua trecere prin perdea
## inainte sa se stinga prima intinde efectul, nu il reseteaza la zero.
var _douse_left: float = 0.0
func douse(seconds: float) -> void:
	_douse_left = maxf(_douse_left, seconds)

## Invarte caroseria in jurul verticalei, `duration` secunde. DOAR VIZUAL.
##
## Colizorul si directia de mers raman ale masinii, si asta e deliberat: o
## rotatie reala a lui `basis` in aer ar insemna ca aterizezi cu botul in alta
## parte decat merge viteza, adica un tete-a-queue pe care jucatorul nu l-a cerut
## si nu l-a putut evita. Tromba (`TyphoonHazard`) trebuie sa te SPERIE cat esti
## in aer, nu sa-ti schimbe traiectoria pe ascuns.
##
## Se stinge singura: cine o porneste n-are nimic de curatat, deci nici o
## repunere sau un abandon la mijlocul zborului nu lasa masina invartindu-se.
func spin_body(rate_rad_s: float, duration: float) -> void:
	_spin_rate = rate_rad_s
	_spin_left = duration


## Sabotaj de control: masina e ROTITA REAL in jurul verticalei cu
## `rate_rad_s`, timp de `seconds` (vartejul de praf: PI / 0,8 s). Spre
## deosebire de spin_body, aici se schimba chiar orientarea: viteza isi
## pastreaza directia din lume, deci dupa 180° mergi cu spatele si trebuie
## sa te aduni singur. Nu se aduna peste un sabotaj in curs — il inlocuieste.
func apply_yaw_kick(rate_rad_s: float, seconds: float) -> void:
	_yaw_kick = rate_rad_s
	_yaw_kick_left = maxf(seconds, 0.0)


## Aruncat in aer de o creasta de fly-off. SETAM velocity.y, nu adunam: pe sol
## el e mereu readus la ~0 de move_and_slide, deci o adunare s-ar pierde.
func launch(up_speed: float) -> void:
	if velocity.y >= up_speed:
		return
	velocity.y = up_speed
	_punch_scale(Vector3(0.9, 1.18, 0.92)) # intinsa pe verticala la desprindere

# Imbrancelile, peretii si popicele: vezi _process_contacts — solverul imparte
# impulsul dupa masa, regulile arcade (plafon, rotatie, slip, semnal) se aplica
# peste bilantul lui.

func _detect_landing() -> void:
	if is_on_floor() and not _was_on_floor:
		_relocate_level()
		if _prev_velocity.y < -6.0:
			landed.emit(self, -_prev_velocity.y)
			_punch_scale(Vector3(1.15, 0.8, 1.15))
			# Sunetul aterizarii (volum/pitch dupa viteza de cadere) il da ImpactSound,
			# pe semnalul `landed` de mai sus.
			# Aterizare de la inaltime: soferul sare din scaun, drept in sus si
			# putin inainte (masina se opreste brusc pe verticala, el nu).
			if -_prev_velocity.y >= eject_land_speed:
				var fwd_v := Vector3(_prev_velocity.x, 0.0, _prev_velocity.z) * 0.5
				_eject(fwd_v + Vector3.UP * minf(-_prev_velocity.y * 0.35, 12.0),
					"aterizare", -_prev_velocity.y)
	_was_on_floor = is_on_floor()

# ------------------------------------------------------------------ ejectare

## Soferul zboara din masina. `fling` = viteza initiala a figurinei (lume).
##
## Ragdoll-ul se pune in PARINTELE masinii (lumea cursei), nu sub masina:
## masina se va teleporta la repunere, iar figurina trebuie sa ramana unde a
## cazut. Nu se ciocneste cu nicio masina (grupul "cars") — vezi ToyRagdoll.
## Tacut cand nu are ce arunca: caroserie inchisa, deja aruncat, cursa
## terminata sau masina scoasa din cursa de un hazard (`race_active`).
func _eject(fling: Vector3, cause: String = "", value: float = 0.0) -> void:
	if not eject_enabled or _driver == null or is_ejected or finished \
			or not race_active or get_parent() == null:
		return
	var ragdoll := _driver.eject(fling, get_tree().get_nodes_in_group(&"cars"))
	if ragdoll == null:
		return
	last_eject_cause = cause
	last_eject_value = value
	get_parent().add_child(ragdoll)
	is_ejected = true
	_eject_left = eject_hold
	is_drifting = false
	drift_blend = 0.0
	is_boosting = false
	_forced_boost = 0.0
	ejected.emit(self, ragdoll)


## Numaratoarea fara sofer; la capat, repunerea (care il si reaseaza). Fara
## pista (sonde) nu exista repunere, deci soferul se intoarce pur si simplu.
func _tick_eject(delta: float) -> void:
	_eject_left -= delta
	if _eject_left > 0.0:
		return
	_eject_left = 0.0
	if track != null and not finished:
		_respawn_cooldown = 0.0 # aruncarea a costat deja; repunerea nu asteapta
		respawn(eject_backoff)
	else:
		_reseat_driver()


func _reseat_driver() -> void:
	is_ejected = false
	_eject_left = 0.0
	if _driver != null:
		_driver.reseat()


## Repunere CU TRANZITIE (#495): in loc de teleport instant, masina clipeste
## `RECOVER_S` secunde fara comenzi (fizica curge — rasturnata ramane
## rasturnata, cazand continua sa cada), apoi `respawn(backoff_m)`.
## Pentru repunerile pe care le vede jucatorul ca urmare a unei greseli:
## butonul, masina rasturnata sau impotmolita. Hazardele care au propria
## punere in scena (tren, avalansa, plasa de sub faleza) raman pe `respawn`.
func recover(backoff_m: float = 14.0) -> void:
	if not can_respawn() or _eject_left > 0.0:
		return
	_recover_left = RECOVER_S
	_recover_backoff = backoff_m
	is_drifting = false
	is_boosting = false
	recovery_started.emit(self, RECOVER_S)


## In tranzitie (pentru Race: nu porni a doua oara aceeasi repunere).
func is_recovering() -> bool:
	return _recover_left > 0.0


func _tick_recover(delta: float) -> void:
	_recover_left -= delta
	if _visual != null:
		_visual.visible = fmod(_recover_left * RECOVER_BLINK_HZ, 1.0) > 0.35
	if _recover_left > 0.0:
		return
	_recover_left = 0.0
	if _visual != null:
		_visual.visible = true
	_respawn_cooldown = 0.0 # tranzitia a fost asteptarea; repunerea nu mai asteapta
	respawn(_recover_backoff)


func driver_seated() -> bool:
	return _driver != null and _driver.is_seated()

## La aterizare pe ALT etaj, indexul se recauta pe toata ruta — o data.
##
## Cautarea de index e locala (~72 m de-a lungul rutei), si asa trebuie sa
## ramana: e anti-cut-ul jocului. Dar pe o pista care trece peste ea insasi,
## o cadere de pe tablier pe drumul de jos (sau un salt proiectat de pe un
## etaj pe altul) te lasa la sute de metri de ruta fata de indexul tinut —
## fereastra nu-l vede niciodata si fractia de tur ingheata. Acelasi
## mecanism ca la comutarea rutelor (Track.resolve_route scaneaza global o
## data per comutare), extins la etaje. Scanarea e 3D, deci alege etajul pe
## care ai aterizat, nu pe cel de deasupra.
func _relocate_level() -> void:
	if track == null:
		return
	var r: TrackRoute = track.route_at(route)
	if r == null or not r.is_other_level(road_index, global_position):
		return
	road_index = track.closest_index_global(global_position, route)

# ------------------------------------------------------------------ restul

## Repunere pe pista dupa o aterizare ratata (sau orice iesire din lume): pe
## ultimul checkpoint valid, retrasa cu `backoff_m` metri ca sa aiba spatiu de
## elan. Nu pe grila de start — repornirea cursei de la zero ar fi o pedeapsa
## absurda pentru o saritura ratata.
## Are rost sa apesi butonul de repunere acum?
##
## respawn() iese in tacere cand nu poate (fara pista, in cooldown, dupa
## terminare). Butonul trebuie sa arate asta, nu sa para stricat.
func can_respawn() -> bool:
	return track != null and _respawn_cooldown <= 0.0 and not finished \
		and _recover_left <= 0.0


## Daca masina sta in afara unei benzi deschise (fara poarta) si in afara soselei,
## la cel mult `BRANCH_FLANK_M` de axa benzii, intoarce (ruta, index) de repunere pe
## banda; altfel (0, 0). Vezi comentariul din `respawn`.
const BRANCH_FLANK_M: float = 16.0

func _branch_flank_trap() -> Vector2i:
	if track == null or track.routes.size() < 2:
		return Vector2i.ZERO
	var main_i := track.closest_index_global(global_position, 0)
	if track.is_on_road(main_i, global_position, 0):
		return Vector2i.ZERO
	for bi in range(1, track.routes.size()):
		var br := track.route_at(bi)
		if br == null or br.baked.is_empty() or not track.branch_is_open(bi):
			continue
		if track.branch_gate(bi) != null:
			continue
		var bidx := br.closest_index_global(global_position)
		if bidx == 0 or br.is_other_level(bidx, global_position):
			continue
		var lat := br.lateral_distance(bidx, global_position)
		if lat > br.half_width and lat < BRANCH_FLANK_M:
			return Vector2i(bi, bidx)
	return Vector2i.ZERO


## Cat se mai retrage repunerea, pas cu pas, cand locul de pe axa nu e liber.
const RESPAWN_RETRY_M: float = 4.0
const RESPAWN_RETRY_STEPS: int = 15

## Punctul de repunere de pe axa drumului, retras pana gaseste un loc LIBER.
##
## Axa e mereu pe carosabil si cu botul pe sensul de mers (ProbeRespawnRoad,
## #494: 0 din 1971 de puncte in afara drumului sau deviate). Ce lipsea era
## intrebarea „ce e ACOLO": 28 din 1971 de puncte cadeau in rampa unui kicker,
## peste golul unei sarituri sau al podului mobil, ori intr-un hazard. Repusa
## acolo, masina era aruncata de solver sau cadea din nou. Se cauta inapoi pe
## traseu (mai mult elan, aceeasi ruta) din RESPAWN_RETRY_M in RESPAWN_RETRY_M
## metri; daca nimic nu e liber, ramane primul punct — comportamentul vechi.
##
## Pe o BANDA (ruta deschisa), retragerea se oprea la capatul ei: indexul se
## taie la 0, deci orice retragere mai lunga decat drumul parcurs pe banda
## dadea acelasi punct — furca, cu roata pe muchia terenului (pe Stromboli,
## (-226, 23, 437), unde ProbeRace arata repuneri repetate). Restul retragerii
## continua pe bucla principala, inaintea furcii; atunci si `last_safe_*`
## trec pe bucla, ca `respawn` sa puna masina pe ruta pe care chiar sta.
func _clear_recovery_transform(backoff_m: float) -> Transform3D:
	var first := Transform3D()
	for k in RESPAWN_RETRY_STEPS:
		var back := backoff_m + RESPAWN_RETRY_M * float(k)
		var route_i := last_safe_route
		var index := last_safe_index
		if route_i != 0:
			var br := track.route_at(route_i)
			var along := 0.0
			if br != null and not br.dists.is_empty():
				along = br.dists[clampi(index, 0, br.dists.size() - 1)]
			if br != null and not br.baked.is_empty() and back > along:
				index = track.closest_index_global(br.baked[0], 0)
				route_i = 0
				back -= along
		var t := track.recovery_transform(index, back, route_i)
		if k == 0:
			first = t
		if _respawn_spot_clear(t):
			if route_i != last_safe_route:
				last_safe_route = route_i
				last_safe_index = index
			return t
	return first


## Locul e bun daca toate cele patru roti au sol sub ele, la cel mult 3 m (nu
## golul unei sarituri), si daca nimic nu intra in gabaritul caroseriei — cu
## 0,4 m de joc lateral si 0,5 m in fata/spate — de la 0,4 m peste sol in sus.
## Sub 0,4 m e treaba rotilor (borduri, dale); peste, e rampa sau perete.
func _respawn_spot_clear(t: Transform3D) -> bool:
	var space := get_world_3d().direct_space_state
	var box := _collision_shape.shape as BoxShape3D if _collision_shape != null \
		else null
	var size := box.size if box != null else Vector3(2.0, 1.0, 3.8)
	var exclude: Array[RID] = [get_rid()]
	var ground_y := INF
	# Patru roti + centrul: podul basculant are golul CHIAR la mijloc, intre
	# cele doua jumatati, cu rotile pe buzele lor.
	var spots: Array[Vector2] = [Vector2(-0.45, -0.45), Vector2(0.45, -0.45),
		Vector2(-0.45, 0.45), Vector2(0.45, 0.45), Vector2.ZERO]
	for s in spots:
		var top: Vector3 = t * Vector3(size.x * s.x, 1.0, size.z * s.y)
		var q := PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 4.2)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return false
		# Solul trebuie sa fie la cota DRUMULUI (axa e cu 1,2 m sub origine):
		# tablierul ridicat al podului mobil e „sol" pentru raza, dar e
		# deasupra drumului, iar golul de sub el e tot gol.
		var hy := (hit.position as Vector3).y
		var road_y := t.origin.y - 1.2
		if hy > road_y + 0.6 or hy < road_y - 2.0:
			return false
		ground_y = minf(ground_y, hy)
	var top_y := t.origin.y + 1.25
	var bottom_y := ground_y + 0.4
	if top_y <= bottom_y:
		return true
	var probe := BoxShape3D.new()
	probe.size = Vector3(size.x + 0.8, top_y - bottom_y, size.z + 1.0)
	var sq := PhysicsShapeQueryParameters3D.new()
	sq.shape = probe
	sq.exclude = exclude
	var center := t.origin
	center.y = (top_y + bottom_y) * 0.5
	sq.transform = Transform3D(t.basis, center)
	return space.intersect_shape(sq, 1).is_empty()


func respawn(backoff_m: float = 14.0) -> void:
	if track == null or _respawn_cooldown > 0.0:
		return
	_respawn_cooldown = 1.5
	# Nu inapoi pe o banda INCHISA: blocata in vaca culcata, masina ar fi
	# repusa tot pe ulicioara, in spatele vacii, si s-ar bloca iar — bucla
	# masurata pe Track17. Se repune pe bucla, inaintea furcii.
	if last_safe_route != 0 and not track.branch_is_open(last_safe_route):
		var br := track.route_at(last_safe_route)
		if br != null and not br.baked.is_empty():
			last_safe_index = track.closest_index_global(br.baked[0], 0)
		last_safe_route = 0
	# Nici intre furca si poarta ingustata a benzii (`AlleyGate`): repusa acolo
	# (cu 15 m pana la poarta si botul deviat), masina lovea iar stalpul —
	# bucla masurata pe Track17 (ejectare -> repunere la 0,348 -> ejectare).
	# Se repune pe bucla, inaintea furcii. Pistele fara AlleyGate: neatinse.
	if last_safe_route != 0:
		var gate := track.branch_gate(last_safe_route)
		var gbr := track.route_at(last_safe_route)
		if gate != null and gbr != null and not gbr.baked.is_empty():
			var sd: float = gbr.dists[clampi(last_safe_index, 0, gbr.dists.size() - 1)]
			if sd < float(gate.gate_dist_m) + 3.0:
				last_safe_index = track.closest_index_global(gbr.baked[0], 0)
				last_safe_route = 0
	# Prinsa PE FLANCUL DE AFARA al unei benzi (peretele palniei tunelului de torii,
	# Kyoto E'): masina sta intre sosea si peretele benzii, pe cota terenului, fara
	# niciun checkpoint luat pe banda (`last_safe_route` ramane 0, la furca). Repusa
	# la furca, aceeasi apropiere (viteza de dupa repunere + coltul taiat spre gura)
	# o ducea iar pe flanc: 7 repuneri la rand la ~0,49 pe ProbeRace
	# `--track=11 --seed=5`, ~15 s una. Se repune pe AXA benzii, la 14 m in urma
	# locului unde a ramas — in palnie, nu in fata ei. Banda inchisa si banda cu
	# poarta ingustata au regulile lor, mai sus; pistele fara banda: neatinse.
	var trap := _branch_flank_trap()
	if trap.x != 0:
		last_safe_route = trap.x
		last_safe_index = trap.y
	global_transform = _clear_recovery_transform(backoff_m)
	# Un pic de viteza, nu oprire pe loc: pornirea din zero in mijlocul unei
	# curse e mai frustranta decat saritura ratata.
	velocity = -global_transform.basis.z * 9.0
	# Teleportare de corp rigid: si rotatia, si reperele bilantului de bump se
	# reseteaza — altfel saltul de pozitie ar citi ca "izbitura" (dv urias) si
	# ar declansa plafonari si semnale fantoma in primul tick de dupa.
	angular_velocity = Vector3.ZERO
	_prev_velocity = velocity
	_commanded_yaw = 0.0
	_yaw_cmd = 0.0
	is_drifting = false
	drift_blend = 0.0
	_drift_visual_yaw = 0.0
	_snap_left = 0.0
	is_boosting = false
	_spin_left = 0.0 # repusa pe sosea, nu mai e in tromba
	_douse_left = 0.0 # repus = uscat, nu mai picura
	_yaw_kick_left = 0.0 # si nici in vartej
	_yaw_kick = 0.0
	burn_time = 0.0 # repusa pe sosea, nu mai arde
	_forced_boost = 0.0
	slip_time = 0.0
	crush_time = 0.0
	crush_factor = 1.0
	steer_invert_left = 0.0 # repusa pe sosea, directia revine la normal
	# Si turtirea care tinea cat incetinirea: repusa pe sosea, masina apare
	# intreaga. Fara asta ar rasari latita si ar ramane asa pana expira tween-ul.
	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()
	if _visual != null:
		_visual.scale = Vector3.ONE
		_visual.visible = true # o tranzitie intrerupta de alta repunere nu lasa masina stinsa
	_recover_left = 0.0
	_bump_pairs.clear() # am fost teleportati; vechile contacte nu mai exista
	_impact_yaw = 0.0 # nici rotatia din ultima izbitura nu ne urmareste
	_was_on_floor = true # fara "aterizare" falsa (shake + bufnet) la repunere
	in_water = false # repusa pe uscat; urmatoarea intrare in apa e o intrare
	_reseat_driver() # soferul reapare pe scaun, oricare ar fi fost motivul repunerii
	route = last_safe_route
	road_index = track.closest_index_global(global_position, route)
	last_safe_index = road_index
	respawned.emit(self)

# ------------------------------------------------------------------- apa

## Sub viteza asta rotile nu mai arunca apa: o masina oprita in vad nu stropeste.
const WATER_SPRAY_MIN_SPEED: float = 3.5
## Durata implicita a lui `douse()` (s) — cat picura masina dupa cascada/
## torent. Folosita si ca referinta pentru estomparea `amount_ratio` (vezi
## `_update_water`): la `_douse_left == DOUSE_FADE_S` (chiar la iesire din
## perdea) picuratul e plin, si se subtiaza spre pragul minim pana se stinge.
const DOUSE_FADE_S: float = 3.0

## Apa de sub roti, o data pe tick. Intrarea (fals -> adevarat) da stropul,
## inelul de unde, semnalul `splashed` si sunetul; cat timp esti in apa si te
## misti, rotile din fata arunca spray.
##
## „In apa" = cota rotilor sub luciu. Luciul il stie pista
## (Track.water_level_at); cota rotilor e contactul cel mai de jos din tick
## (`_road_wheel_y`, pus de suspensie). In AER — cand cazi in parau sau in
## mare — se ia fundul rotii sub caroserie, ca stropul sa apara la ATINGEREA
## apei, nu abia pe fundul albiei, unde te asteapta RespawnZone-ul si te
## teleporteaza inainte sa se vada ceva.
func _update_water(delta: float) -> void:
	if track == null or _water_burst == null:
		return
	if not _water_color_ready:
		_water_color_ready = true
		var c := track.water_splash_color(global_position)
		_water_spray.color = c
		_water_burst.color = c
		if _ring_material != null:
			_ring_material.albedo_color = c
	var level := track.water_level_at(global_position)
	var was := in_water
	if level == -INF:
		in_water = false
	else:
		var wheel_y := _road_wheel_y if _road_wheel_y < INF \
			else global_position.y - suspension_rest - _susp_wheel_radius
		in_water = wheel_y < level - 0.02
	if in_water and not was:
		_enter_water(level)
	# Uda de cascada/torent (Fiordland): decade LINIAR, nu e o poarta on/off —
	# altfel ai iesi din perdea si te-ai usca instantaneu, in loc sa se vada
	# ca apa se scurge cateva secunde. Nu are legatura cu `in_water`: dupa
	# Stirling esti pe asfalt uscat, dar tot picuri.
	if _douse_left > 0.0:
		_douse_left = maxf(_douse_left - delta, 0.0)
	var doused := _douse_left > 0.0
	var wading := in_water and horizontal_speed() > WATER_SPRAY_MIN_SPEED
	var live := wading or doused
	_water_spray.emitting = live
	if live:
		# Stropii pleaca CU masina, nu raman pe loc: la 27 m/s, un strop
		# aruncat doar in sus ramane in urma si trece de camera in 0.3 s —
		# prima sonda n-a vazut niciun spray desi emitatorul mergea. Deci
		# viteza initiala poarta jumatate din viteza de mers, inainte (-Z e
		# fata), plus saltul in sus; de acolo cad singuri sub gravitatie.
		var hs := horizontal_speed()
		var dir := Vector3(0.0, 4.5, -hs * 0.5)
		var v := dir.length()
		_water_spray.direction = dir / v
		_water_spray.initial_velocity_min = v * 0.8
		_water_spray.initial_velocity_max = v * 1.2
		if doused and not in_water:
			# Picurat, nu spray de val: cade aproape vertical de pe caroserie
			# in loc sa tasneasca de sub roata. `CPUParticles3D` n-are
			# `amount_ratio` (aia e doar pe `GPUParticles3D` — descoperit prin
			# eroare de scena la sonda), deci "mai putina apa" cu cat trece
			# timpul vine din `speed_scale`: sistemul incetineste treptat spre
			# 0, deci se vad tot mai putine picaturi noi pornind, fara sa
			# atingem `amount` (schimbat live pe CPUParticles3D, e nesigur —
			# vezi documentatia clasei).
			_water_spray.initial_velocity_min = 0.4
			_water_spray.initial_velocity_max = 1.4
			_water_spray.direction = Vector3(0.0, -1.0, -0.1)
			_water_spray.speed_scale = clampf(_douse_left / DOUSE_FADE_S, 0.1, 1.0)
		else:
			_water_spray.speed_scale = 1.0
	# PRIN apa, nu PE apa (verdictul dezvoltatorului dupa #382: „masina pare
	# ca merge pe apa"). Cota era corecta; lipsea INTERACTIUNEA — apa nu
	# raspundea deloc la masina. Trei lucruri, toate legate de viteza:
	#   1. siajul: panza de spuma sub si in spatele masinii, la nivelul
	#      luciului, care curge spre spate — continua, nu rara ca stropii;
	#   2. frana apei: apa pana la butuc ia din viteza (mult sub valul de pe
	#      dig, 1.4/s, care e o pedeapsa; aici e o senzatie);
	#   3. un tremur de camera cat timp esti in apa cu viteza, ca la val.
	# Dara e pe OGLINDA apei: doar cand chiar esti in apa. Udat de cascada pe
	# asfalt, `level` e -INF si dara ar primi cota -inf (NaN in randare).
	_update_wake(level, wading)
	if in_water and is_on_floor():
		var keep := 1.0 - clampf(WATER_DRAG_PER_SEC * delta, 0.0, 0.5)
		linear_velocity.x *= keep
		linear_velocity.z *= keep
		if horizontal_speed() > 8.0:
			_water_rumble += delta
			if _water_rumble >= WATER_RUMBLE_EVERY:
				_water_rumble = 0.0
				splash(WATER_RUMBLE)
	else:
		_water_rumble = 0.0


## Cat din viteza ia apa pe secunda, cat esti cu rotile in ea.
const WATER_DRAG_PER_SEC: float = 0.55
## Tremurul de fond prin apa: mic si des (trauma^2, deci abia se simte), ca la
## WaveSurge.SPLASH_RUMBLE dar mai bland — vadul e traseu, nu hazard.
const WATER_RUMBLE: float = 0.15
const WATER_RUMBLE_EVERY: float = 0.15


## Siajul: se aseaza PLAT la nivelul luciului (nu urmeaza ruliul masinii),
## cu botul la bara din fata si coada in urma; lungimea si spuma cresc cu
## viteza. Stins cand nu esti in apa.
func _update_wake(level: float, live: bool) -> void:
	if _water_wake == null:
		if not live:
			return
		_build_wake()
	_water_wake.visible = live
	if not live:
		return
	var hs := horizontal_speed()
	var k := clampf(hs / maxf(max_speed, 1.0), 0.0, 1.0)
	var bw := data.body_width if data != null else 1.8
	var bl := data.body_length if data != null else 3.8
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	if fwd.length_squared() < 1e-4:
		return
	fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP)
	var bow := Vector3(global_position.x, level + 0.05, global_position.z) 		+ fwd * (bl * 0.5 + 0.4)
	var length := lerpf(4.0, 11.0, k)
	# Baza: X = dreapta (latimea), Z = spre SPATE (coada), Y sus.
	var basis := Basis(right * (bw * 0.85), Vector3.UP, -fwd * length)
	_water_wake.global_transform = Transform3D(basis, bow)
	_water_wake.set_instance_shader_parameter(&"strength", lerpf(0.45, 1.0, k))


func _build_wake() -> void:
	if _wake_mesh == null:
		_wake_mesh = _build_wake_mesh()
	if _wake_material == null:
		_wake_material = ShaderMaterial.new()
		_wake_material.shader = load("res://assets/shaders/water_wake.gdshader") as Shader
		_wake_material.set_shader_parameter("ripple_tex", load(Palette.DETAIL_PATH))
	_water_wake = MeshInstance3D.new()
	_water_wake.name = "WaterWake"
	_water_wake.mesh = _wake_mesh
	_water_wake.material_override = _wake_material
	_water_wake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_water_wake.top_level = true # transformul e pus in lume, nu fata de masina
	add_child(_water_wake)
	var c := _water_burst.color
	_water_wake.set_instance_shader_parameter(&"foam_col", Vector3(c.r, c.g, c.b))


## V-ul siajului in unitati: X in -1..1 (latimea la coada), Z in 0..1 (bot ->
## coada), bot pe jumatate din latime. UV.x = lungimea, UV.y = latimea in
## -1..1 — shaderul deseneaza spuma dupa ele. 6 x 4 quad-uri = 48 triunghiuri.
static func _build_wake_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const NZ := 6
	const NX := 4
	for iz in NZ:
		for ix in NX:
			var quad: Array[Vector3] = []
			var uvs: Array[Vector2] = []
			for corner: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
				var tz := (float(iz) + corner.y) / float(NZ)
				var tx := (float(ix) + corner.x) / float(NX) * 2.0 - 1.0
				var half := lerpf(0.55, 1.0, tz)
				quad.append(Vector3(tx * half, 0.0, tz))
				uvs.append(Vector2(tz, tx))
			for k: int in [0, 1, 2, 1, 3, 2]:
				st.set_uv(uvs[k])
				st.set_normal(Vector3.UP)
				st.add_vertex(quad[k])
	return st.commit()


## Am intrat in apa: strop la nivelul LUCIULUI (nu la masina, care poate fi
## deja pe jumatate sub el), inel de unde, zguduitura si sunet.
##
## Energia intrarii decide totul: caderea in parau (10-15 m/s pe verticala) e
## un plesnet, vadul luat la 20 m/s e o brazda, iar la pas nu e nici un strop.
func _enter_water(level: float) -> void:
	var fall := maxf(-velocity.y, 0.0)
	var run := horizontal_speed()
	var energy := clampf((fall * 1.3 + run * 0.45) / 16.0, 0.0, 1.0)
	if energy < 0.05:
		return
	var at := Vector3(global_position.x, level + 0.05, global_position.z)
	_water_burst.global_position = at
	_water_burst.initial_velocity_min = lerpf(1.5, 5.0, energy)
	_water_burst.initial_velocity_max = lerpf(3.5, 11.0, energy)
	if data != null:
		_water_burst.emission_box_extents = Vector3(
			data.body_width * 0.5, 0.05, data.body_length * 0.5)
	_water_burst.restart()
	_spawn_ring(at, energy)
	# Aceeasi cale ca valul de pe dig (WaveSurge): semnalul zguduie camera
	# jucatorului, ascultatorii isi iau ce vor.
	splash(lerpf(0.1, 0.55, energy))
	if is_player:
		AudioManager.play_sfx(&"splash", lerpf(1.2, 0.85, energy))


## Inelul de unde de pe luciu: un disc plat care creste si se stinge intr-o
## secunda. Un singur mesh pentru toate masinile; materialul e al masinii
## (culoarea apei temei). Parintele e cel al urmelor (lumea), nu masina —
## inelul ramane unde ai intrat, masina merge mai departe.
func _spawn_ring(at: Vector3, energy: float) -> void:
	var parent: Node = skid_parent if skid_parent != null else track
	if parent == null:
		return
	if _ring_mesh == null:
		_ring_mesh = _build_ring_mesh()
	if _ring_material == null:
		_ring_material = StandardMaterial3D.new()
		_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ring_material.vertex_color_use_as_albedo = true
		_ring_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_ring_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_ring_material.albedo_color = _water_burst.color
	var ring := MeshInstance3D.new()
	ring.mesh = _ring_mesh
	ring.material_override = _ring_material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ring)
	ring.global_position = at + Vector3.UP * 0.06
	var r0 := lerpf(1.0, 1.6, energy)
	var r1 := lerpf(3.2, 6.5, energy)
	ring.scale = Vector3(r0, 1.0, r0)
	var tw := ring.create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(r1, 1.0, r1), 1.1) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(ring, "transparency", 1.0, 1.1) \
		.set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(ring.queue_free)


## Inel plat (coroana circulara) cu alfa in vertex: 0 pe muchia interioara si
## pe cea exterioara, 1 la mijloc — deci un inel moale, fara textura.
## 20 de segmente x 2 fasii x 2 triunghiuri = 80 de triunghiuri.
static func _build_ring_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEGS := 20
	const RADII: Array[float] = [0.55, 0.78, 1.0]
	const ALPHA: Array[float] = [0.0, 0.85, 0.0]
	for i in SEGS:
		var a0 := TAU * float(i) / float(SEGS)
		var a1 := TAU * float(i + 1) / float(SEGS)
		for band in 2:
			var ri := RADII[band]
			var ro := RADII[band + 1]
			var ci := Color(1, 1, 1, ALPHA[band])
			var co := Color(1, 1, 1, ALPHA[band + 1])
			var p0 := Vector3(cos(a0) * ri, 0.0, sin(a0) * ri)
			var p1 := Vector3(cos(a1) * ri, 0.0, sin(a1) * ri)
			var p2 := Vector3(cos(a0) * ro, 0.0, sin(a0) * ro)
			var p3 := Vector3(cos(a1) * ro, 0.0, sin(a1) * ro)
			for v: Array in [[p0, ci], [p2, co], [p1, ci], [p1, ci], [p2, co], [p3, co]]:
				st.set_color(v[1])
				st.set_normal(Vector3.UP)
				st.add_vertex(v[0])
	return st.commit()


func horizontal_speed() -> float:
	return Vector3(velocity.x, 0.0, velocity.z).length()

## Jumatatile gabaritului colizerului caroseriei (m) — pentru cine trebuie sa
## stie daca masina incape intr-un prag (usa telecabinei).
func collider_half_length() -> float:
	var box := _collision_shape.shape as BoxShape3D if _collision_shape != null else null
	return box.size.z * 0.5 if box != null else 1.9

func collider_half_width() -> float:
	var box := _collision_shape.shape as BoxShape3D if _collision_shape != null else null
	return box.size.x * 0.5 if box != null else 1.1

## Squash & stretch: deformare scurta a caroseriei care "vinde" evenimentul.
func _punch_scale(target: Vector3) -> void:
	if _visual == null:
		return
	_visual.scale = target
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Turtire care RAMANE, apoi se dezumfla la loc. Vezi `crush(hold_squash)`.
##
## Tween-ul precedent se opreste explicit: doua tween-uri pe aceeasi proprietate
## se calca reciproc, iar cel vechi (revenire in 0.25 s) ar fi tras masina inapoi
## la forma normala chiar sub cel nou.
func _hold_squash(target: Vector3, seconds: float) -> void:
	if _visual == null:
		return
	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()
	# Turtirea intra repede (impactul e brusc), tine cat incetinirea, si abia la
	# final revine — cu BACK, ca sa arate a redresare elastica, nu a lift.
	_squash_tween = create_tween()
	_squash_tween.tween_property(_visual, "scale", target, 0.08) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_squash_tween.tween_interval(maxf(seconds - 0.5, 0.0))
	_squash_tween.tween_property(_visual, "scale", Vector3.ONE, 0.42) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_effects(delta: float) -> void:
	# Suprafata de sub roti, aflata O DATA pe cadru: raspunsul il cer si urmele
	# de drift, si praful, si dara de rulare.
	var on_road := track != null \
		and track.is_on_road(road_index, global_position)
	# Pe o banda SECUNDARA (scurtatura): nu e sosea, dar nici camp — e pamant
	# batatorit, deci praful ia culoarea EI (vezi _update_dust).
	var on_branch := track != null and route != 0 \
		and track.is_on_road(road_index, global_position, route)
	var loose := _on_loose_ground(on_road)
	_toy_loose = loose
	_update_slide(delta)
	_update_scrape_sparks()
	# Fumul si urmele urmeaza ALUNECAREA, nu butonul: handbrake-ul le aprinde
	# oricum (cu un minim), dar o alunecare mare fara handbrake (gheata, dupa
	# o lovitura, derapaj de coada) le aprinde si ea, iar franarea tare lasa
	# urma de blocare. Intensitatea vine din unghiul de derapaj si viteza.
	var mark := _skid_mark_strength(delta)
	if is_drifting or slide_amount >= SMOKE_FREE_SLIDE:
		_drift_particles.emitting = true
		_update_drift_smoke()
	else:
		_drift_particles.emitting = false
	if mark > 0.0:
		# Cauciuc ars doar pe suprafata TARE. Pe pamant derapajul se vede in dara
		# de rulare si in norul de praf; o pata neagra lucioasa acolo ar fi
		# asfaltul care se vede prin drum.
		if not loose:
			_drop_skid_marks(delta, mark)
	# Ding cand bara de turbo ajunge plina — stii fara sa te uiti in jos.
	if turbo_charge >= 1.0 and not _turbo_full_latch and is_player:
		_turbo_full_latch = true
		AudioManager.play_sfx(&"drift_level", 1.3)
	elif turbo_charge < 0.95:
		_turbo_full_latch = false
	_boost_particles.emitting = is_boosting
	# Focul se stinge SINGUR cand expira ceasul: nimeni nu are de curatat dupa
	# el, deci nici o repunere si nici un abandon nu lasa masina arzand.
	if _fire_particles != null:
		_fire_particles.emitting = burn_time > 0.0
	_update_dust(on_road, loose, on_branch)
	_update_soft_veg(delta)
	_drop_trail(delta, loose)
	_drop_leaf_wear(delta, on_road)
	# Motor cu trepte, derapaj dupa alunecare, suprafete, turbo, vant.
	_audio.tick(delta, on_road, loose)

## De la cat de mare e alunecarea fara handbrake pornesc fumul si urmele.
const SMOKE_FREE_SLIDE: float = 0.3
## Franare tare (m/s^2 decelerare) de la care roata blocata lasa urma.
const BRAKE_MARK_DECEL: float = 12.0

## „Cat de tare aluneca" (0..1) din unghiul de derapaj si viteza: 4 grade sunt
## zgomot, 40 de grade sunt plin; viteza mica taie la 30% (o alunecare la pas
## nu face nor). Pura, ca sa o poata masura o sonda.
static func slide_amount_for(slip_deg: float, speed: float) -> float:
	var a := smoothstep(4.0, 40.0, slip_deg)
	return clampf(a * clampf(speed / 20.0, 0.3, 1.0), 0.0, 1.0)


## Unghiul de derapaj si `slide_amount`, o data pe tick. Viteza e FATA DE SOL
## (ca restul fizicii): pe o platforma mobila nu aluneci doar pentru ca ea merge.
func _update_slide(delta: float) -> void:
	var rel := velocity - _ground_velocity
	rel.y = 0.0
	var sp := rel.length()
	var target := 0.0
	slip_angle_deg = 0.0
	if wheels_on_ground > 0 and sp > 3.0:
		var b := global_transform.basis
		var fwd := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
		var right := Vector3(b.x.x, 0.0, b.x.z).normalized()
		# Cu spatele inainte, „derapajul" e fata de coada: abs pe ambele.
		slip_angle_deg = rad_to_deg(atan2(absf(rel.dot(right)), absf(rel.dot(fwd))))
		target = slide_amount_for(slip_angle_deg, sp)
	slide_amount = lerpf(slide_amount, target, 1.0 - exp(-12.0 * minf(delta, 0.05)))


## Opacitatea urmei de cauciuc pe acest tick (0 = nu lasa). Handbrake: minim
## 0.3, urca cu alunecarea. Fara handbrake: doar o alunecare mare, sau franare
## tare cu masina inca in viteza (roata blocata).
func _skid_mark_strength(delta: float) -> float:
	if is_drifting:
		return lerpf(0.3, 1.0, slide_amount)
	if slide_amount >= SMOKE_FREE_SLIDE:
		return slide_amount * 0.85
	if brake_lamp and wheels_on_ground >= 3 and horizontal_speed() > 10.0:
		var fwd := -global_transform.basis.z
		var decel := (_prev_velocity - velocity).dot(fwd) / maxf(delta, 0.0001)
		if decel > BRAKE_MARK_DECEL:
			return clampf(0.35 + (decel - BRAKE_MARK_DECEL) * 0.02, 0.35, 0.6)
	return 0.0


## Urme de cauciuc: placute plate depuse sub rotile din spate cand aluneci;
## `strength` (0..1) le da opacitatea.
func _drop_skid_marks(delta: float, strength: float = 1.0) -> void:
	if skid_parent == null or not is_on_floor():
		return
	_skid_accum += horizontal_speed() * delta
	if _skid_accum < 1.1:
		return
	_skid_accum = 0.0
	if _skid_mesh == null:
		_skid_mesh = PlaneMesh.new()
		# Scalat cu masinile (factor 0.84): urma trebuie sa aiba latimea anvelopei.
		_skid_mesh.size = Vector2(0.34, 0.85)
		_skid_mat = StandardMaterial3D.new()
		# 0.4 alpha pe asfaltul nostru inchis abia se vedea (ProbeFx). 0.6 se
		# citeste clar si de la camera de joc, si dupa ce iesi din viraj.
		_skid_mat.albedo_color = Color(0.05, 0.05, 0.05, 0.6)
		_skid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_skid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_skid_mesh.material = _skid_mat
	var half_track_w := data.body_width * 0.38 if data != null else 0.85
	var rear_z := data.body_length * 0.34 if data != null else 1.3
	for side in [-1.0, 1.0]:
		var mark := MeshInstance3D.new()
		mark.mesh = _skid_mesh
		skid_parent.add_child(mark)
		mark.global_position = global_position \
			+ global_transform.basis.x * half_track_w * side \
			+ global_transform.basis.z * rear_z + Vector3.UP * 0.06
		mark.rotation.y = rotation.y
		# Intensitatea e opacitatea URMEI (transparenta de instanta peste cea a
		# materialului comun): derapaj usor = dara palida, plin = neagra.
		mark.transparency = 1.0 - clampf(strength, 0.15, 1.0)
		var tw := mark.create_tween()
		# Urma traieste destul cat sa o REVEZI: la un tur de ~55 s, 8 s inseamna
		# ca inca vezi urmele virajului cand privesti in urma, dar turul urmator
		# gaseste asfalt curat.
		tw.tween_interval(6.5)
		tw.tween_property(mark, "transparency", 1.0, 2.0)
		tw.tween_callback(mark.queue_free)
	# Limita de "juice": stergem urmele cele mai vechi.
	while skid_parent.get_child_count() > 160:
		skid_parent.get_child(0).free()

## Praful se ridica doar cand chiar zgarii solul: roti pe teren afanat si cu
## viteza. Fara pragul de viteza, o masina oprita pe nisip ar fumega la
## nesfarsit — si aia e fix imaginea care strica iluzia in loc s-o construiasca.
const DUST_MIN_SPEED: float = 6.0

## Solul de sub roti e AFANAT — nisip, pamant? De asta atarna si praful, si
## urmele lasate rulind.
##
## Pe majoritatea pistelor raspunsul e "doar in afara soselei": asfaltul e tare,
## marginea nu. Pe o pista cu drum de pamant (Track.road_surface) raspunsul e
## "peste tot", si asta e chiar rostul ei — nu mai exista panglica tare pe care
## sa te odihnesti, tot turul scoate praf.
func _on_loose_ground(on_road: bool) -> bool:
	if track == null or not is_on_floor():
		return false
	if not on_road:
		return true
	# Banda de GHEATA (Baikal) e sosea, dar nu e suprafata afanata: pe ea
	# derapajul lasa scrasnet de cauciuc (zgarieturi pe gheata), nu brazde de
	# zapada, si nu se ridica spulber. Fara verificarea asta, un drum "snow"
	# ar intinde brazdele albastrui si peste autostrada de gheata.
	if route == 0 and track.is_ice_at(track.frac_at(road_index)):
		return false
	return _road_loose_here()


## Soseaua de sub roti e drum afanat? Pe fractia curenta, nu pe toata pista: o
## bucla cu asfalt si portiuni de pamant (Track.is_dirt_at) are praf si urme doar
## pe pamant. Pe o scurtatura (route != 0) nu exista intervale, ramane
## raspunsul pistei. Pe o pista fara intervale e exact `road_is_loose()`.
func _road_loose_here() -> bool:
	if route == 0:
		return track.road_is_loose_at(track.frac_at(road_index))
	return track.road_is_loose()

## Culorile prafului, coapte o data cand masina afla pe ce pista e: una a
## terenului, una a soselei. Cat timp soseaua era asfalt exista o singura
## suprafata pe care se ridica praf, deci si o singura culoare.
var _dust_ground_color: Color = Color.BLACK
var _dust_road_color: Color = Color.BLACK
var _dust_colors_ready: bool = false
## Ce culoare e pusa ACUM pe particule: -1 niciuna, 0 teren, 1 sosea,
## 2 banda secundara (ruta curenta; se recalculeaza la schimbarea rutei).
var _dust_source: int = -1
var _dust_route: int = -1
## Roata e pe un interval de pamant al pistei (Track.is_dirt_at)? Doar ca sa
## stim cand sa recolorez fumul de drift la trecerea pamant <-> asfalt.
var _drift_on_dirt: bool = false

## Tufele: rafala de frunze la intrare si franare usoara cat rotile sunt
## in ea. Registrul (`SoftVegetation`) se citeste o data pe cursa, din chunk-urile
## de vegetatie ale pistei; fara ele (sau headless) depth e mereu 0.
func _update_soft_veg(delta: float) -> void:
	_veg_cooldown = maxf(_veg_cooldown - delta, 0.0)
	var root: Node3D = soft_veg_root if soft_veg_root != null else track
	if root == null or not race_active or wheels_on_ground == 0:
		_veg_depth = 0.0
		return
	if not SoftVegetation.is_scanned(root):
		SoftVegetation.scan(root)
	var speed := horizontal_speed()
	if speed < 2.0 or SoftVegetation.count(root) == 0:
		_veg_depth = 0.0
		return
	_veg_depth = SoftVegetation.depth_at(root, global_position)
	if _veg_depth <= 0.0:
		return
	var v := Vector3(velocity.x, 0.0, velocity.z)
	# Franare mica, pe directia de mers: nu schimba directia si nu atinge solverul.
	apply_central_force(-v.normalized() * bush_drag * _veg_depth * mass)
	if speed >= bush_burst_min_speed and _veg_cooldown <= 0.0:
		_veg_cooldown = 0.3
		var tint := Color(0.38, 0.56, 0.24)
		if track != null:
			tint = tint.lerp(track.theme_ground_tint, 0.25)
		PropDebris.leaf_burst(get_tree(), global_position + Vector3.UP * 0.4,
			v.normalized() * 0.5 + Vector3.UP,
			clampf(inverse_lerp(bush_burst_min_speed, 28.0, speed), 0.0, 1.0), tint)


## Fumul de cauciuc dupa alunecare (0..1): cate pufuri se vad, cat de opace si
## cat de mari. La 1 e fumul de dinainte; la alunecari mici e o adiere subtire.
## Handbrake-ul tine un minim, ca intrarea in drift sa se vada de la inceput.
func _update_drift_smoke() -> void:
	if _drift_density == null:
		return
	var s := slide_amount
	if is_drifting:
		s = maxf(s, 0.2)
	# Densitatea si opacitatea pe radacina: un drift obisnuit (20-30 de grade) sa
	# arate cam ca fumul de dinainte, iar 40 de grade sa-l intreaca; doar marimea
	# urmeaza liniar.
	var d := sqrt(s)
	_drift_density.set_offset(1, lerpf(0.3, 1.0, d)) # fractia care se vede
	_drift_density.set_color(0, Color(1, 1, 1, lerpf(0.55, 1.0, d))) # opacitatea
	var size := lerpf(0.9, 1.9, s)
	_drift_particles.scale_amount_min = 0.6 * size
	_drift_particles.scale_amount_max = 1.4 * size


## Culorile prafului se coc o data, cand masina afla pe ce pista e.
func _ensure_dust_colors() -> void:
	if _dust_colors_ready or track == null:
		return
	_dust_colors_ready = true
	# Praful de pe TEREN: mai INCHIS decat solul, nu mai deschis. Prima
	# versiune folosea lightened(0.22) si ProbeFx a aratat rezultatul: alb pal
	# pe nisip luminat = invizibil. Contrastul care se citeste ca praf e cel
	# al unei umbre usoare.
	_dust_ground_color = track.theme_ground_tint.darkened(0.12)
	# Praful de pe SOSEA merge exact invers, din acelasi motiv: contrastul,
	# nu luminozitatea. Drumul de pamant e cea mai inchisa suprafata de sub
	# roti, deci un nor si mai inchis peste el ar fi invizibil la fel de sigur
	# cum era cel alb pe nisip.
	_dust_road_color = track.road_dust_color().lightened(0.18)


## Culoarea prafului de sub roti ACUM, aceeasi alegere ca in `_update_dust`
## (sosea afanata / banda secundara / teren), plus asfaltul, unde praful de
## rulare nu porneste niciodata: acolo o aterizare ridica un nor gri-deschis.
func _surface_dust_color() -> Color:
	if track == null:
		return DRIFT_SMOKE_COLOR.darkened(0.12)
	_ensure_dust_colors()
	var on_road := track.is_on_road(road_index, global_position)
	var on_branch := route != 0 and track.is_on_road(road_index, global_position, route)
	if on_road:
		return _dust_road_color if _on_loose_ground(true) 			else DRIFT_SMOKE_COLOR.darkened(0.12)
	if on_branch:
		return track.route_dust_color(route).lightened(0.18)
	return _dust_ground_color


## Aterizare dura (`landed`, deja doar de la 6 m/s in jos): un singur nor de
## praf din jurul rotilor, mai mare si mai iute cu cat caderea a fost mai
## lunga. Thud-ul si scuturatura sunt in alta parte.
func _on_landed_visual(_car: Car, fall_speed: float) -> void:
	if _land_dust == null or fall_speed < land_dust_min_fall or in_water:
		return
	var k := clampf(inverse_lerp(land_dust_min_fall, 24.0, fall_speed), 0.0, 1.0)
	if data != null:
		_land_dust.emission_box_extents = Vector3(
			data.body_width * 0.45, 0.05, data.body_length * 0.4)
	_land_dust.color = _surface_dust_color()
	_land_dust.initial_velocity_max = lerpf(2.5, 5.0, k)
	_land_dust.radial_accel_min = lerpf(4.0, 7.0, k)
	_land_dust.radial_accel_max = lerpf(6.0, 12.0, k)
	_land_dust.scale_amount_max = lerpf(1.0, 1.6, k)
	_land_dust.restart()


func _update_dust(on_road: bool, loose: bool, on_branch: bool = false) -> void:
	if _dust_particles == null or track == null:
		return
	# Bucla cu asfalt si portiuni de pamant (Track.is_dirt_at): culoarea fumului
	# de drift se alege doar cand se schimba SURSA prafului (mai jos), iar pe asfalt
	# praful nu porneste niciodata — deci fumul ramanea colorat cu pamantul de
	# dinainte. La trecerea pamant <-> asfalt se reseteaza aici. Pe pistele fara
	# intervale ramura nu ruleaza.
	if track.has_dirt_ranges():
		var on_dirt := route == 0 and track.is_dirt_at(track.frac_at(road_index))
		if on_dirt != _drift_on_dirt:
			_drift_on_dirt = on_dirt
			_dust_source = -1
			if not on_dirt:
				_drift_particles.color = DRIFT_SMOKE_COLOR
	_ensure_dust_colors()
	var live := loose and horizontal_speed() > DUST_MIN_SPEED
	_dust_particles.emitting = live
	if _debris_particles != null:
		# Pietricelele cer mai multa viteza decat praful: la limita de jos roata
		# ridica spulber, dar nu arunca bucati. Fara pragul separat, o masina
		# care abia se misca ar imprastia pietre.
		_debris_particles.emitting = live 			and horizontal_speed() > DUST_MIN_SPEED * 1.6
	if not live:
		return
	var src := 1 if on_road else (2 if on_branch else 0)
	if src != _dust_source or (src == 2 and route != _dust_route):
		_dust_source = src
		_dust_route = route
		var tint := _dust_road_color if src == 1 else _dust_ground_color
		if src == 2:
			# Praful scurtaturii: pamantul benzii, deschis ca la sosea (norul
			# trebuie sa fie mai luminos decat suprafata de sub el ca sa se vada).
			tint = track.route_dust_color(route).lightened(0.18)
		_dust_particles.color = tint
		# Bucatile sunt din acelasi sol, dar se citesc ca material solid, nu ca
		# ceata: mai inchise si mai saturate decat norul.
		if _debris_particles != null:
			_debris_particles.color = tint.darkened(0.28)
		# Si fumul de drift: pe pamant nu arde cauciucul, se ridica solul. Gri de
		# anvelopa peste o dara rosie ar fi singurul lucru din cadru care spune
		# ca dedesubt e tot asfalt.
		_drift_particles.color = tint if _road_loose_here() \
			else DRIFT_SMOKE_COLOR
	# Norul creste cu viteza: la 6 m/s e o adiere, la plafon e o dara adevarata.
	var k := clampf(horizontal_speed() / maxf(max_speed, 1.0), 0.0, 1.0)
	_dust_particles.initial_velocity_max = lerpf(2.5, 7.0, k)
	_dust_particles.lifetime = lerpf(0.75, 1.35, k)


## Cat de des se depune o urma de rulare, in metri parcursi. 2.2 m cu placute de
## 2.4 m (SandTrail.MARK_SIZE) inseamna suprapunere, deci dara e continua.
const TRAIL_SPACING: float = 2.2
## Sub viteza asta nu se depune nimic: o masina care abia se misca prin nisip tot
## lasa urme, una oprita nu — si mai ales nu vrem sa tapetam gridul de start.
const TRAIL_MIN_SPEED: float = 3.0
## Cat de sus peste SOL sta placuta — nu peste originea masinii.
##
## ############################################################################
## Distinctia asta a costat o vanatoare intreaga: urmele se depuneau, cu pozitii
## corecte, si nu se vedea niciuna.
##
## Originea unui Car NU e la nivelul solului. Colizorul e o cutie de 1 m inalta,
## asezata la +0.6 (vezi _ready), deci talpa ei — punctul care atinge drumul —
## sta la +0.1 fata de origine. O placuta ridicata cu 0.05 "peste masina" ajungea
## astfel cu 5 cm SUB asfalt.
##
## Peste asta se aduna coroana soselei: suprafata VIZIBILA a drumului e bombata
## cu pana la Track.ROAD_CROWN (0.03) peste cea de COLIZIUNE, pe care calca
## roata. Adica exact pe banda de rulare, unde stau urmele, drumul desenat trece
## peste drumul pipait — aceeasi capcana care ingropase si urmele coapte in
## pista (vezi Track._build_tire_marks).
##
## De-aia inaltimea se calculeaza din talpa colizorului (_hull_bottom), iar
## constanta de mai jos e doar MARJA peste sol: coroana plus ce trebuie ca
## placuta sa nu clipeasca in ea pe denivelari.
## ############################################################################
const TRAIL_LIFT: float = 0.08

## Cat de sus fata de originea masinii e SOLUL. Pe fizica intreaga originea
## sta chiar la nivelul solului prin constructia suspensiei (vezi
## _rebuild_suspension_geometry), deci nu se mai deriva din talpa colizerului
## — aia s-a ridicat la +0.25 ca bordurile sa fie treaba rotilor, si ar fi
## tras urmele de rulare in aer.
func _hull_bottom() -> float:
	return 0.02


## Dara de urme lasata rulind pe teren afanat. Creata la prima nevoie: pe o pista
## cu asfalt care nu iese niciodata de pe drum nu se aloca nimic.
var _trail: SandTrail
var _trail_accum: float = 0.0

## Urme de rulare — DIFERITE de urmele de drift, si asta e tot rostul lor.
##
## Urma de drift e cauciuc ars pe asfalt: apare doar cu handbrake-ul tras, e
## neagra si dispare in 8 secunde. Urma de rulare e sant in pamant moale: apare
## din simplul fapt ca ai trecut pe acolo si ramane pana o rescrie inelul. Cele
## doua nu apar niciodata pe aceeasi suprafata (vezi _update_effects).
func _drop_trail(delta: float, loose: bool) -> void:
	if not loose:
		return
	var speed := horizontal_speed()
	if speed < TRAIL_MIN_SPEED:
		return
	_trail_accum += speed * delta
	if _trail_accum < TRAIL_SPACING:
		return
	_trail_accum = 0.0
	# Baza urmei sta pe PANTA, nu pe orizontala: y-ul placutei urmeaza normala
	# solului, iar directia de mers se proiecteaza pe planul ei.
	var up := get_floor_normal()
	if up.length_squared() < 0.5:
		up = Vector3.UP
	var fwd := -global_transform.basis.z
	fwd -= up * fwd.dot(up)
	if fwd.length_squared() < 0.001:
		return # masina exact perpendiculara pe panta: nu exista "inainte" pe ea
	fwd = fwd.normalized()
	var right := fwd.cross(up).normalized()
	if _trail == null:
		_trail = SandTrail.new()
		# Profilul brazdei tine de SUPRAFATA, nu de masina: materialul si plasa
		# sunt partajate, deci o singura urma pe pista (vezi
		# SandTrail.set_surface). Se pune INAINTE de add_child, fiindca latimea
		# intra in plasa, iar plasa se coace la primul _ready.
		SandTrail.set_surface(track.trail_mark_color(), track.trail_profile())
		add_child(_trail)
	var half_track_w := data.body_width * 0.38 if data != null else 0.85
	var rear_z := data.body_length * 0.34 if data != null else 1.3
	# Rotile din SPATE: pe o linie dreapta ele calca peste urma celor din fata,
	# deci doua fasii, nu patru.
	var base := global_position - fwd * rear_z \
		+ up * (_hull_bottom() + TRAIL_LIFT)
	var orientation := Basis(right, up, -fwd)
	for side: float in [-1.0, 1.0]:
		var wheel := base + right * half_track_w * side
		_trail.stamp(wheel, orientation)
		# Aceleasi roti scriu si in masca PERSISTENTA a drumului de zapada
		# (Track.stamp_wear refuza singur ce cade in afara soselei si nu face
		# nimic pe pistele fara foaie de uzura). SandTrail e dara proaspata
		# din spatele masinii; masca e istoria batatorita a intregii curse.
		if route == 0:
			track.stamp_wear(road_index, wheel)

## Uzura pentru consumatorii externi ai pistei (covorul de frunze de la Kyoto):
## rotile din spate stampileaza in `Track.wear_sinks`, la cadenta TRAIL_SPACING,
## DOAR pe bucla principala si DOAR la sol — si independent de `loose`, fiindca
## covorul sta pe asfalt, unde `_drop_trail` nu ruleaza. Pe pistele fara
## consumatori iese din prima: zero cost.
var _leaf_accum: float = 0.0

func _drop_leaf_wear(delta: float, on_road: bool) -> void:
	if track == null or route != 0 or not on_road or not track.has_wear_sinks():
		return
	var speed := horizontal_speed()
	if speed < TRAIL_MIN_SPEED:
		return
	_leaf_accum += speed * delta
	if _leaf_accum < TRAIL_SPACING:
		return
	_leaf_accum = 0.0
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	if fwd.length_squared() < 0.001:
		return
	fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	var half_track_w := data.body_width * 0.38 if data != null else 0.85
	var rear_z := data.body_length * 0.34 if data != null else 1.3
	var base := global_position - fwd * rear_z
	for side: float in [-1.0, 1.0]:
		track.stamp_wear_sinks(road_index, base + right * half_track_w * side)

## Textura de fum, incarcata o singura data pentru toate masinile.
##
## Regula de texturi din CLAUDE.md e "materiale de CLASA, nu per asset": asta e
## exact o clasa — un singur material partajat de tot ce e fum sau praf pe orice
## masina din cursa, deci un material, nu unul per masina.
const SMOKE_TEX: String = "res://assets/textures/smoke_puff.png"
static var _puff_material: StandardMaterial3D = null


## Puf fatetat, luminat — corpul oricarei particule de fum sau praf.
##
## Directia vine din ghidul vizual al proiectului (TOY RACER — TRACKS &
## PARTICLES): puf-uri fatetate cu volum, cu o latura in lumina si una in umbra,
## nu ceata. E o alegere DIFERITA de referinta Beach Buggy Racing 2, unde praful
## e atmosferic si moale — si a fost luata explicit de dezvoltator.
##
## Consecinta masurata, ca sa fie scrisa undeva: silueta fatetata are muchii,
## deci pe o taietura prin nor apar iar trepte dure (billboard-urile moi dadeau
## 0, sferele ~45). Aici nu mai e un defect, e chiar efectul cerut — dar
## inseamna ca marimea si numarul trebuie tinute in frau, altfel norul se
## citeste ca un morman de bile.
##
## `size` e diametrul sferei, in metri.
func _puff_mesh(size: float) -> Mesh:
	if _puff_material == null:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		# Culorile noastre sunt autorate ca sRGB (Color.html, Palette). Fara
		# steagul asta, Godot le citeste ca LINIARE si le scoate cu ~1.5 trepte
		# mai deschise: #BB8744 randa (241,218,177) — crem pal, masurat cu
		# ProbeFx. De-aia praful parea alb oricat il inchideam la sursa.
		m.vertex_color_is_srgb = true
		# LUMINAT, nu unshaded — asta e alegerea de directie: guide-ul cere
		# puf-uri cu volum, cu o latura in lumina si una in umbra. Un billboard
		# unshaded n-are cum sa aiba fete, deci n-are cum sa aiba volum.
		#
		# PER VERTEX, nu per pixel (sep 2026, planul de grafica pe mobil): pe
		# o sfera cu 8x4 segmente lumina per-vertex da aceleasi fete, cu
		# aceeasi latura in lumina si in umbra — fatetarea e chiar din
		# vertecsi. Diferenta e ca pixelul de fum nu mai evalueaza lumina, si
		# fumul jucatorului e exact stratul transparent care sta cel mai
		# aproape de camera, pe cel mai mult ecran, pe un GPU cu placi.
		m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		# Difuz plat si fara specular: praful nu straluceste, doar prinde
		# directia soarelui. Fara asta, sferele ies ca niste bile de plastic.
		m.roughness = 1.0
		m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		# Fara scriere in depth: norii se suprapun fara sa se taie unul pe altul.
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_puff_material = m
	# Sfera FATETATA, cu putine segmente: fetele sunt chiar rostul ei. 8x4 = 64
	# de triunghiuri bucata — cu segmentele setate, dupa regula din CLAUDE.md.
	var sph := SphereMesh.new()
	sph.radius = size * 0.5
	sph.height = size
	sph.radial_segments = 8
	sph.rings = 4
	sph.material = _puff_material
	return sph


## Fum de cauciuc ars. Pe drum de pamant se inlocuieste cu praful solului —
## vezi _update_dust.
const DRIFT_SMOKE_COLOR: Color = Color(0.78, 0.78, 0.8)

## 0 la pragul de ciocnire, 1 la plafonul de violenta — dozajul comun pentru
## sunet si scantei.
func _bump_strength(dv: float) -> float:
	return clampf(inverse_lerp(bump_min_closing, bump_max_dv, dv), 0.0, 1.0)


## Sub atat (m/s de delta-v) contactul e frecare, nu izbitura: fara scantei.
const SPARK_MIN_DV: float = 4.0

## Scantei la contactul cu `other` (#500): la jumatatea distantei dintre
## caroserii, la inaltimea barelor, aruncate in afara contactului si in sus.
## Mai multe si mai rapide cu cat izbitura e mai mare: `amount` (CPUParticles3D
## n-are `amount_ratio`; schimbarea realoca, dar oricum repornim). Emitatorul e in coordonate de LUME, deci scanteile raman unde
## s-au nascut, nu fug cu masina.
func _emit_sparks(other: Car, dv: float) -> void:
	if _sparks == null or dv < SPARK_MIN_DV:
		return
	var to_other := other.global_position - global_position
	to_other.y = 0.0
	if to_other.length_squared() < 0.0001:
		return
	var k := _bump_strength(dv)
	_sparks.global_position = _contact_point_with(other,
		global_position + to_other * 0.5 + Vector3.UP * 0.55)
	# Directia: perpendiculara pe linia dintre masini (de-a lungul fetelor care
	# se freaca), cu o componenta in sus; spread-ul larg face restul.
	var along := to_other.normalized().cross(Vector3.UP)
	_set_spark_direction(_sparks,
		along * (1.0 if randf() < 0.5 else -1.0) + Vector3.UP * 0.6)
	_sparks.amount = int(lerpf(float(SPARKS_MIN), float(SPARKS_MAX), k))
	_sparks.initial_velocity_max = lerpf(7.0, 13.0, k)
	_sparks.restart()


## `direction` al unui emitator CPU e in spatiul NODULUI (velocitatile se rotesc
## cu baza lui globala chiar si cu `local_coords = false`), iar scanteile
## noastre sunt copii ai masinii: directia ceruta in LUME trebuie adusa in
## spatiul ei, altfel iese rotita cu orientarea masinii.
func _set_spark_direction(emitter: CPUParticles3D, world_dir: Vector3) -> void:
	var d := emitter.global_transform.basis.inverse() * world_dir
	emitter.direction = d.normalized() if d.length_squared() > 1e-6 else Vector3.UP


## Rafala la o izbitura de perete (>= `wall_spark_burst_dv`): scanteile sar
## dinspre perete, in sus, si putin inapoi pe directia de mers. Reuseaza
## emitatorul one-shot de la ciocnirea intre masini.
func _emit_wall_sparks(point: Vector3, normal: Vector3, strength: float) -> void:
	if _sparks == null:
		return
	var k := _bump_strength(strength)
	_sparks.global_position = point + Vector3.UP * 0.1
	var vh := Vector3(velocity.x, 0.0, velocity.z)
	var tangent := vh - normal * vh.dot(normal)
	var back := -tangent.normalized() if tangent.length_squared() > 0.01 		else Vector3.ZERO
	_set_spark_direction(_sparks, normal * 0.9 + Vector3.UP * 0.6 + back * 0.5)
	_sparks.amount = int(lerpf(float(SPARKS_MIN), float(SPARKS_MAX), k))
	_sparks.initial_velocity_max = lerpf(7.0, 13.0, k)
	_sparks.restart()


## Scanteile CONTINUE ale razuirii pe perete si ale frecarii intre masini.
## Un singur emitator (`ScrapeSparks`, 8 particule, viata 0.22 s) servit pe
## rand: peretele are prioritate. Rata nu se poate schimba la un emitator CPU
## fara sa-l realoci, deci o da RAMPA DE CULOARE INITIALA: fiecare particula
## isi alege la nastere un loc pe ea, iar partea „opaca" a rampei (offset 0..p)
## e fractia care se si vede. Mai multa viteza = p mai mare = mai multe scantei.
func _update_scrape_sparks() -> void:
	if _scrape_sparks == null:
		return
	var live := false
	var point := Vector3.ZERO
	var n := Vector3.ZERO
	var rel := Vector3.ZERO
	var density := 0.0
	# Cat de sus pleaca scanteile: pe perete bine in sus (peretele le-ar ascunde
	# din camera de sus), intre masini si mai sus — contactul e intre doua
	# acoperisuri, iar scanteia trebuie sa treaca de ele ca sa se vada.
	var lift := 1.3
	var lift_y := 0.55
	if wall_contact and wall_scrape_speed > scrape_min_speed:
		live = true
		point = wall_point
		n = wall_normal
		rel = Vector3(velocity.x, 0.0, velocity.z)
		density = inverse_lerp(scrape_min_speed, 18.0, wall_scrape_speed)
	elif rub_car != null and rub_speed > rub_min_speed 			and get_instance_id() < rub_car.get_instance_id():
		# Perechea scanteiaza O SINGURA data (masina cu id-ul mai mic): doua
		# emitatoare in acelasi punct ar dubla rata si bugetul.
		live = true
		point = rub_point
		n = rub_normal
		rel = velocity - rub_car.velocity
		rel.y = 0.0
		density = inverse_lerp(rub_min_speed, 10.0, rub_speed)
		lift = 1.6
		lift_y = 0.35
	if not live:
		_scrape_sparks.emitting = false
		return
	var tangent := rel - n * rel.dot(n)
	var back := -tangent.normalized() if tangent.length_squared() > 0.01 		else Vector3.ZERO
	_scrape_sparks.global_position = point + Vector3.UP * lift_y
	# Spre inapoi pe directia de mers, putin in afara peretelui si in sus.
	# Si bine in sus: din camera de sus, sparturile care raman la nivelul
	# peretelui se ascund in spatele lui.
	_set_spark_direction(_scrape_sparks, back * 0.7 + n * 0.35 + Vector3.UP * lift)
	var d := clampf(density, 0.0, 1.0)
	_scrape_density.set_offset(1, lerpf(0.25, 1.0, d))
	_scrape_sparks.initial_velocity_min = lerpf(2.5, 5.0, d)
	_scrape_sparks.initial_velocity_max = lerpf(5.0, 10.0, d)
	_scrape_sparks.emitting = true


## Starea de contact a tick-ului, dintr-o singura trecere prin punctele
## solverului: perete (normala aproape orizontala) si masina de care te freci.
## Solul de sub caroserie (normala in sus) nu e perete.
func _scan_contact_state() -> void:
	wall_contact = false
	wall_moving = false
	wall_scrape_speed = 0.0
	rub_car = null
	rub_speed = 0.0
	_last_static = null
	var state := PhysicsServer3D.body_get_direct_state(get_rid())
	if state == null:
		return
	var wn := Vector3.ZERO
	var wp := Vector3.ZERO
	var wc := 0
	var rn := Vector3.ZERO
	var rp := Vector3.ZERO
	var rc := 0
	for i in state.get_contact_count():
		var obj := state.get_contact_collider_object(i)
		var pt := state.get_contact_collider_position(i)
		var n := state.get_contact_local_normal(i)
		var to_me := global_position - pt
		if n.dot(to_me) < 0.0:
			n = -n
		var nh := Vector3(n.x, 0.0, n.z)
		if obj is Car:
			if rub_car == null:
				rub_car = obj as Car
			if obj == rub_car:
				rp += pt
				rc += 1
				var away := Vector3(to_me.x, 0.0, to_me.z)
				rn += away.normalized() if away.length_squared() > 1e-4 else nh
		elif obj is StaticBody3D:
			if absf(n.y) > 0.7 or nh.length_squared() < 1e-4:
				continue
			_last_static = obj as Node
			if obj is AnimatableBody3D:
				wall_moving = true
			wn += nh.normalized()
			wp += pt
			wc += 1
	if wc > 0:
		wall_contact = true
		wall_normal = wn.normalized() if wn.length_squared() > 1e-6 else wall_normal
		wall_point = wp / float(wc)
		var vh := Vector3(velocity.x, 0.0, velocity.z)
		wall_scrape_speed = (vh - wall_normal * vh.dot(wall_normal)).length()
	if rc > 0:
		rub_point = rp / float(rc)
		rub_normal = rn.normalized() if rn.length_squared() > 1e-6 else Vector3.ZERO
		var rel := velocity - rub_car.velocity
		rel.y = 0.0
		rub_speed = (rel - rub_normal * rel.dot(rub_normal)).length()


## Punctul de contact cu `other`, cum il raporteaza solverul (media punctelor
## din tick-ul asta); `fallback` daca nu exista niciunul. Mijlocul dintre
## centre nu ajunge: cand o masina e mult mai mare (autobuzul), el cade in
## caroseria ei, iar scanteile ies ascunse inauntru (vazut pe captura).
func _contact_point_with(other: Car, fallback: Vector3) -> Vector3:
	var state := PhysicsServer3D.body_get_direct_state(get_rid())
	if state == null:
		return fallback
	var sum := Vector3.ZERO
	var count := 0
	for i in state.get_contact_count():
		if state.get_contact_collider_object(i) == other:
			sum += state.get_contact_collider_position(i)
			count += 1
	return sum / float(count) if count > 0 else fallback


static var _spark_material: StandardMaterial3D = null
const SPARKS_MIN: int = 8
const SPARKS_MAX: int = 14
## Emitatorul continuu de razuire/frecare. Impreuna cu SPARKS_MAX (14): 40 de
## scantei pe masina (plafonul cerut: <= ~40). (Rafala de la ciocnirea intre
## masini a coborat de la 24 la 14 ca sa incapa; la camera de joc o razuire cu
## 8-12 scantei se vedea ca doua-trei puncte risipite in urma masinii.)
const SCRAPE_SPARKS_AMOUNT: int = 26

func _build_sparks() -> void:
	_sparks = CPUParticles3D.new()
	_sparks.name = "Sparks"
	_sparks.emitting = false
	_sparks.one_shot = true
	_sparks.explosiveness = 1.0
	# Plafonul pe mobil: 24 pe masina, 144 pe o cursa de 6, si doar o clipa.
	_sparks.amount = SPARKS_MAX
	_sparks.lifetime = 0.45
	_sparks.local_coords = false
	_sparks.spread = 70.0
	_sparks.initial_velocity_min = 4.0
	_sparks.initial_velocity_max = 8.0
	_sparks.gravity = Vector3(0, -14.0, 0)
	_sparks.damping_min = 2.0
	_sparks.damping_max = 4.0
	_sparks.scale_amount_min = 0.6
	_sparks.scale_amount_max = 1.2
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.2))
	_sparks.scale_amount_curve = shrink
	# Alb-galben la nastere, portocaliu, apoi se stinge: metal incins.
	var heat := Gradient.new()
	heat.set_offsets(PackedFloat32Array([0.0, 0.35, 1.0]))
	heat.set_colors(PackedColorArray([
		Color(1.0, 0.97, 0.75, 1.0), Color(1.0, 0.62, 0.15, 1.0),
		Color(0.9, 0.25, 0.05, 0.0)]))
	_sparks.color_ramp = heat
	if _spark_material == null:
		# Un material de CLASA pentru toate scanteile din cursa (vezi nota de la
		# _puff_material): neluminat — scanteia e sursa de lumina, nu o
		# suprafata. OPAC, nu aditiv: pe nisipul luminos de zi aditivul n-avea
		# ce adauga (pixelul era deja aproape alb) si darele ieseau translucide,
		# abia ghicite pe captura. Se sting prin rampa de culoare.
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_spark_material = m
	# Dara, nu punct: o bara subtire de 60 cm aliniata cu viteza
	# (`particle_flag_align_y`). Un patrat de 9 cm cu fata la camera iesea de
	# 3-4 pixeli la distanta camerei de urmarire — numarat de sonda, nevazut pe
	# captura. Cutia se vede din orice unghi, unde un quad aliniat ar fi putut
	# ajunge cu muchia spre camera. 12 triunghiuri.
	var streak := BoxMesh.new()
	streak.size = Vector3(0.07, 0.6, 0.07)
	streak.material = _spark_material
	_sparks.mesh = streak
	_sparks.particle_flag_align_y = true
	_sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sparks)
	_build_scrape_sparks(heat, shrink)


## Emitatorul continuu de scantei (vezi `_update_scrape_sparks`). `top_level`:
## sta in lume, nu se roteste cu masina, deci directia ceruta in lume e cea
## care iese; pozitia i se scrie in fiecare tick cat tine contactul.
func _build_scrape_sparks(heat: Gradient, shrink: Curve) -> void:
	var e := CPUParticles3D.new()
	e.name = "ScrapeSparks"
	e.top_level = true # inainte de add_child: dupa, ar ingheta transformul
	e.emitting = false
	e.amount = SCRAPE_SPARKS_AMOUNT
	e.lifetime = 0.28
	e.randomness = 0.6
	e.local_coords = false
	e.spread = 32.0
	e.initial_velocity_min = 2.5
	e.initial_velocity_max = 6.0
	e.gravity = Vector3(0, -12.0, 0)
	e.damping_min = 1.0
	e.damping_max = 3.0
	# Pornesc imprastiate pe ~1 m in jurul contactului, nu dintr-un punct:
	# razuirea e o LINIE de contact lunga cat caroseria.
	e.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	e.emission_sphere_radius = 0.6
	e.scale_amount_min = 0.9
	e.scale_amount_max = 1.3
	e.scale_amount_curve = shrink
	# Rampa proprie, SATURATA (portocaliu-galben apoi rosu), nu alb-galben ca la
	# rafala: alb-galben pe un perete bej sau o dala deschisa dispare. Opacitatea
	# ramane plina pana aproape de capat.
	var hot := Gradient.new()
	hot.set_offsets(PackedFloat32Array([0.0, 0.5, 0.85, 1.0]))
	hot.set_colors(PackedColorArray([
		Color(1.0, 0.85, 0.25, 1.0), Color(1.0, 0.5, 0.05, 1.0),
		Color(0.95, 0.22, 0.02, 1.0), Color(0.8, 0.12, 0.02, 0.0)]))
	e.color_ramp = hot
	# Rata: cine nu cade in partea opaca a rampei se naste invizibil.
	_scrape_density = Gradient.new()
	_scrape_density.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	_scrape_density.set_offsets(PackedFloat32Array([0.0, 1.0]))
	_scrape_density.set_colors(PackedColorArray([
		Color(1, 1, 1, 1), Color(1, 1, 1, 0)]))
	e.color_initial_ramp = _scrape_density
	var streak := BoxMesh.new()
	# Mai groase decat rafala: la camera de joc (16 m) o dara de 5 cm abia avea
	# 2 pixeli si se vedeau doua-trei puncte portocalii pe captura.
	streak.size = Vector3(0.2, 1.25, 0.2)
	streak.material = _spark_material
	e.mesh = streak
	e.particle_flag_align_y = true
	e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(e)
	_scrape_sparks = e


## Praful de aterizare: o rafala (one_shot) de 16 pufuri din jurul rotilor,
## imprastiate spre exterior de o acceleratie radiala. Aceeasi familie ca
## praful de rulare (acelasi puf, aceeasi rampa de opacitate); culoarea o
## primeste la fiecare aterizare, dupa suprafata.
func _build_land_dust() -> void:
	var e := CPUParticles3D.new()
	e.name = "LandDust"
	e.position = Vector3(0, 0.1, 0)
	e.emitting = false
	e.one_shot = true
	e.explosiveness = 0.95
	e.amount = LAND_DUST_AMOUNT
	e.lifetime = 0.75
	e.local_coords = false
	# Aproape orizontal, in toate directiile: norul trebuie sa iasa de sub masina,
	# nu sa urce pe sub ea (de sus, un nor ramas sub caroserie nu se vede).
	e.direction = Vector3.UP
	e.spread = 85.0
	e.initial_velocity_min = 1.5
	e.initial_velocity_max = 3.5
	e.radial_accel_min = 5.0
	e.radial_accel_max = 9.0
	e.damping_min = 1.5
	e.damping_max = 2.5
	e.gravity = Vector3(0, 0.4, 0)
	e.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	e.emission_box_extents = Vector3(0.9, 0.05, 1.4)
	e.scale_amount_min = 0.6
	e.scale_amount_max = 1.2
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.5))
	grow.add_point(Vector2(1.0, 1.0))
	e.scale_amount_curve = grow
	e.angle_min = -180.0
	e.angle_max = 180.0
	var fade := Gradient.new()
	fade.set_offsets(PackedFloat32Array([0.0, 0.12, 1.0]))
	fade.set_colors(PackedColorArray([
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.0)]))
	e.color_ramp = fade
	e.mesh = _puff_mesh(0.9)
	e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(e)
	_land_dust = e


const LAND_DUST_AMOUNT: int = 16

func _build_effects() -> void:
	_build_sparks()
	# Fum de drift, colorat dupa nivelul de boost incarcat.
	_drift_particles = CPUParticles3D.new()
	# Nume propriu, ca la "Dust"/"Debris": pana acum singurul mod de a deosebi
	# fumul de praf dintr-o sonda era sa te iei dupa `amount`.
	_drift_particles.name = "DriftSmoke"
	_drift_particles.position = Vector3(0, 0.4, 1.9) # spatele masinii (+Z)
	_drift_particles.emitting = false
	_drift_particles.amount = 24
	_drift_particles.lifetime = 0.5
	_drift_particles.direction = Vector3(0, 0.4, 1)
	_drift_particles.spread = 30.0
	_drift_particles.initial_velocity_min = 3.0
	_drift_particles.initial_velocity_max = 6.0
	_drift_particles.gravity = Vector3(0, 1.5, 0)
	_drift_particles.scale_amount_min = 0.6
	_drift_particles.scale_amount_max = 1.4
	_drift_particles.color = DRIFT_SMOKE_COLOR
	# Fumul de drift nu avea deloc rampa de opacitate: iesea opac si disparea
	# brusc la 0.5 s. Acum se naste, se ingroasa si se stinge, ca praful.
	var smoke_fade := Gradient.new()
	smoke_fade.set_offsets(PackedFloat32Array([0.0, 0.18, 1.0]))
	smoke_fade.set_colors(PackedColorArray([
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.42), Color(1, 1, 1, 0.0)]))
	_drift_particles.color_ramp = smoke_fade
	# Densitatea fumului: ca la scanteile continue, o rampa de culoare INITIALA
	# in trepte — fiecare puf isi trage la nastere un loc pe ea, iar partea
	# opaca (0..p) e fractia care se vede, cu opacitatea ei. `_update_drift_smoke`
	# muta p si opacitatea cu alunecarea; `color` ramane neatins (sondele de
	# praf il compara cu culoarea pistei).
	_drift_density = Gradient.new()
	_drift_density.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	_drift_density.set_offsets(PackedFloat32Array([0.0, 1.0]))
	_drift_density.set_colors(PackedColorArray([
		Color(1, 1, 1, 1), Color(1, 1, 1, 0)]))
	_drift_particles.color_initial_ramp = _drift_density
	_drift_particles.angle_min = -180.0
	_drift_particles.angle_max = 180.0
	# Fumul se destrama crescand, ca norul de praf.
	var smoke_grow := Curve.new()
	smoke_grow.add_point(Vector2(0.0, 0.5))
	smoke_grow.add_point(Vector2(1.0, 1.0))
	_drift_particles.scale_amount_curve = smoke_grow
	# Panza orientata spre camera cu textura moale, nu sfera low-poly: vezi
	# _puff_mesh. Sferele aveau exact defectul cuburilor de dinaintea lor,
	# doar cu mai multe fete — o silueta cu muchii, nu un nor.
	_drift_particles.mesh = _puff_mesh(0.30)
	_drift_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_drift_particles)

	# Praf ridicat de sub roti pe off-road. Emite din SPATELE masinii, la nivelul
	# solului — sursa e contactul rotii cu nisipul, nu evacuarea.
	#
	# Buget: 26 de particule per masina, 130 pe o cursa de 5. Prima versiune avea
	# 18 mici si palide si sonda vizuala (ProbeFx) a aratat de ce nu le vedea
	# nimeni: o dara punctata de cuburi, nu un nor.
	_dust_particles = CPUParticles3D.new()
	# Nume propriu ca sondele sa-l poata gasi: ProbeFx verifica praful si dara
	# impreuna, iar pana acum singurul mod de a-l deosebi de fumul de drift era
	# sa te iei dupa `amount`.
	_dust_particles.name = "Dust"
	_dust_particles.position = Vector3(0, 0.12, 1.7)
	_dust_particles.emitting = false
	# Multe particule mici si palide, nu putine mari si opace. Masuratoarea
	# fata de referinta (Beach Buggy Racing 2) a aratat de ce conteaza: la 26
	# de blob-uri mari fiecare se citeste individual, si o taietura orizontala
	# prin nor gasea 45 de trepte dure fata de 0-3 la ei. Densitatea trebuie sa
	# vina din suprapunere, nu din marimea bucatii.
	# Mai PUTINE si mai mari decat la varianta de ceata: in ghid se numara
	# puf-urile din cadru (cinci-sase), fiindca fiecare are volum propriu. La 64
	# de sfere fatetate nu se mai vede niciuna, doar un morman.
	_dust_particles.amount = 22
	_dust_particles.lifetime = 1.15
	_dust_particles.direction = Vector3(0, 1, 0.6)
	_dust_particles.spread = 45.0
	_dust_particles.initial_velocity_min = 1.5
	_dust_particles.initial_velocity_max = 4.0
	# Norul iese de pe TOATA latimea puntii spate, nu dintr-un punct: in
	# referinta dara e mai lata decat masina, fiindca sursa sunt cele doua pete
	# de contact. Emitatorul-punct era motivul pentru care al nostru iesea ca o
	# pana ingusta din mijlocul barei.
	_dust_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_dust_particles.emission_box_extents = Vector3(0.62, 0.06, 0.12)
	# Gravitatie usor negativa: praful se ridica si se lasa, nu tasneste ca fumul.
	_dust_particles.gravity = Vector3(0, -1.2, 0)
	_dust_particles.damping_min = 1.5
	_dust_particles.damping_max = 3.0
	# Particula creste cat traieste — asa se destrama un nor real. Cu scara
	# fixa, fiecare puf ramane un disc de aceeasi marime pana dispare.
	_dust_particles.scale_amount_min = 0.55
	_dust_particles.scale_amount_max = 1.35
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.45))
	grow.add_point(Vector2(1.0, 1.0))
	_dust_particles.scale_amount_curve = grow
	# Rotatie proprie per particula: fara ea, 64 de exemplare din ACEEASI
	# textura arata ca 64 de stampile identice.
	_dust_particles.angle_min = -180.0
	_dust_particles.angle_max = 180.0
	# Se stinge in transparenta pe durata vietii; fara asta, norul dispare brusc.
	# CPUParticles3D vrea un Gradient direct, nu un GradientTexture1D — ala e
	# pentru varianta GPU.
	# Praful e o TENTA peste sol, nu un obiect care il acopera. La 0.72 norul
	# nostru muta luminanta solului cu 55 in medie si pana la 212; in referinta
	# textura de dedesubt se vede prin praf tot timpul. Varful coboara la 0.30,
	# iar densitatea o dau cele 64 de particule suprapuse.
	var fade := Gradient.new()
	fade.set_offsets(PackedFloat32Array([0.0, 0.15, 1.0]))
	fade.set_colors(PackedColorArray([
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.62), Color(1, 1, 1, 0.0)]))
	_dust_particles.color_ramp = fade
	# Culoare provizorie; cea reala vine din tema, in _update_dust, de indata ce
	# masina stie pe ce pista e. Praf nisipiu pe iarba ar fi exact genul de
	# detaliu care se observa fara sa stii de ce te deranjeaza.
	_dust_particles.color = Palette.color(Palette.SAND_MID).darkened(0.12)
	_dust_particles.mesh = _puff_mesh(0.30)
	# Nicio particula nu arunca umbra. Inainte fumul de drift si flacara erau
	# opace si o aruncau chiar — iar acum, fiind panze orientate spre camera,
	# umbra lor ar fi un dreptunghi care se roteste dupa privitor.
	_dust_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_dust_particles)
	_build_land_dust()

	# STROPI DE APA (v12). Doua emitatoare din aceeasi familie ca praful (panza
	# spre camera cu material luminat, vezi _puff_mesh); culorile vin din tema
	# la primul tick cu pista (Track.water_splash_color).
	#   - `WaterSpray`: continuu, de la rotile din FATA, cat timp treci prin apa
	#     cu viteza. Sursa e botul care taie apa, deci se vede din chase cam —
	#     un spray din spate n-ar fi vazut de nimeni. Aruncat in sus si lateral
	#     si tras jos tare (gravitatie -12): stropii cad, nu plutesc ca praful.
	#   - `WaterBurst`: o rafala la INTRARE (one_shot), la nivelul luciului, pe
	#     tot gabaritul masinii.
	# Buget: 28 + 40 pe masina, dar rafala traieste 0.8 s si spray-ul doar in
	# apa — in 95% din cursa amandoua stau stinse.
	_water_spray = CPUParticles3D.new()
	_water_spray.name = "WaterSpray"
	_water_spray.position = Vector3(0, 0.3, -1.15) # puntea fata (-Z e fata)
	_water_spray.emitting = false
	_water_spray.amount = 36
	_water_spray.lifetime = 0.7
	_water_spray.direction = Vector3(0, 1, -0.35)
	_water_spray.spread = 50.0
	_water_spray.initial_velocity_min = 2.0
	_water_spray.initial_velocity_max = 6.0
	_water_spray.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_water_spray.emission_box_extents = Vector3(0.75, 0.05, 0.25)
	_water_spray.gravity = Vector3(0, -9.0, 0)
	_water_spray.damping_min = 0.5
	_water_spray.damping_max = 1.5
	_water_spray.scale_amount_min = 0.5
	_water_spray.scale_amount_max = 1.1
	var spray_grow := Curve.new()
	spray_grow.add_point(Vector2(0.0, 0.6))
	spray_grow.add_point(Vector2(1.0, 1.0))
	_water_spray.scale_amount_curve = spray_grow
	_water_spray.angle_min = -180.0
	_water_spray.angle_max = 180.0
	var spray_fade := Gradient.new()
	spray_fade.set_offsets(PackedFloat32Array([0.0, 0.1, 1.0]))
	spray_fade.set_colors(PackedColorArray([
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.85), Color(1, 1, 1, 0.0)]))
	_water_spray.color_ramp = spray_fade
	_water_spray.color = Color(0.85, 0.92, 0.95)
	_water_spray.mesh = _puff_mesh(0.5)
	_water_spray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_water_spray)

	_water_burst = CPUParticles3D.new()
	_water_burst.name = "WaterBurst"
	_water_burst.emitting = false
	_water_burst.one_shot = true
	_water_burst.explosiveness = 0.95
	_water_burst.amount = 40
	_water_burst.lifetime = 0.8
	_water_burst.direction = Vector3(0, 1, 0)
	_water_burst.spread = 70.0
	_water_burst.initial_velocity_min = 3.0
	_water_burst.initial_velocity_max = 9.0
	_water_burst.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_water_burst.emission_box_extents = Vector3(0.9, 0.05, 1.6)
	_water_burst.gravity = Vector3(0, -13.0, 0)
	_water_burst.scale_amount_min = 0.6
	_water_burst.scale_amount_max = 1.4
	var burst_grow := Curve.new()
	burst_grow.add_point(Vector2(0.0, 0.7))
	burst_grow.add_point(Vector2(1.0, 1.1))
	_water_burst.scale_amount_curve = burst_grow
	_water_burst.angle_min = -180.0
	_water_burst.angle_max = 180.0
	var burst_fade := Gradient.new()
	burst_fade.set_offsets(PackedFloat32Array([0.0, 0.08, 1.0]))
	burst_fade.set_colors(PackedColorArray([
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.0)]))
	_water_burst.color_ramp = burst_fade
	_water_burst.color = Color(0.85, 0.92, 0.95)
	_water_burst.mesh = _puff_mesh(0.42)
	_water_burst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_water_burst)

	# Pietricele aruncate de roata. Contrapunctul prafului: bucati MICI si
	# opace, cu gravitatie adevarata, care cad inapoi pe sol. Norul da
	# atmosfera, astea dau materialul — fara ele solul afanat arata ca fum, nu
	# ca pamant.
	_debris_particles = CPUParticles3D.new()
	_debris_particles.name = "Debris"
	_debris_particles.position = Vector3(0, 0.10, 1.7)
	_debris_particles.emitting = false
	_debris_particles.amount = 14
	_debris_particles.lifetime = 0.7
	_debris_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_debris_particles.emission_box_extents = Vector3(0.62, 0.04, 0.10)
	_debris_particles.direction = Vector3(0, 0.7, 1)
	_debris_particles.spread = 22.0
	_debris_particles.initial_velocity_min = 3.5
	_debris_particles.initial_velocity_max = 8.0
	# Gravitatie plina: bucata urca, cade si se opreste — arcul e chiar ce o
	# deosebeste de praf.
	_debris_particles.gravity = Vector3(0, -14.0, 0)
	_debris_particles.scale_amount_min = 0.5
	_debris_particles.scale_amount_max = 1.0
	_debris_particles.angular_velocity_min = -420.0
	_debris_particles.angular_velocity_max = 420.0
	# 8 triunghiuri bucata, cu segmentele setate — regula din CLAUDE.md. La 14
	# particule inseamna 112 triunghiuri per masina.
	var grit := SphereMesh.new()
	grit.radius = 0.05
	grit.height = 0.10
	grit.radial_segments = 4
	grit.rings = 2
	var grit_mat := StandardMaterial3D.new()
	grit_mat.vertex_color_use_as_albedo = true
	grit_mat.vertex_color_is_srgb = true
	grit_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grit.material = grit_mat
	_debris_particles.mesh = grit
	_debris_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_debris_particles)

	# Flacara de boost.
	_boost_particles = CPUParticles3D.new()
	_boost_particles.position = Vector3(0, 0.6, 2.0)
	_boost_particles.emitting = false
	_boost_particles.amount = 30
	_boost_particles.lifetime = 0.25
	_boost_particles.direction = Vector3(0, 0, 1)
	_boost_particles.spread = 10.0
	_boost_particles.initial_velocity_min = 10.0
	_boost_particles.initial_velocity_max = 16.0
	_boost_particles.scale_amount_min = 0.4
	_boost_particles.scale_amount_max = 0.9
	_boost_particles.color = Color(1.0, 0.55, 0.1)
	# Flacara se stinge in fum, nu dispare intreaga la 0.25 s.
	var flame_fade := Gradient.new()
	flame_fade.set_offsets(PackedFloat32Array([0.0, 0.35, 1.0]))
	flame_fade.set_colors(PackedColorArray([
		Color(1.0, 0.92, 0.60, 0.95),
		Color(1.0, 0.48, 0.10, 0.75),
		Color(0.55, 0.20, 0.06, 0.0)]))
	_boost_particles.color_ramp = flame_fade
	_boost_particles.angle_min = -180.0
	_boost_particles.angle_max = 180.0
	# Foc ADITIV pe panza moale: 30 de bile portocalii opace erau exact aceeasi
	# greseala ca la praf, doar ca la evacuare. Focul e lumina — se aduna peste
	# ce e in spatele lui, nu il acopera.
	var flame_q := _puff_mesh(0.26)
	var flame_mat := StandardMaterial3D.new()
	flame_mat.albedo_texture = load(SMOKE_TEX) as Texture2D
	flame_mat.vertex_color_use_as_albedo = true
	flame_mat.vertex_color_is_srgb = true
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	flame_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	flame_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	flame_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	flame_q.material = flame_mat
	_boost_particles.mesh = flame_q
	_boost_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_boost_particles)

	# Flacarile de pe capota, cat masina arde (vezi `ignite`).
	#
	# Pozitionate in FATA si suflate spre spate: la chase cam, ce iese de pe
	# capota urca prin dreptul parbrizului si acopera partea de sus a
	# ecranului — adica exact banda in care vezi urmatorul obstacol. Pedeapsa
	# arderii e vizibilitatea, nu cifra din plafon.
	_fire_particles = CPUParticles3D.new()
	_fire_particles.position = Vector3(0, 0.62, -0.75)
	_fire_particles.emitting = false
	# 26: sub plafonul de particule al proiectului, si oricum doar UNA din
	# masini (a ta) e vazuta de aproape.
	_fire_particles.amount = 26
	_fire_particles.lifetime = 0.75
	_fire_particles.direction = Vector3(0, 1, 0.55)
	_fire_particles.spread = 24.0
	_fire_particles.initial_velocity_min = 2.4
	_fire_particles.initial_velocity_max = 5.0
	# Gravitatie POZITIVA pe Y: aerul cald urca, flacara nu cade.
	_fire_particles.gravity = Vector3(0, 3.4, 0)
	_fire_particles.scale_amount_min = 0.5
	_fire_particles.scale_amount_max = 1.5
	# Se sting din portocaliu incins in fum gri — o flacara care ramane
	# portocalie pana dispare arata a sprite, nu a foc.
	var fire_ramp := Gradient.new()
	fire_ramp.set_color(0, Color(1.0, 0.72, 0.18, 1.0))
	fire_ramp.set_color(1, Color(0.32, 0.29, 0.28, 0.0))
	_fire_particles.color_ramp = fire_ramp
	var fire_mesh := SphereMesh.new()
	fire_mesh.radius = 0.16
	fire_mesh.height = 0.32
	# Segmente EXPLICIT: implicitul (64x32) ar da 4224 de triunghiuri pe o
	# bila de 16 cm, ori 26 de bucati (CLAUDE.md, regula sferei).
	fire_mesh.radial_segments = 6
	fire_mesh.rings = 3
	var fire_mat := StandardMaterial3D.new()
	fire_mat.vertex_color_use_as_albedo = true
	fire_mat.vertex_color_is_srgb = true
	fire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fire_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Fara scriere in depth, ca la praf: flacarile se suprapun fara sa se taie.
	fire_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	fire_mesh.material = fire_mat
	_fire_particles.mesh = fire_mesh
	add_child(_fire_particles)

	# Vocile masinii: motor pozitional (al tau se aude mereu, adversarii cand sunt
	# aproape), derapaj, suprafete, turbo, vant. Creat aici, cu playerele la nevoie.
	_audio = CarAudio.new()
	add_child(_audio)
	_audio.setup(self)

	# Umbra blob: disc intunecat, pozitionat pe sol la fiecare tick.
	# top_level = nu mosteneste transformarea masinii (o setam noi global).
	_shadow = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.02
	_shadow.mesh = disc
	_shadow_mat = StandardMaterial3D.new()
	_shadow_mat.albedo_color = Color(0.0, 0.0, 0.0, 0.38)
	_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow.material_override = _shadow_mat
	_shadow.scale = Vector3(1.3, 1.0, 2.0)
	add_child(_shadow)
	_shadow.top_level = true

## Rotile se invart cu viteza reala (unghi = viteza / raza), cele din fata se
## intorc spre directia de viraj, si TOATE urmaresc compresia reala a arcului
## lor: pe denivelari fiecare roata urca singura, in aer atarna la
## destinderea completa. Vizualul citeste fizica, nu o mimeaza.
func _update_wheels(delta: float, steer: float, fwd_speed: float) -> void:
	if _wheels_all.is_empty():
		return
	_wheel_spin = fposmod(_wheel_spin + fwd_speed / _wheel_radius * delta, TAU)
	_wheel_steer = lerpf(_wheel_steer, steer * 0.42, 10.0 * delta)
	var spin_basis := Basis(Vector3.RIGHT, _wheel_spin)
	var inv_scale := 1.0 / maxf(data.model_scale if data != null else 1.0, 0.001)
	for idx in _wheels_all.size():
		var wheel := _wheels_all[idx]
		var anim := spin_basis
		if wheel in _wheels_front:
			anim = Basis(Vector3.UP, _wheel_steer) * spin_basis
		# Compunem PESTE transformarea originala, nu in locul ei.
		wheel.basis = anim * _wheel_orig[idx]
		# Mai multa compresie = roata mai sus fata de caroserie (distanta de la
		# prindere la centrul rotii e rest - compresie). Offsetul e in spatiul
		# modelului, deci impartit la scala.
		if idx < _wheel_corner.size():
			var corner: int = _wheel_corner[idx]
			var lift := (wheel_compression[corner] - _susp_static_comp) \
				* inv_scale
			wheel.position.y = _wheel_orig_pos[idx].y + lift

## Umbra blob: raycast in jos, discul sta pe sol indiferent unde e masina.
## Cu cat sari mai sus, cu atat umbra palste — dar iti arata aterizarea.
func _update_shadow() -> void:
	if _shadow == null:
		return
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.6, global_position + Vector3.DOWN * 30.0)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		_shadow.visible = false
		return
	_shadow.visible = true
	_shadow.global_position = (hit.position as Vector3) + Vector3.UP * 0.06
	_shadow.rotation = Vector3(0.0, rotation.y, 0.0)
	var height := global_position.y - (hit.position as Vector3).y
	# Cu umbre dinamice pornite caroseria arunca deja o umbra reala, iar
	# blob-ul peste ea dubla intunecarea sub masina. Ramane doar ca AO de
	# contact (0.16) — si ca semn de aterizare in aer, unde umbra reala cade
	# oriunde o duce soarele, dar blob-ul sta mereu sub roti. Fara umbre
	# (theme_shadows stins pe device), blob-ul e singura umbra, deci 0.38.
	var full := 0.38
	if track != null and track.theme_shadows:
		full = 0.16
	_shadow_mat.albedo_color.a = clampf(full - height * 0.03, 0.06, full)

func _update_visual_tilt(delta: float, steer: float, fwd_speed: float) -> void:
	# Pe fizica intreaga, CORPUL insusi se inclina: panta, ruliul, squat-ul si
	# dive-ul vin din suspensie, nu mai e nimic de desenat. Toata istoria
	# fake-pitch-ului (botul in sus la coborare, pivotul pe axul rotilor — vezi
	# git blame pe blocul asta) a murit odata cu CharacterBody3D.
	#
	# Ce ramane pe _visual: un STROP de ruliu suplimentar in drift — juice-ul
	# care vinde alunecarea, calibrat mic ca sa nu se bata cu ruliul fizic —,
	# invartirea de tromba (_update_spin) si reactiile de contact (jolt-ul unei
	# izbituri, aplecarea la frecare). Fiecare are STAREA ei, iar rotatia
	# vizuala se COMPUNE din ele la sfarsit: niciunul nu citeste inapoi din
	# `_visual.rotation` (cum facea lerp-ul vechi), deci niciunul nu-l mananca
	# pe celalalt.
	var speed_frac := clampf(fwd_speed / max_speed, 0.0, 1.0)
	# Pe sensul DRIFTULUI, nu al volanului: cu maparea CTR poti tine contravolan
	# in plina alunecare, iar caroseria tot spre exterior se lasa.
	var target_roll := -drift_dir * 0.05 * speed_frac * 1.6 * drift_blend
	# Reasezarea de la iesire: o jumatate de sinusoida in sens opus ruliului
	# de drift — spatele se prinde si caroseria tresare o data.
	if _snap_left > 0.0:
		_snap_left = maxf(_snap_left - delta, 0.0)
		target_roll += _snap_dir * 0.045 * speed_frac \
			* sin(PI * (1.0 - _snap_left / DRIFT_SNAP_TIME))
	_drift_roll = lerpf(_drift_roll, target_roll, 8.0 * delta)
	# Rotatia in plus a modelului in sensul driftului (drift_visual_yaw_deg),
	# dozata cu rampa, netezita ca sa nu sara la intrare; intra in compunere
	# ca termen de yaw, langa tromba (vezi _compose_visual).
	_drift_visual_yaw = lerpf(_drift_visual_yaw,
		drift_dir * deg_to_rad(drift_visual_yaw_deg) * _drift_amount(),
		minf(10.0 * delta, 1.0))
	_update_spin(delta)
	_update_jolt(delta)
	_compose_visual()
	_update_toys(delta, fwd_speed)


## Invartirea de caroserie, cat tine si pe urma inapoi la zero.
##
## Axa Y e singura libera in vechiul Euler (`_update_visual_tilt` scria pe Z),
## acum unghiul ramane doar un TERMEN al compunerii din `_compose_visual`,
## adunat cu rotatia in plus din drift (`_drift_visual_yaw`).
func _update_spin(delta: float) -> void:
	if _spin_left > 0.0:
		_spin_left -= delta
		_spin_angle = wrapf(_spin_angle + _spin_rate * delta, -PI, PI)
	elif not is_zero_approx(_spin_angle):
		# Botul se intoarce in fata la aterizare. O masina lasata strambă dupa ce
		# atinge solul citeste ca bug de rotatie, nu ca urmare a trombei.
		_spin_angle = lerp_angle(_spin_angle, 0.0, minf(7.0 * delta, 1.0))
		if absf(_spin_angle) < 0.01:
			_spin_angle = 0.0


## Cat de mare e varful deplasarii pe unitatea de viteza data arcului la
## lovitura (arc subamortizat pornit din repaus cu viteza v0:
## x(t) = v0/wd * e^(-z w t) * sin(wd t), maxim la tan(wd t) = wd / (z w)).
## Cu ea, `jolt_max_offset` e CHIAR varful vazut, nu o viteza oarecare.
func _jolt_peak_per_velocity() -> float:
	var w := jolt_freq
	var z := clampf(jolt_damping, 0.05, 0.95)
	var wd := w * sqrt(1.0 - z * z)
	var tp := atan2(wd, z * w) / wd
	return exp(-z * w * tp) * sin(wd * tp) / wd


## Un pas EXACT al unui arc subamortizat (x'' = -w^2 x - 2 z w x'), pe vectori:
## intoarce [x, v] dupa `dt`. Solutia inchisa, nu Euler — cu Euler la 60 Hz si
## 24 rad/s varful iesea cu un sfert mai mic decat cel calculat, iar revenirea
## se schimba cu rata de cadre.
static func spring_step(x: Vector3, v: Vector3, w: float, z: float,
		dt: float) -> Array[Vector3]:
	var wd := w * sqrt(1.0 - z * z)
	var e := exp(-z * w * dt)
	var c := cos(wd * dt)
	var s := sin(wd * dt)
	var k := z * w / wd
	var nx := (x * (c + k * s) + v * (s / wd)) * e
	var nv := (v * (c - k * s) - x * (w * w / wd * s)) * e
	return [nx, nv]


## Jolt + aplecare la frecare, un pas.
func _update_jolt(delta: float) -> void:
	var w := jolt_freq
	var z := clampf(jolt_damping, 0.05, 0.95)
	var dt := minf(delta, 0.05)
	var sp := Car.spring_step(_jolt_pos, _jolt_pos_vel, w, z, dt)
	_jolt_pos = sp[0]
	_jolt_pos_vel = sp[1]
	var st := Car.spring_step(_jolt_tilt, _jolt_tilt_vel, w, z, dt)
	_jolt_tilt = st[0]
	_jolt_tilt_vel = st[1]
	# Plafon: lovituri una dupa alta nu au voie sa scoata caroseria din cadru.
	_jolt_pos = _jolt_pos.limit_length(jolt_max_offset * 1.3)
	_jolt_tilt = _jolt_tilt.limit_length(deg_to_rad(jolt_max_tilt_deg) * 1.3)
	# Frecarea laterala cu alta masina: caroseria se apleaca ASTA de ea.
	var lean_target := Vector3.ZERO
	if rub_car != null and rub_speed > rub_min_speed 			and rub_normal != Vector3.ZERO:
		var n_local := global_transform.basis.inverse() * rub_normal
		n_local.y = 0.0
		if n_local.length_squared() > 1e-6:
			lean_target = n_local.normalized() * deg_to_rad(rub_lean_deg)
	# Urca repede (contactul solverului palpaie de la un cadru la altul), coboara
	# mai lent: aplecarea tine pe toata frecarea, nu pulseaza cu ea.
	var lean_rate := 18.0 if lean_target.length_squared() > _rub_lean.length_squared() else 6.0
	_rub_lean = _rub_lean.lerp(lean_target, 1.0 - exp(-lean_rate * dt))


## Singurul loc care scrie transformarea lui `_visual` (rotatia si pozitia;
## scala ramane a tween-urilor de squash). Ordinea e cea de Euler de dinainte
## (Y apoi Z: spin * ruliu de drift), cu aplecarea de contact in cadrul
## masinii, peste ele.
func _compose_visual() -> void:
	var tilt := _jolt_tilt + _rub_lean
	var q := Quaternion.IDENTITY
	if tilt.length_squared() > 1e-10:
		# Varful (UP) se deplaseaza spre `tilt` cand rotim in jurul lui UP x tilt.
		q = Quaternion(Vector3.UP.cross(tilt).normalized(), tilt.length())
	q = q * Quaternion(Vector3.UP, _spin_angle + _drift_visual_yaw) \
		* Quaternion(Vector3.BACK, _drift_roll)
	_visual.quaternion = q
	_visual.position = _jolt_pos


## Semnalul `impact` (feed-ul comun): impinge si apleaca caroseria vizuala, iar
## la perete aprinde si rafala de scantei. Fizica nu e atinsa.
func _on_impact_visual(_car: Car, kind: StringName, strength: float,
		normal: Vector3, point: Vector3, _other: Node) -> void:
	if _visual == null:
		return
	var k := clampf(sqrt(maxf(strength, 0.0) / maxf(jolt_full_dv, 0.1)), 0.0, 1.0)
	var n_local := global_transform.basis.inverse() * normal
	n_local.y = 0.0
	if n_local.length_squared() > 1e-6:
		n_local = n_local.normalized()
		var gain := 1.0 / maxf(_jolt_peak_per_velocity(), 1e-5)
		_jolt_pos_vel += n_local * (jolt_max_offset * k * gain)
		_jolt_tilt_vel += n_local * (deg_to_rad(jolt_max_tilt_deg) * k * gain)
	# Antena zvacneste in directia loviturii (varful ramane in urma caroseriei).
	if _toy_antenna != null and n_local.length_squared() > 1e-6:
		_ant_vel -= n_local * (clampf(strength, 0.0, 20.0) * 0.12 * ANT_FREQ)
	if kind == &"wall" and strength >= wall_spark_burst_dv:
		_emit_wall_sparks(point, normal, strength)
	if _driver != null:
		# „Lovit de" = nu mergeam eu spre ea: viteza de DINAINTE de impact
		# (inca _prev_velocity: semnalul pleaca din tick-ul propriu).
		var into := -Vector3(_prev_velocity.x, 0.0, _prev_velocity.z).dot(normal)
		_driver.react_impact(kind, strength, n_local,
			kind == &"car" and into < strength * 0.5)


## Repunerea sterge orice urma de jolt: masina apare asezata, nu zvacnind.
func _reset_visual_offsets(_c: Car = null) -> void:
	_jolt_pos = Vector3.ZERO
	_jolt_pos_vel = Vector3.ZERO
	_rattle_burst = 0.0
	_rattle_drive_smooth = 0.0
	toy_rattle = 0.0
	_jolt_tilt = Vector3.ZERO
	_jolt_tilt_vel = Vector3.ZERO
	_rub_lean = Vector3.ZERO
	_ant_tilt = Vector3.ZERO
	_ant_vel = Vector3.ZERO
	if _visual != null:
		_compose_visual()

## Modelul 3D al unei masini, cu scala si rotatia din CarData, fara fizica.
## Static ca sa-l poata folosi si fantoma din contratimp (GhostCar) — acelasi
## model, aceeasi orientare, fara sa dubleze cifrele. Null daca masina nu are
## model (placeholder-ul de cuburi ramane doar al lui `_build_visual`).
static func build_model(car_data: CarData) -> Node3D:
	if car_data == null or car_data.model == null:
		return null
	var model := car_data.model.instantiate() as Node3D
	model.scale = Vector3.ONE * car_data.model_scale
	model.rotation.y = deg_to_rad(car_data.model_rotation_deg)
	return model


## ---------------------------------------------------------------- jucaria

## Mesh de caroserie al modelului (fara roti), in spatiul `_visual`: fiecare
## intrare are TriangleMesh-ul, transformarea si cutia. Pentru raze.
func _toy_collect(n: Node3D, parent_xf: Transform3D, out: Array) -> void:
	var t := parent_xf * n.transform
	var low := String(n.name).to_lower()
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null and not ("wheel" in low or "tire" in low):
		out.append({"tm": mi.mesh.generate_triangle_mesh(), "xf": t,
			"box": t * mi.mesh.get_aabb()})
	for c in n.get_children():
		if c is Node3D:
			_toy_collect(c as Node3D, t, out)


## Cea mai apropiata intersectie a razei cu caroseria; gol daca nu ataca nimic.
static func toy_ray(parts: Array, from: Vector3, dir: Vector3) -> Dictionary:
	var best := {}
	var best_d := INF
	for part: Dictionary in parts:
		var xf: Transform3D = part["xf"]
		var inv := xf.affine_inverse()
		var hit: Dictionary = (part["tm"] as TriangleMesh).intersect_ray(
			inv * from, (inv.basis * dir).normalized())
		if hit.is_empty():
			continue
		var p: Vector3 = xf * (hit["position"] as Vector3)
		var d := from.distance_to(p)
		if d < best_d:
			best_d = d
			best = {"position": p, "distance": d}
	return best


## Mesh primitiv cu UV-urile puse pe slotul de paleta (ca restul lumii: o
## singura textura de atlas, zero materiale noi) si culoare de vertex alba.
static func _toy_mesh(prim: PrimitiveMesh, slot: int) -> ArrayMesh:
	var arrays := prim.get_mesh_arrays()
	var n := (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var uvs := PackedVector2Array()
	uvs.resize(n)
	uvs.fill(Palette.uv(slot))
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var cols := PackedColorArray()
	cols.resize(n)
	cols.fill(Color(0.96, 0.96, 0.96))
	arrays[Mesh.ARRAY_COLOR] = cols
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


static func _toy_part(parent: Node3D, mesh: PrimitiveMesh, slot: int,
		pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _toy_mesh(mesh, slot)
	mi.material_override = Palette.world_material()
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Antena si cheia, montate pe suprafata modelului: antena pe coltul din
## dreapta-spate (raza de sus in jos gaseste cota caroseriei acolo), cheia in
## mijlocul fetei din spate (raza dinspre spate gaseste fata). Daca raza nu
## gaseste nimic, piesa nu se monteaza — mai bine lipsa decat plutind.
func _build_toys(model: Node3D) -> void:
	var parts: Array = []
	_toy_collect(model, Transform3D.IDENTITY, parts)
	if parts.is_empty():
		return
	var box: AABB = (parts[0]["box"] as AABB)
	for part: Dictionary in parts:
		box = box.merge(part["box"])
	var unit := clampf(box.size.x / 2.2, 0.6, 1.3)
	# Antena: candidati (x ca fractie din latime, z = distanta de spatele
	# modelului, in unitati), intai coltul din dreapta-spate. Se alege primul la
	# care raza gaseste caroseria SI vergeaua, in repaus si inclinata la 0.25 rad
	# in 8 directii, nu intalneste niciun triunghi (un buggy deschis sau un
	# camion cu scara nu au caroserie sub orice punct).
	var length := 0.95 * unit
	var spots := [Vector2(0.84, 0.45), Vector2(0.16, 0.45), Vector2(0.84, 0.9),
		Vector2(0.16, 0.9), Vector2(0.7, 0.45), Vector2(0.3, 0.45),
		Vector2(0.84, 1.4), Vector2(0.16, 1.4), Vector2(0.5, 0.45)]
	var ant_base := Vector3.ZERO
	var found := false
	for spot: Vector2 in spots:
		var ax := box.position.x + box.size.x * spot.x
		var az := box.end.z - spot.y * unit
		var top := toy_ray(parts, Vector3(ax, box.end.y + 1.0, az), Vector3.DOWN)
		if top.is_empty():
			continue
		var base: Vector3 = (top["position"] as Vector3) - Vector3(0, 0.03, 0)
		if _toy_segments_clear(parts, base, length):
			ant_base = base
			found = true
			break
	if found:
		var ant := Node3D.new()
		ant.name = "ToyAntenna"
		ant.position = ant_base
		_visual.add_child(ant)
		var stem := CylinderMesh.new()
		stem.top_radius = 0.022 * unit
		stem.bottom_radius = 0.03 * unit
		stem.height = length
		stem.radial_segments = 6
		stem.rings = 1
		_toy_part(ant, stem, Palette.ASPHALT, Vector3(0, length * 0.5, 0))
		var tip := SphereMesh.new()
		tip.radius = 0.085 * unit
		tip.height = 0.17 * unit
		tip.radial_segments = 8
		tip.rings = 4
		_toy_part(ant, tip, Palette.KERB_RED, Vector3(0, length + 0.03 * unit, 0))
		_toy_antenna = ant
	# Cheia: pe fata din spate. Raze dinspre spate la cateva inaltimi (30-70% din
	# cutie) si doua pozitii laterale, ferite de axa (acolo sta placuta de
	# inmatriculare, galbena si ea); se alege cea mai din spate suprafata (panoul
	# portbagajului, nu scaunul din interior). Apoi o departeaza de fata pana
	# cand nicio aripa, in niciun unghi, nu mai taie caroseria.
	var key_hit := {}
	for fx: float in [-0.3, 0.3]:
		for f: float in [0.3, 0.4, 0.5, 0.6, 0.7]:
			var ky := box.position.y + box.size.y * f
			var kx := box.get_center().x + box.size.x * fx
			var h := toy_ray(parts, Vector3(kx, ky, box.end.z + 1.5), Vector3(0, 0, -1))
			if h.is_empty():
				continue
			if key_hit.is_empty() or (h["position"] as Vector3).z > (key_hit["position"] as Vector3).z + 0.02:
				key_hit = h
	if not key_hit.is_empty():
		var kp: Vector3 = (key_hit["position"] as Vector3) + Vector3(0, 0, -0.02)
		var sc := clampf(box.size.x * 0.2, 0.3, 0.7)
		var stand := 0.0
		while stand < 0.6 and not _toy_key_clear(parts, kp, sc, stand):
			stand += 0.05
		if stand >= 0.6:
			return # nicio departare nu scoate aripile din caroserie: fara cheie
		var key := Node3D.new()
		key.name = "ToyKey"
		key.position = kp
		_visual.add_child(key)
		var shaft_len := 0.3 * sc + stand
		var shaft := CylinderMesh.new()
		shaft.top_radius = 0.05 * sc
		shaft.bottom_radius = 0.05 * sc
		shaft.height = shaft_len
		shaft.radial_segments = 6
		shaft.rings = 1
		_toy_part(key, shaft, Palette.CAR_BLUE, Vector3(0, 0, shaft_len * 0.5),
			Vector3(PI * 0.5, 0, 0))
		for side in [-1.0, 1.0]:
			var wing := BoxMesh.new()
			wing.size = Vector3(0.62 * sc, 0.32 * sc, 0.07 * sc)
			_toy_part(key, wing, Palette.CAR_BLUE,
				Vector3(side * 0.34 * sc, 0, shaft_len + 0.02 * sc))
		_toy_key = key


## Segment liber de caroseria? (primul triunghi lovit e dincolo de capat.)
static func _toy_clear(parts: Array, a: Vector3, b: Vector3) -> bool:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return true
	var hit := toy_ray(parts, a, d / l)
	return hit.is_empty() or float(hit["distance"]) > l - 0.01


## Vergeaua antenei, de la `base` in sus, in repaus si inclinata la 0.25 rad in
## 8 directii, libera de caroserie.
static func _toy_segments_clear(parts: Array, base: Vector3, length: float) -> bool:
	var from := base + Vector3(0, 0.06, 0)
	if not _toy_clear(parts, from, base + Vector3(0, length + 0.1, 0)):
		return false
	for k in 8:
		var yaw := TAU * k / 8.0
		var tilted := base + Vector3(sin(0.25) * cos(yaw), cos(0.25),
			sin(0.25) * sin(yaw)) * (length + 0.1)
		if not _toy_clear(parts, from, tilted):
			return false
	return true


## Aripile cheii (12 unghiuri de rotatie) libere de caroserie, cu fusul
## prelungit cu `stand`.
static func _toy_key_clear(parts: Array, kp: Vector3, sc: float, stand: float) -> bool:
	var axis := kp + Vector3(0, 0, 0.3 * sc + stand + 0.02 * sc)
	for k in 12:
		var a := TAU * k / 12.0
		var tip := axis + Vector3(cos(a) * 0.68 * sc, sin(a) * 0.68 * sc, 0)
		if not _toy_clear(parts, axis, tip):
			return false
	return true


## Aterizare dura: rafala de zdranganeala proportionala cu caderea.
func _on_landed_rattle(_car: Car, fall_speed: float) -> void:
	_rattle_burst = maxf(_rattle_burst,
		clampf(fall_speed / maxf(rattle_land_full_fall, 0.1), 0.0, 1.0))


## Nivelul de zdranganeala (0..1) in `toy_rattle` si tremurul acestui cadru
## (doua axe, ~±1): suma de trei sinusoide neinrudite sub frecventa Nyquist a
## cadrului de fizica — pare zgomot rapid, nu o unda. Sursele de teren cer
## roti pe sol si viteza; rafala de aterizare nu depinde de nici una.
func _update_rattle(dt: float, fwd_speed: float) -> Vector2:
	var surface := 0.0
	if toy_rattle_enabled and wheels_on_ground > 0:
		if on_kerb:
			surface = rattle_kerb
		if on_steps:
			surface = maxf(surface, rattle_steps)
		if _toy_loose:
			surface = maxf(surface, rattle_loose)
	var speed_k := clampf(inverse_lerp(rattle_min_speed, rattle_full_speed,
		absf(fwd_speed)), 0.0, 1.0)
	var drive := surface * speed_k
	var rate := rattle_attack if drive > _rattle_drive_smooth else rattle_release
	_rattle_drive_smooth = move_toward(_rattle_drive_smooth, drive, rate * dt)
	_rattle_burst = maxf(_rattle_burst - dt / maxf(rattle_land_decay_s, 0.05), 0.0)
	toy_rattle = clampf(maxf(_rattle_drive_smooth,
		_rattle_burst if toy_rattle_enabled else 0.0), 0.0, 1.0)
	if toy_rattle < 0.001:
		return Vector2.ZERO
	_rattle_t += dt
	var t := _rattle_t
	return Vector2(
		(sin(TAU * 26.3 * t) + 0.8 * sin(TAU * 17.1 * t + 1.3)
			+ 0.6 * sin(TAU * 11.7 * t + 2.9)) / 2.4,
		(sin(TAU * 23.9 * t + 0.7) + 0.8 * sin(TAU * 14.3 * t + 2.2)
			+ 0.6 * sin(TAU * 9.1 * t + 4.1)) / 2.4)


## Antena (arc fortat de acceleratie) si cheia (turatie dupa viteza).
func _update_toys(delta: float, fwd_speed: float) -> void:
	var dt := minf(delta, 0.05)
	var jit := _update_rattle(dt, fwd_speed)
	if _toy_antenna != null:
		# Acceleratia masinii in spatiul ei; varful ramane in urma ei.
		var acc := (velocity - _prev_velocity) / maxf(delta, 0.0001)
		var a_local := global_transform.basis.inverse() * acc
		a_local.y = 0.0
		var target := (-a_local * ANT_PER_ACCEL).limit_length(ANT_MAX)
		var sp := Car.spring_step(_ant_tilt - target, _ant_vel, ANT_FREQ, ANT_DAMPING, dt)
		_ant_tilt = (sp[0] as Vector3) + target
		_ant_vel = sp[1]
		_ant_tilt = _ant_tilt.limit_length(ANT_MAX * 1.4)
		# Zdranganeala se adauga DOAR la desen: starea arcului ramane curata.
		var drawn := _ant_tilt + Vector3(jit.x, 0.0, jit.y) * (rattle_ant_rad * toy_rattle)
		var q := Quaternion.IDENTITY
		if drawn.length_squared() > 1e-10:
			q = Quaternion(Vector3.UP.cross(drawn).normalized(), drawn.length())
		_toy_antenna.quaternion = q
	if _toy_key != null:
		var f := clampf(absf(fwd_speed) / maxf(max_speed, 1.0), 0.0, 1.2)
		_key_angle = fposmod(_key_angle + lerpf(KEY_SPIN_MIN, KEY_SPIN_MAX, f)
			* signf(fwd_speed if absf(fwd_speed) > 0.5 else 1.0) * dt, TAU)
		# Cheia sta slab pe ax: pe teren aspru se clatina in jurul lui X si Y.
		var wob := Vector2(jit.y, jit.x) * (rattle_key_rad * toy_rattle)
		_toy_key.rotation = Vector3(wob.x, wob.y, _key_angle)


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	_toy_antenna = null
	_toy_key = null
	_ant_tilt = Vector3.ZERO
	_ant_vel = Vector3.ZERO
	# Model 3D real daca exista in CarData; altfel placeholder din cuburi.
	if data != null and data.model != null:
		var model := Car.build_model(data)
		_visual.add_child(model)
		# Gasim rotile dupa nume, ca sa le animam (spin + viraj + compresie).
		_wheels_all.clear()
		_wheels_front.clear()
		_wheel_orig.clear()
		_wheel_orig_pos.clear()
		_wheel_corner.clear()
		for child in model.get_children():
			var child_name := String(child.name).to_lower()
			if child is Node3D and "wheel" in child_name:
				var wheel_node := child as Node3D
				_wheels_all.append(wheel_node)
				_wheel_orig.append(wheel_node.basis)
				_wheel_orig_pos.append(wheel_node.position)
				var is_front := "front" in child_name
				if is_front:
					_wheels_front.append(wheel_node)
				# Coltul de suspensie al rotii vizuale. Modelul e rotit 180°
				# (privea spre +Z), deci stanga masinii = +x in spatiul
				# modelului — de-aia conditia pare inversata.
				var car_left := wheel_node.position.x > 0.0
				var axle := 0 if is_front else 1
				_wheel_corner.append(axle * 2 + (0 if car_left else 1))
		if data.toy_animation:
			_build_toys(model)
		if not _wheels_all.is_empty():
			# Raza reala = inaltimea centrului rotii (sta pe sol) x scala.
			_wheel_radius = maxf(0.15,
				_wheels_all[0].position.y * data.model_scale)
		# Pe fizica intreaga pivotul vizual nu mai conteaza: corpul intreg se
		# inclina fizic in jurul propriului centru de masa, iar modelul sta
		# simplu la origine. Hack-ul "pivot pe axul rotilor" de pe
		# CharacterBody a murit odata cu fake-pitch-ul.
		return
	# Placeholder din cuburi, cand masina n-are model in CarData.
	_wheel_radius = 0.48
	_add_box(Vector3(2.2, 0.7, 3.6), Vector3(0, 0.55, 0), body_color)
	_add_box(Vector3(1.6, 0.55, 1.7), Vector3(0, 1.1, 0.2),
		body_color.darkened(0.5))
	_add_box(Vector3(2.3, 0.18, 0.7), Vector3(0, 0.9, 1.85),
		body_color.darkened(0.25))
	for corner in [Vector3(-1.05, 0.45, -1.2), Vector3(1.05, 0.45, -1.2),
			Vector3(-1.05, 0.45, 1.25), Vector3(1.05, 0.45, 1.25)]:
		var wheel := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.48
		cyl.bottom_radius = 0.48
		cyl.height = 0.42
		wheel.mesh = cyl
		wheel.rotation.z = PI / 2.0
		wheel.position = corner
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.1, 0.1)
		wheel.material_override = mat
		_visual.add_child(wheel)

func _add_box(size: Vector3, pos: Vector3, color: Color) -> void:
	var inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	inst.mesh = mesh
	inst.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	inst.material_override = mat
	_visual.add_child(inst)
