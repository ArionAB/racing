@tool
class_name WaterfallHazard
extends Area3D
## CASCADA PESTE DRUM (Fiordland, brief §2 POI C / §3 „Cascada peste drum").
##
## O perdea de apa care cade PESTE sosea, de-a lungul unei portiuni de `length`
## metri, pe toata latimea `thickness`. Cat esti sub ea primesti doua lucruri,
## simultan:
##   - o ACCELERATIE constanta in jos (`force_accel`, m/s2), aplicata prin
##     `apply_central_force(Vector3.DOWN * mass * force_accel)` — vezi
##     `BurnerHazard` pentru de ce e acceleratie si nu impuls: acelasi motiv,
##     acelasi cod (aceeasi acceleratie pentru orice masa = AI onest, si o
##     rulare repetata da acelasi rezultat, nu o loterie de cadru);
##   - o FRANARE pe componenta orizontala a vitezei (`drag`, 1/s), fiindca
##     apa care cade nu doar apasa, ci si franeaza inaintarea.
##
## [b]De ce forta in jos, nu un impuls la intrare.[/b] Perdeaua are `length`
## metri, deci masina STA sub ea cateva zecimi de secunda — nu e o lovitura, e
## o GREUTATE in plus cat timp esti dedesubt. O acceleratie continua se simte
## ca apa care curge; un impuls unic ar fi un zid invizibil la intrare, exact
## capcana descrisa in `BurnerHazard`.
##
## [b]De ce nu inventeaza a doua notiune de "atinge fundul".[/b] Suspensia pe
## raycast (`Car._apply_suspension`) tine deja compresia fiecarui arc in
## `wheel_compression` (0..`suspension_rest`); cand compresia atinge cursa
## intreaga, arcul e la fund — nu exista alt semnal si nu trebuie inventat
## unul nou. Sonda (`probe_fiord_cascada.gd`) citeste `wheel_compression`
## direct, hazardul insusi nu are nevoie sa stie de bottom-out: forta in jos
## creste sarcina pe roti (deci gripul, e realist — downforce), iar cine
## atinge fundul o face din SUSPENSIA LUI (`CarData.spring_freq`/
## `suspension_rest`), nu din vreun cod special de-al hazardului. Asta e
## exact ce trebuie sa difere intre masini (Buggy moale vs. Politie rigida).
##
## [b]Albirea[/b] se face prin REFOLOSIREA `FogCorridorHazard`-ului ca ceata
## LOCALA de-a lungul zonei (nu `Car.blind()`, care e o clipa alba pe tot
## ecranul): o instanta interna de `FogCorridorHazard`, cu acelasi `length`,
## impinsa spre o culoare aproape alba pe toata adancimea perdelei — cat esti
## in cascada, vezi prin ea ca prin ceata deasa, nu esti orbit brusc. E
## exact contractul de "cost zero, zero draw calls" din `FogCorridorHazard`.
## Nu exista timp `whiteout` separat de tinut: cat timp ceata a corpului e
## in zona, ea E albirea; `whiteout` ramane totusi ca export, pentru viitor
## (variante cu un puf de abur care se stinge dupa iesire) si pentru sonde
## care vor sa citeasca "cat ar trebui sa tina" ca referinta.
##
## [b]Capcana pentru orice sonda viitoare pe albire.[/b] `FogCorridorHazard`
## (deci si `_fog` de aici) cauta un `WorldEnvironment` pe scena
## (`_find_env`) si, daca nu gaseste unul, RENUNTA DEFINITIV — se intoarce
## mai devreme din `_physics_process` la fiecare cadru, pentru totdeauna, nu
## doar cadrul curent. Intr-un harnas sintetic FARA `WorldEnvironment` (cum
## sunt sondele tehnice de teren/fizica), `fog_amount()` ramane 0.0 tot
## timpul — nu pentru ca albirea nu functioneaza, ci pentru ca n-are ce
## mediu sa impinga. Orice sonda care vrea sa verifice albirea (nu doar
## forta/compresia) trebuie sa adauge un `WorldEnvironment` cu `Environment`
## minimal in scena INAINTE de primul `_physics_process` al hazardului.
##
## [b]Ploaia (`rain_factor`).[/b] `RainCycle` (nescris inca — vine dupa sonda,
## §7 pasul 6) va seta `rain_factor` peste 1.0 in faza de ploaie: forta si
## latimea perdelei cresc (brief: "in ploaie perdeaua e cu 30% mai grea si cu
## 5 m mai lata"). Aici `rain_factor` e doar un export citit direct — hazardul
## nu stie de unde vine valoarea, la fel cum `FogCorridorHazard` nu stie cine
## ii comanda ceata.
##
## [b]Runda 2 — forta se scaleaza cu viteza (`speed_ref`/`min_speed_factor`),
## ca sa rupa o bucla pozitiva.[/b] La `force_accel` constant (runda 1: 40),
## Autobuzul si Pompierii intrau intr-o bucla: apasare mare -> compresie mare
## -> frecare/franare mare -> viteza mica -> RAMANE mai mult timp sub apasare
## (aceeasi forta, dar mai multe secunde din ea) -> compresie SI MAI mare.
## Masurat: pana la 1300+ cadre (>20 s) la fund, pierderi de 40-100%. Solutia
## (decizia coordonatorului): apasarea nu mai e constanta, ci proportionala cu
## viteza ORIZONTALA CURENTA a masinii — ca o lovitura de apa: masina lenta ia
## putin, cea rapida ia mult. Factorul se recalculeaza in FIECARE tick din
## viteza de ACUM (nu cea de la intrarea in zona), exact ca sa rupa bucla: cand
## masina incetineste, apasarea scade odata cu ea, deci nu se mai auto-alimenteaza.
## Efect secundar dorit, nu bug: turbo prin perdea = mai putin timp sub apasare,
## dar apasare mai mare cat timp esti inauntru — un trade-off, nu o scapare
## gratuita.
##
## [b]Varianta "cascada de ploaie" (teatru, cost zero).[/b] `force_accel = 0`
## dezactiveaza forta si franarea, dar pastreaza albirea si vizualul — exact
## ce cere brief-ul §3 pentru cele 5 fire false de pe pereti. Acelasi script,
## alt export, zero cod nou.
##
## [b]Vizualul[/b] e `WaterfallVisual` (scenes/hazards/waterfall_visual.gd):
## panze verticale incrucisate cu `waterfall.gdshader` (dungi care curg,
## margini topite continuu), placa de spuma la sol si spray din
## `GPUParticles3D` — O SINGURA clasa vizuala pentru Stirling, cele 5 de
## ploaie si Bowen (brief §5.1 `waterfall`, §6: un material de shader
## partajat + un material de spray partajat pe toata pista). A inlocuit
## placeholder-ul din sonda (o cutie pe FOAM_WHITE — „un bloc mare alb",
## verdictul dezvoltatorului la volan). Vizualul e construit in ACELASI reper
## cu forma de coliziune (X grosime, Z lungime), ca ce vezi sa fie ce simti.
##
## [b]Fade-ul de ploaie.[/b] `RainCycle` comuta grupul `rain_falls` prin
## `visible` si, daca nodul are proprietatea, prin `modulate.a` — `modulate`
## de aici exista exact pentru mecanismul acela (nu un al doilea): alpha-ul
## lui e impins in `WaterfallVisual.set_intensity()`.
##
## [b]`set_physics_enabled(on)` — comutator separat de vizibilitate
## (Torrent, Fiordland, `torrent_cycle.gd`).[/b] `_physics_process` aplica
## `drag`-ul (si `force_accel`, si albirea) de cate ori zona e ACTIVA
## (`is_visible_in_tree() and modulate.a > 0.001`) — ceea ce e corect pentru
## o cascada constanta, dar gresit pentru un puls: un fir SUBTIRE de teatru
## (`modulate.a` mic, dar > 0, in faza de calm a torentului) e vizibil, deci
## ar franea si ar albi masina in continuu, desi brief-ul cere fizica NUMAI
## in puls. `set_physics_enabled(false)` lasa perdeaua monitorizata si
## vizibila (splash-ul de intrare tot declanseaza — e teatru, nu fizica) dar
## taie forta ORIZONTALA/verticala SI albirea (`_fog.set_active`); `true`
## reactiveaza ambele fara sa schimbe `modulate`. Implicit `true` — orice alt
## chemator (pista veche, sondele existente) e neschimbat.

const FogCorridorHazardScript = preload("res://scenes/hazards/fog_corridor_hazard.gd")

@export_group("Zona")
## Lungimea perdelei de-a lungul drumului (m). Brief: 30 (45 in varianta lata
## de ploaie, vezi `rain_factor`).
@export_range(4.0, 80.0, 0.5) var length: float = 30.0:
	set(value):
		length = value
		_rebuild()
## Latimea perdelei (m), perpendicular pe drum. Brief: 6 (perdeaua "prin", nu
## pragul uscat din spate — acela e geometrie de pista, nu hazardul).
@export_range(1.0, 30.0, 0.5) var thickness: float = 6.0:
	set(value):
		thickness = value
		_rebuild()
## Inaltimea vizuala a perdelei (m) — doar vizual; cascada reala cade de la
## un surplomb, dar zona de forta nu are nevoie de inaltimea aia. Varful se
## topeste continuu in alpha (`top_frac` din shader), deci nu e o muchie.
@export_range(2.0, 40.0, 0.5) var visual_height: float = 14.0:
	set(value):
		visual_height = value
		_rebuild()

@export_group("Forta")
## Acceleratia in jos (m/s2), aplicata ca `apply_central_force(DOWN * mass *
## force_accel * rain_factor)`. 0 = cascada de ploaie (teatru, fara forta).
##
## [b]Brief-ul cerea ~12; sonda a masurat ca 12 NU ajunge la efectul cerut.[/b]
## Arcul e liniar (comp_static = (gravity + force_accel) / omega^2): la 12,
## compresia STATICA de echilibru pentru Buggy (cea mai moale suspensie) e
## doar ~52% din cursa — nici macar sustinuta la nesfarsit nu atinge fundul,
## darmite tranzitand 30 m in ~1.2-2 s.
##
## [b]Runda 1[/b] a gasit 40 ca punct unde Buggy atinge fundul si Politia nu,
## dar la `force_accel` CONSTANT, Autobuzul/Pompierii intrau intr-o bucla
## pozitiva (apasare -> compresie -> franare -> viteza mica -> mai mult timp
## sub apasare -> compresie SI MAI mare): masurat pana la 1300+ cadre (>20 s)
## la fund si pierderi de 40-100%.
##
## [b]Runda 2[/b] (coordonator): a rupt bucla scaland apasarea cu viteza
## CURENTA (`speed_ref`/`min_speed_factor`) SI cu compresia curenta
## (`compression_ease_start`/`compression_ease_min`), plus a scazut `drag`
## la 0.25 (pierderea mare la Autobuz/Pompieri venea mai ales din franarea
## ORIZONTALA in dwell time lung, nu din apasarea verticala — verificat:
## la `force_accel=0`, Autobuzul tot pierdea ~37%). Cu toate patru
## impreuna (`force_accel=48`, `drag=0.25`, `compression_ease_start=0.72`,
## `compression_ease_min=0.15`), sonda (`probe_fiord_cascada.gd`, matrice
## completa: 6 masini x 15/25 m/s x rain 1.0/1.3 x 3 repetari + 10 m/s pentru
## Autobuz/Pompierii) trece toate cele 4 criterii ale rundei 2: nicio masina
## nu pierde peste 35% la 25 m/s uscat (Autobuzul: 21.3%, cel mai mare),
## niciun timp la fund peste 0.5 s (cel mai lung: EXACT 0.50 s, Autobuzul la
## 25 m/s + ploaie — zero marja, vezi raportul sondei), Buggy atinge fundul
## scurt (0.03 s) pe uscat la 25 m/s si Politia nu (78.4%), zero rasturnari.
@export_range(0.0, 60.0, 0.5) var force_accel: float = 48.0
## Viteza orizontala (m/s) la care se aplica `force_accel` INTREG. Sub ea,
## apasarea scade proportional (vezi `_speed_factor`); peste ea, creste (dar
## plafonata la `1.5x` — vezi clamp-ul din `_speed_factor`). 25 = viteza de
## test standard din brief pentru „25 m/s pe uscat, fara turbo".
@export_range(5.0, 40.0, 1.0) var speed_ref: float = 25.0
## Podeaua factorului de viteza — cat ramane din `force_accel` la viteza
## foarte mica (0 m/s si sub). Nu 0: o masina aproape oprita sub cascada tot
## trebuie sa simta ceva apa, altfel bucla s-ar opri prin disparitia totala a
## fortei (echivalent cu „ai scapat gratis daca te opresti"), nu prin
## echilibru. 0.25 = un sfert din forta de referinta.
@export_range(0.0, 1.0, 0.05) var min_speed_factor: float = 0.25
## Varianta B (runda 2): apasarea slabeste SUPLIMENTAR cand arcul e aproape
## de fund, ca sa nu tina masina blocata la 100% timp de secunde intregi.
## Peste `compression_ease_start` (fractie din cursa), factorul de compresie
## scade liniar spre `compression_ease_min` la 100%.
##
## [b]Necesara impreuna cu varianta A[/b] (scalarea cu viteza): masurat ca
## varianta A singura (force_accel constant scalat doar cu viteza) tot lasa
## Autobuzul/Pompierii cu 3-7 s la fund — scalarea cu viteza rupe CRESTEREA
## nelimitata a buclei, dar nu scurteaza destul timpul petrecut la fund odata
## ce arcul a ajuns acolo. 0.72 e valoarea gasita prin sweep (0.5-0.85):
## suficient de devreme cat sa scurteze bottom-out-ul Autobuz/Pompieri sub
## 0.5 s, dar nu atat de devreme incat sa scada compresia Buggy sub pragul de
## 97% la 25 m/s uscat (testat: la 0.75+ Buggy nu mai atinge fundul acolo).
@export_range(0.0, 1.0, 0.05) var compression_ease_start: float = 0.72
## Cat mai ramane din acceleratie la compresie 100%, daca
## `compression_ease_start` > 0. 0.15 gasit prin acelasi sweep ca mai sus.
@export_range(0.0, 1.0, 0.05) var compression_ease_min: float = 0.15
## Franarea pe componenta ORIZONTALA a vitezei, ca fractie pe secunda
## (`v -= v_horiz * drag * delta`). Calibrat pe sonda (`probe_fiord_cascada.gd
## --drag=`, sweep 0.0-0.5) CU GAZUL APASAT (nu in ruliu liber — vezi nota
## din sonda despre drag-ul intrinsec al lui Car).
##
## [b]Runda 2:[/b] coborat de la 0.45 la 0.25. Descoperire-cheie: pierderea
## excesiva de viteza a Autobuzului/Pompierilor (37-57% in runda 1) NU vine
## in principal din apasarea verticala (`force_accel`) — masurat: chiar la
## `force_accel = 0` (fara nicio forta in jos), Autobuzul tot pierdea ~37%,
## doar din `drag`-ul orizontal al hazardului combinat cu motorul lor slab
## (acceleration 11-12 vs 15-17 la restul garajului) si dwell time-ul mai
## lung (mai aproape de `speed_ref`, deci factorul de viteza nu-i ajuta).
## La 0.25, Autobuzul/Pompierii raman sub plafonul de 35% (21-22%), iar
## Muscle/Politia/Taxi/Buggy scad si ei (2-8%) — inca sub orice plafon cerut,
## nu sub vreo tinta minima (runda 2 n-are prag de jos, doar plafon).
@export_range(0.0, 3.0, 0.05) var drag: float = 0.25
## Multiplicator din faza de ploaie (`RainCycle`, viitor): la 1.3, forta
## creste si zona se face cu 5 m mai lata (brief). Citit direct, hazardul nu
## stie cine il seteaza.
@export_range(0.5, 2.0, 0.01) var rain_factor: float = 1.0:
	set(value):
		rain_factor = value
		_rebuild()
## Cat de multi metri se adauga la `thickness` la `rain_factor` = 1.3 (brief:
## +5 m la perdeaua lata de ploaie). Interpolat liniar intre 1.0 si 1.3.
@export_range(0.0, 15.0, 0.5) var rain_extra_thickness: float = 5.0

@export_group("Vizual")
## Cati stropi de spray la baza (brief §6: overdraw-ul e bugetul real). 48
## la Stirling, 16 la o cascada de ploaie; 0 = fara spray.
@export_range(0, 64, 1) var spray_count: int = 48:
	set(value):
		spray_count = value
		_rebuild()
## Citit/scris de `RainCycle` (`_node_alpha`/`_set_node_alpha`): alpha-ul e
## intensitatea vizualului (0 = stins). Culoarea nu e folosita.
@export var modulate: Color = Color.WHITE:
	set(value):
		modulate = value
		if _visual != null and is_instance_valid(_visual):
			_visual.set_intensity(value.a)

@export_group("Impact la intrare")
## Runda 3 (verdict la volan, sep 2026): „cand trec prin cascada nu simt
## nimic" / „nu are niciun impact asupra soferului". `force_accel` comprima
## suspensia (verticala, invizibila din chase cam); ce lipsea era o lovitura
## pe planul pe care jucatorul CHIAR il vede — orizontal, la intrare, o
## singura data (nu continuu, ca `force_accel`; apa te matura o data, nu te
## tine impinsa lateral cat esti sub ea).
##
## Impuls LATERAL (m/s, `Car.apply_sweep`) aplicat o singura data la INTRARE,
## pe directia `push_dir` (in spatiul LOCAL al perdelei — X e latimea, acelasi
## reper ca forma de coliziune). 0 = fara impuls (variantele de teatru/ploaie
## raman neschimbate, `force_accel=0` deja le scoate din calcul mai jos).
## Stirling: brief-ul cere impuls spre marginea dinspre mare, FARA parapet —
## risc real, nu o palma spre pragul uscat sigur.
@export_range(0.0, 20.0, 0.5) var push_speed: float = 9.0
## Directia impulsului lateral, in spatiul LOCAL (X = latimea perdelei, Z =
## lungimea de-a lungul drumului — acelasi reper ca `_build_shape`). Nu
## trebuie normalizat: se normalizeaza la aplicare. Implicit +X; fiecare
## instanta isi seteaza semnul dupa geometria ei (Stirling: spre mare, vezi
## nota din Track16 unde se instantiaza).
@export var push_dir: Vector3 = Vector3.RIGHT
## Smucitura de yaw (rad/s) prin `Car.apply_yaw_kick` — sabotaj de control
## scurt, NU un cuplu fizic (memoria `yaw-ul-masinii-e-rescris-pe-tick`:
## `apply_torque_impulse` pe Car e mort, `angular_velocity` se rescrie in
## fiecare tick din `yaw_rate + kick`). Semnul urmeaza `push_dir` (impinsa
## spre dreapta = si botul fuge usor spre dreapta, ca un vehicul real lovit
## lateral de un perete de apa). 0 = fara smucitura.
@export_range(0.0, 4.0, 0.1) var yaw_kick_rate: float = 1.4
@export_range(0.0, 1.0, 0.05) var yaw_kick_seconds: float = 0.35
## Trauma de camera la intrare (`Car.splash` -> `Race` -> `camera.add_trauma`,
## acelasi lant ca la valul de pe dig — vezi `wave_surge.gd`). Shake-ul e
## trauma^2, deci valorile mici practic nu se vad; 0.55 da un zguduit clar
## fara sa acopere ecranul ca la un val intreg (`WaveSurge.SPLASH_TRAUMA`
## 0.75, pentru un perete de apa mai mare).
@export_range(0.0, 1.0, 0.05) var splash_trauma: float = 0.55
## Cat picura masina dupa iesire (s, `Car.douse`) — vizibil pe caroserie
## cateva secunde, nu doar in cadrul impactului. 0 = fara picurat.
@export_range(0.0, 6.0, 0.5) var douse_seconds: float = 3.0
## Sfx la intrare, prin `AudioManager.play_sfx` (grupul `SFX`, nu un stream
## dedicat pe hazard — o lovitura scurta, nu un loop). Numele trebuie sa
## existe in `AudioManager.SFX_STREAMS`; gol = fara sunet (nu s-a adaugat
## niciun asset nou fara cerere explicita — `splash.wav` exista deja, e
## refolosit aici).
@export var impact_sfx: StringName = &"splash"

@export_group("Efect in calm (fara fizica plina)")
## Un efect MIC, simtit, cat `_physics_enabled` e false (Torrent: CALM si
## TELEGRAPH, issue #493 — fara el, jumatate din ciclu trecea prin apa fara sa
## se simta nimic). NU e SURGE: fara forta in jos, fara albire, fara yaw. Toate
## implicit 0 (cascadele de ploaie/teatru raman inerte); `TorrentCycle` le
## seteaza din propriile `calm_*`. Franare orizontala (1/s), ca `drag`.
@export_range(0.0, 1.0, 0.01) var calm_drag: float = 0.0
## Impingere laterala la intrare (m/s, pe `push_dir`), o singura data.
@export_range(0.0, 6.0, 0.1) var calm_push_speed: float = 0.0
## Shake + strop la intrare (`Car.splash`) si picurat dupa iesire (s).
@export_range(0.0, 1.0, 0.05) var calm_splash_trauma: float = 0.0
@export_range(0.0, 6.0, 0.5) var calm_douse_seconds: float = 0.0

@export_group("Albire")
## Cat ar trebui sa tina albirea vizuala (s) — vezi antetul: efectiv, albirea
## e ceata locala cat esti in zona, nu un ceas separat. Export pastrat pentru
## sonde si pentru o varianta viitoare cu puf de abur care se stinge singur.
@export_range(0.0, 3.0, 0.1) var whiteout: float = 1.0
## Cat de aproape/departe imping ceata cand esti in mijlocul perdelei (m).
## Valori mici = albire puternica (aproape opac).
@export_range(0.5, 20.0, 0.5) var fog_begin_inside: float = 1.5
@export_range(2.0, 60.0, 0.5) var fog_end_inside: float = 9.0

var _visual: WaterfallVisual
var _fog: FogCorridorHazardScript
var _cars_inside: Dictionary = {}
## Starea de activare aplicata ultima data (vezi `_set_active`).
var _active: bool = true
## Comutator SEPARAT de `_active` (Torrent, Fiordland brief „Torentul in
## pulsuri"): `_active` e legat de VIZIBILITATE (modulate.a > 0.001) — un fir
## subtire de teatru in faza CALM e vizibil (`modulate.a` mic, dar > 0), deci
## `_active` ramane true, si fara comutatorul asta franarea/forta/albirea ar
## rula in continuu cat perdeaua e vizibila, nu doar cat e PLINA. Vezi
## `set_physics_enabled`.
var _physics_enabled: bool = true


func _ready() -> void:
	_rebuild()
	set_physics_process(not Engine.is_editor_hint())


func _current_thickness() -> float:
	var extra := rain_extra_thickness * clampf((rain_factor - 1.0) / 0.3, 0.0, 1.0)
	return thickness + extra


func _rebuild() -> void:
	if not is_inside_tree():
		return
	monitoring = true
	monitorable = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_build_shape()
	_build_visual()
	_build_fog()
	if not _active:
		_set_active(false)


func _build_shape() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var t := _current_thickness()
	box.size = Vector3(t, 10.0, length)
	shape.shape = box
	shape.position = Vector3.UP * 5.0
	shape.name = "Curtain"
	add_child(shape)


## Vizualul partajat (vezi antetul): aceeasi amprenta ca forma de coliziune
## (grosimea curenta, cu ploaia inclusa, pe X; `length` pe Z), `visual_height`
## pe Y. Intensitatea porneste din `modulate.a`, ca o pista incarcata in
## faza uscata sa nu arate o clipa cascadele de ploaie aprinse.
func _build_visual() -> void:
	_visual = WaterfallVisual.new()
	# Nu "Curtain": numele e luat de forma de coliziune, iar la runtime un
	# nume dublat devine "@Curtain@id" — pe care `Snapshot --hide=Curtain*`
	# nu-l mai gaseste (masurat: A/B-ul on/off a iesit identic la bit).
	_visual.name = "Perdea"
	add_child(_visual)
	_visual.build(Vector3(_current_thickness(), visual_height, length), spray_count)
	_visual.set_intensity(modulate.a)


## Ceata locala = albirea. O instanta INTERNA de `FogCorridorHazard`, cu
## acelasi `length`, dar `ramp_in`/`ramp_out` scurte (perdeaua e brusca la
## intrare si la iesire, nu un culoar cu tranzitie lunga ca la Chongqing) si
## fara marcaje (zona n-are nevoie de repere — n-o traversezi orb, doar 1 s).
func _build_fog() -> void:
	_fog = FogCorridorHazardScript.new()
	_fog.name = "Whiteout"
	_fog.length = length
	_fog.half_width = _current_thickness() * 0.5 + 1.0
	_fog.ramp_in = maxf(length * 0.15, 1.0)
	_fog.ramp_out = maxf(length * 0.15, 1.0)
	_fog.fog_begin_inside = fog_begin_inside
	_fog.fog_end_inside = fog_end_inside
	_fog.fog_color = Color(0.92, 0.94, 0.96)
	_fog.marker_spacing = 1000.0 # efectiv fara marcaje: zona e prea scurta ca sa le ceara
	add_child(_fog)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Pe uscat, o cascada de ploaie e STINSA de `RainCycle` (`visible = false`,
	# `modulate.a = 0`) — si zona ei trebuie sa fie la fel de inactiva ca
	# vizualul: nici franare, nici albire. Inainte, un nod invizibil franea si
	# albea in continuare (constatare de la un alt agent, 22 sep: cutiile de
	# ploaie apareau pe uscat; iar ceata lor lucra chiar si cand nu apareau).
	var active := is_visible_in_tree() and modulate.a > 0.001
	if active != _active:
		_set_active(active)
	if not active:
		return
	# `_physics_enabled=false` (Torrent, faza CALM/TELEGRAPH): zona ramane
	# MONITORIZATA (splash-ul de intrare tot declanseaza — e teatru, nu
	# fizica), dar FARA forta/franare, si albirea locala se stinge separat
	# (vezi mai jos): un fir subtire vizibil nu trebuie sa apese sau sa
	# franeze masina, doar cascada PLINA o face.
	var seen := {}
	for body in get_overlapping_bodies():
		var car := body as Car
		if car == null:
			continue
		seen[car] = true
		# SPLASH la intrare (brief pasul 3b): explozia de spray porneste o
		# singura data, in cadrul in care masina INTRA in zona — nu la fiecare
		# cadru cat timp ramane sub perdea (`_cars_inside` marcheaza exact
		# membership-ul de la cadrul anterior, deci absenta lui aici = intrare
		# noua). Doar pentru jucator sau AI, oricine declanseaza vizualul —
		# splash-ul e al LUMII, nu al camerei (la fel ca spray-ul continuu).
		var entering := not _cars_inside.has(car)
		if entering and _visual != null and is_instance_valid(_visual):
			_visual.trigger_splash_burst()
		_cars_inside[car] = true
		if not _physics_enabled:
			_apply_calm_effect(car, entering, delta)
			continue
		# IMPACTUL la intrare (runda 3, verdict la volan): lateral + yaw +
		# shake + picurat + sfx, o SINGURA data per intrare, nu la fiecare
		# cadru cat esti sub perdea (force_accel/drag de mai jos raman
		# continue, astea sunt lovitura). Doar cand fizica e chiar activa
		# (nu in teatru/CALM, deja garantat de `continue`-ul de mai sus) SI
		# `force_accel > 0`: varianta "cascada de ploaie" (teatru, brief S3)
		# are force_accel=0 dar `_physics_enabled` ramane implicit true - fara
		# conditia asta, cele 5 RainFall* te-ar imbranci si ele.
		if entering and force_accel > 0.0:
			_apply_entry_impact(car)
		var base_accel := force_accel * rain_factor
		if base_accel > 0.0:
			var accel := base_accel * _speed_factor(car.horizontal_speed())
			if compression_ease_start > 0.0:
				accel *= _compression_factor(car)
			car.apply_central_force(Vector3.DOWN * car.mass * accel)
		if drag > 0.0:
			var v := car.velocity
			var horiz := Vector3(v.x, 0.0, v.z)
			car.velocity = Vector3(
				horiz.x * (1.0 - drag * delta), v.y,
				horiz.z * (1.0 - drag * delta))
	for car in _cars_inside.keys():
		if not seen.has(car):
			_cars_inside.erase(car)
	if _fog != null and is_instance_valid(_fog):
		_fog.set_active(_physics_enabled)


## Aprinde/stinge ZONA odata cu vizualul: `monitoring` pe Area3D-ul propriu
## (fara suprapuneri, deci fara forta/franare) si zona cetii interne (fara
## albire; `FogCorridorHazard` recalculeaza cantitatea din suprapuneri la
## fiecare cadru, deci fara suprapuneri mediul revine singur la baza).
func _set_active(on: bool) -> void:
	_active = on
	monitoring = on
	if not on:
		_cars_inside.clear()
	if _fog != null and is_instance_valid(_fog):
		_fog.set_active(on and _physics_enabled)


## Comutator SEPARAT de vizibilitate (Torrent, Fiordland): taie forta,
## franarea SI albirea (`_fog.set_active`) fara sa stinga perdeaua vizual —
## un fir subtire de teatru in CALM tot trebuie sa se VADA (altfel torentul
## ar disparea intre pulsuri, gresit fata de brief: "fir subtire, teatru"),
## dar nu trebuie sa apese sau sa franeze masina, si nu trebuie sa albeasca
## ecranul pentru un fir de apa. `on=true` = comportament implicit
## (nesetat, orice alta pista/sonda ramane neschimbata).
func set_physics_enabled(on: bool) -> void:
	_physics_enabled = on
	if not on:
		if _fog != null and is_instance_valid(_fog):
			_fog.set_active(false)
	elif _active:
		if _fog != null and is_instance_valid(_fog):
			_fog.set_active(true)


## Factorul care scaleaza `force_accel` cu viteza CURENTA (nu cea de la
## intrare — vezi antetul, "runda 2"). Liniar pe `speed_ref`, cu podea
## `min_speed_factor` si plafon 1.5 (o masina care intra foarte rapid, cu
## turbo, ia mai mult decat `force_accel` nominal — trade-off-ul cerut).
func _speed_factor(horizontal_speed: float) -> float:
	if speed_ref <= 0.01:
		return 1.0
	return clampf(horizontal_speed / speed_ref, min_speed_factor, 1.5)


## Varianta B: slabeste apasarea cand arcul e deja aproape de fund — citeste
## `wheel_compression` (acelasi camp public folosit de sonda), ia MAXIMUL
## celor 4 roti ca fractie din cursa proprie, si scade liniar de la 1.0 (la
## `compression_ease_start`) la `compression_ease_min` (la 100%).
func _compression_factor(car: Car) -> float:
	var rest := maxf(car.suspension_rest, 0.001)
	var frac := 0.0
	for c in car.wheel_compression:
		frac = maxf(frac, float(c) / rest)
	if frac <= compression_ease_start:
		return 1.0
	var t := clampf(
		(frac - compression_ease_start) / maxf(1.0 - compression_ease_start, 0.001),
		0.0, 1.0)
	return lerpf(1.0, compression_ease_min, t)


## Lovitura de la INTRARE (runda 3): lateral, yaw, shake, picurat, sfx — o
## singura data per intrare, apelata din `_physics_process` inainte de
## forta/franarea continue (care raman neschimbate mai jos, in bucla
## principala). Toate cele cinci sunt export-uri, deci un "reglaj de volan"
## fara cod nou: `push_speed=0` sau `splash_trauma=0` le scoate individual din
## calcul, exact ca `force_accel=0` scoate apasarea verticala (variantele de
## teatru/ploaie raman neatinse, fiindca `_physics_enabled` sau `force_accel`
## le opresc deja mai devreme).
##
## AI ONEST (principiul 5): acelasi apel, pentru orice `Car` din zona — nu
## exista `if car.is_player`. Diferenta de FEEDBACK (shake/sunet/picurat) intre
## jucator si AI vine din `Race`, care leaga semnalele DOAR pe `player` (vezi
## `race.gd`); AI-ul primeste exact aceeasi forta/impuls/yaw, doar fara
## camera/HUD care sa le arate — la fel cum bumping-ul cu masa loveste AI-ul
## identic, dar numai camera jucatorului tremura.
func _apply_entry_impact(car: Car) -> void:
	if push_speed > 0.0 and push_dir.length_squared() > 0.0001:
		var local_dir := push_dir.normalized()
		var world_dir := (global_transform.basis * local_dir)
		world_dir.y = 0.0
		if world_dir.length_squared() > 0.0001:
			world_dir = world_dir.normalized()
			car.apply_sweep(world_dir * push_speed)
			if yaw_kick_rate > 0.0 and yaw_kick_seconds > 0.0:
				# Semnul urmeaza spre ce parte a masinii impinge apa (dot cu
				# dreapta locala a masinii): impinsa spre dreapta ei, botul
				# fuge usor spre dreapta — un vehicul lovit lateral, nu un
				# spin aleator. `car.basis.x` e dreapta locala (convenția
				# Car: -Z e fata).
				var car_right := car.global_transform.basis.x
				var sign := signf(world_dir.dot(car_right))
				if sign == 0.0:
					sign = 1.0
				car.apply_yaw_kick(sign * yaw_kick_rate, yaw_kick_seconds)
	if splash_trauma > 0.0:
		car.splash(splash_trauma)
	if douse_seconds > 0.0:
		car.douse(douse_seconds)
	if impact_sfx != &"":
		AudioManager.play_sfx(impact_sfx)


## Efectul mic din faza calma (vezi grupul `calm_*`): franare usoara continua
## + la intrare o impingere laterala mica, splash/shake mic si picurat. Fara
## sfx (un fir de apa nu loveste), fara forta in jos, fara yaw. Acelasi apel
## pentru orice `Car` (AI onest).
func _apply_calm_effect(car: Car, entering: bool, delta: float) -> void:
	if calm_drag > 0.0:
		var v := car.velocity
		car.velocity = Vector3(
			v.x * (1.0 - calm_drag * delta), v.y, v.z * (1.0 - calm_drag * delta))
	if not entering:
		return
	if calm_push_speed > 0.0 and push_dir.length_squared() > 0.0001:
		var world_dir := global_transform.basis * push_dir.normalized()
		world_dir.y = 0.0
		if world_dir.length_squared() > 0.0001:
			car.apply_sweep(world_dir.normalized() * calm_push_speed)
	if calm_splash_trauma > 0.0:
		car.splash(calm_splash_trauma)
	if calm_douse_seconds > 0.0:
		car.douse(calm_douse_seconds)


# ---------------------------------------------------------------- pentru sonde

## Masinile aflate ACUM sub perdea (dupa ultimul `_physics_process`).
func cars_inside() -> Array:
	return _cars_inside.keys()


## Latimea EFECTIVA a zonei, cu ploaia inclusa — ce foloseste sonda ca sa NU
## presupuna aritmetica `rain_extra_thickness` de doua ori.
func effective_thickness() -> float:
	return _current_thickness()


## Ceata locala, pentru sonda care vrea sa verifice ca albirea chiar se leaga
## de mediul pistei (acelasi contract ca `FogCorridorHazard.amount()`).
func fog_amount() -> float:
	return _fog.amount() if _fog != null else 0.0
