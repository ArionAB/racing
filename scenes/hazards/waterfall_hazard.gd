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
## [b]Placeholder vizual.[/b] O singura cutie verticala pe atlas
## (`PaletteBox`, slotul `FOAM_WHITE`), intinsa pe toata zona — shaderul de
## cadere (pânza billboard cu UV pe verticala, brief §5.1 `waterfall`) NU e
## treaba sondei tehnice.

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
## Inaltimea vizuala a perdelei (m) — doar pentru placeholder; cascada reala
## cade de la un surplomb, dar zona de forta nu are nevoie de inaltimea aia.
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
## darmite tranzitand 30 m in ~1.2-2 s. Masurat cu sonda
## (`tools/probe_fiord_cascada.gd`, sweep 9-70): la **40**, pe uscat, Buggy
## atinge fundul (98.9%) la ORICE viteza testata (15/25 m/s) si Politia NU
## (71.5-84.3%) — diferentierea ceruta de brief — iar Muscle/Politia/Taxi/
## Buggy raman toate in banda de 17-24% pierdere de viteza (tinta brief:
## 20-25%). Autobuzul si Pompierii (cele mai grele, cu suspensia cea mai
## moale SI motorul cel mai slab) ies din tinta chiar si la 40 (pierdere
## 42-57%) — vezi raportul sondei: e un compromis structural al perechii
## forta/suspensie, nu o valoare de reglat mai fin.
@export_range(0.0, 60.0, 0.5) var force_accel: float = 40.0
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
## Franarea pe componenta ORIZONTALA a vitezei, ca fractie pe secunda
## (`v -= v_horiz * drag * delta`). Calibrat pe sonda (`probe_fiord_cascada.gd
## --drag=`, sweep 0.0-0.5) sa dea ~20-25% pierdere de viteza pe 30 m la
## 25 m/s, force_accel implicit, CU GAZUL APASAT (nu in ruliu liber — vezi
## nota din sonda despre drag-ul intrinsec al lui Car): masurat 23.5% pentru
## Muscle la `drag = 0.45`. Valoarea initiala (0.7) dadea 39%, mult peste
## tinta din brief.
@export_range(0.0, 3.0, 0.05) var drag: float = 0.45
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

@export_group("Albire")
## Cat ar trebui sa tina albirea vizuala (s) — vezi antetul: efectiv, albirea
## e ceata locala cat esti in zona, nu un ceas separat. Export pastrat pentru
## sonde si pentru o varianta viitoare cu puf de abur care se stinge singur.
@export_range(0.0, 3.0, 0.1) var whiteout: float = 1.0
## Cat de aproape/departe imping ceata cand esti in mijlocul perdelei (m).
## Valori mici = albire puternica (aproape opac).
@export_range(0.5, 20.0, 0.5) var fog_begin_inside: float = 1.5
@export_range(2.0, 60.0, 0.5) var fog_end_inside: float = 9.0

var _visual: MeshInstance3D
var _fog: FogCorridorHazardScript
var _cars_inside: Dictionary = {}


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


func _build_shape() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var t := _current_thickness()
	box.size = Vector3(t, 10.0, length)
	shape.shape = box
	shape.position = Vector3.UP * 5.0
	shape.name = "Curtain"
	add_child(shape)


## Placeholder: o singura cutie pe FOAM_WHITE, cat toata zona. Fara shader de
## cadere — asta ramane treaba pasului de assets (§7.7), nu al sondei tehnice.
func _build_visual() -> void:
	var t := _current_thickness()
	_visual = PaletteBox.instance(
		Vector3(t, visual_height, length), Palette.FOAM_WHITE,
		Vector3(0.0, visual_height * 0.5, 0.0))
	_visual.name = "CurtainPlaceholder"
	add_child(_visual)


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
	var base_accel := force_accel * rain_factor
	var seen := {}
	for body in get_overlapping_bodies():
		var car := body as Car
		if car == null:
			continue
		seen[car] = true
		_cars_inside[car] = true
		if base_accel > 0.0:
			var accel := base_accel * _speed_factor(car.horizontal_speed())
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


## Factorul care scaleaza `force_accel` cu viteza CURENTA (nu cea de la
## intrare — vezi antetul, "runda 2"). Liniar pe `speed_ref`, cu podea
## `min_speed_factor` si plafon 1.5 (o masina care intra foarte rapid, cu
## turbo, ia mai mult decat `force_accel` nominal — trade-off-ul cerut).
func _speed_factor(horizontal_speed: float) -> float:
	if speed_ref <= 0.01:
		return 1.0
	return clampf(horizontal_speed / speed_ref, min_speed_factor, 1.5)


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
