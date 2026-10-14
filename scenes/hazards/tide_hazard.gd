@tool # vizibil si in preview-ul din editor
class_name TideHazard
extends WaterHazard
## MAREEA (Ha Long, Track22, brief §3): banda de jos a drumului de coasta e
## scurtatura pistei la maree joasa si e SUB APA la maree inalta.
##
## Gimmick-ul: nu e un obstacol care te loveste, e o **stare a lumii** cu ciclu
## lung (un tur intreg), pe care o **citesti de pe belvedere** cu ~30 s inainte
## sa ajungi la ea. Decizia („o iau sau nu?") se ia ACOLO, nu la intrare —
## de-aia ciclul e lung si de-aia telegraful e geografic, nu vizual-local.
##
## [b]Fata de celelalte variante de WaterHazard[/b] (`WaterHose`, `WaveSurge`,
## `ShishiOdoshi`): alea sunt EVENIMENTE de cateva secunde pe drumul principal.
## Mareea e o stare de ~80 s care deschide si inchide o BANDA INTREAGA. Deci:
##  - `_advance` nu numara o trecere, ci rezolva o faza lunga;
##  - pe langa taierea de grip (de la `WaterHazard`), hazardul e si **poarta de
##    banda**: intra in `Track.BRANCH_GATE_GROUP` cu `branch_index` +
##    `shortcut_open()`, exact ca lava de pe Stromboli si vaca de la Jodhpur.
##    Precedentul exista, deci grupul se alatura, nu se creeaza.
##
## [b]DECIZIA 3.1.3 din brief, luata pe cod citit[/b]: briful propunea „apa taie
## grip-ul, banda rămâne deschisa" ca varianta mai ieftina, lasand decizia
## riscanta posibila. Dar `Track.branch_is_open` + `BRANCH_GATE_GROUP` exista
## deja si costa DOUA metode, iar inchiderea e mai onesta: la 1.5 m de apa peste
## terasa, o banda „deschisa cu grip tăiat" ar fi o capcana, nu o decizie — iar
## AI-ul re-alege la fiecare tur (`shortcut_open` se intreaba per tur in
## AIController), deci nu intra in apa fiindca a decis la turul 1.
## Compromisul pastrat: banda se inchide DOAR la apa mare (`closed_frac`), iar
## faza de telegraf si cea de retragere o lasa deschisa cu apa pe ea — adica
## riscul asumat rămâne posibil pe muchie.
##
## [b]Cum se declara in Track22.tscn[/b] (nod separat sub radacina pistei, NU
## prin HazardMarker):
##
##   [node name="Maree" type="Node3D" parent="."]
##   script = ExtResource("tide")
##   branch_index = 1
##   period = 80.0
##   span_m = 120.0
##
## [b]CEASUL PORNESTE IN TELEGRAF[/b] (memoria `ceasul-porneste-in-prima-faza`):
## la `t = 0` faza e TELEGRAF, nu „apa sus". Pe Fiordland, `RainCycle` la 0 era
## deja in ploaie si toate verdictele ProbeRace au ieşit cu ploaie de la start —
## adica se masura alta pista. `phase` implicit 0 cade anume la inceputul
## telegrafului, iar sonda `probe_maree` verifica asta explicit.

## Fazele ciclului, in ordine. Suma fractiilor = 1.
## JOS: terasa descoperita, scurtatura deschisa si uscata.
## URCA: apa vine, banda inca deschisa — ferestra de risc asumat.
## SUS: apa peste terasa, banda INCHISA.
## COBOARA: apa se retrage, banda se redeschide uda.
enum Phase {JOS, URCA, SUS, COBOARA}

## Perioada intregului ciclu (s). Brief §3: ~75-90 s, adica un tur intreg, ca
## decizia de pe belvedere sa fie despre TURUL ASTA.
@export_range(20.0, 200.0, 1.0) var period: float = 80.0
## Defazaj 0..1. Implicit 0 = ceasul porneste la inceputul TELEGRAFULUI (URCA),
## nu cu apa sus (vezi antetul).
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0
## Cat din ciclu e fiecare faza. Se normalizeaza, deci nu trebuie sa dea exact 1.
@export_range(0.05, 0.6, 0.01) var low_frac: float = 0.34
@export_range(0.05, 0.4, 0.01) var rise_frac: float = 0.14
@export_range(0.05, 0.6, 0.01) var high_frac: float = 0.38
@export_range(0.05, 0.4, 0.01) var fall_frac: float = 0.14
## Indexul benzii secundare pe care o inchide (ordinea din Track.routes).
@export var branch_index: int = 1
## Lungimea benzii de jos (m): de atat are nevoie pelicula de apa ca sa acopere
## terasa, nu doar un petec de sosea. Se masoara pe scena, nu se ghiceste.
@export_range(10.0, 300.0, 1.0) var span_m: float = 120.0
## Latimea benzii de jos (m).
@export_range(3.0, 20.0, 0.5) var lane_width: float = 8.0
## Cat urca apa peste terasa la maree plina (m). Brief §1: mareea reala din
## golful Tonkin e 3-4 m; in joc e „scara e decizie" (§8) — 1.5 m e destul ca
## banda sa fie impracticabila si putin pentru ca pereţii sa nu para inundati.
@export_range(0.3, 4.0, 0.1) var rise_m: float = 1.5

signal phase_changed(phase: Phase)

var _time: float = 0.0
var _phase: Phase = Phase.URCA
var _level: float = 0.0
var _film: MeshInstance3D


func _ready() -> void:
	super()
	# Grupul comun de „porti de banda" (Track.branch_is_open). Precedentul e
	# lava de pe Stromboli si vaca de la Jodhpur, deci grupul se ALATURA.
	add_to_group(Track.BRANCH_GATE_GROUP)


# ---------------------------------------------------------- contractul WaterHazard

## Apa acoperă toata banda de jos, nu un petec de sosea: de-aia `span_m` si
## `lane_width` sunt exporturi masurate pe scena, nu derivate din `road_width`
## (care e latimea drumului PRINCIPAL, irelevanta aici).
func _wet_patch_size() -> Vector3:
	return Vector3(lane_width, maxf(rise_m * 2.0, 2.0), span_m)


## Pelicula sta la cota curenta a apei, nu la cea a soselei: aici apa URCA, deci
## inaltimea e starea hazardului, nu o constanta. (La conducta sparta si la val,
## apa e mereu pe asfalt — de-aia implicitul e 0.06.)
func _wet_patch_offset() -> float:
	return 0.06


## Ceasul: rezolva faza lunga si nivelul apei. `true` cat timp banda e udata —
## adica in URCA, SUS si COBOARA (in JOS terasa e descoperita).
func _advance(delta: float) -> bool:
	_time += delta
	var sum := low_frac + rise_frac + high_frac + fall_frac
	var t := fposmod(_time / maxf(period, 0.1) + phase, 1.0) * sum
	# Ordinea e URCA -> SUS -> COBOARA -> JOS, ca `phase = 0` sa cada la
	# inceputul TELEGRAFULUI (vezi antetul: ceasul porneste in prima faza).
	var ph: Phase
	var level: float
	if t < rise_frac:
		ph = Phase.URCA
		level = t / rise_frac
	elif t < rise_frac + high_frac:
		ph = Phase.SUS
		level = 1.0
	elif t < rise_frac + high_frac + fall_frac:
		ph = Phase.COBOARA
		level = 1.0 - (t - rise_frac - high_frac) / fall_frac
	else:
		ph = Phase.JOS
		level = 0.0
	_level = level
	if ph != _phase:
		_phase = ph
		phase_changed.emit(ph)
	_update_film()
	return level > 0.02


## Pelicula urca si coboara cu apa. Se scaleaza pe Y in loc sa fie mutata, ca
## marginea sa rămână lipita de terasa: o foaie de apa care PLUTESTE la 1.5 m
## ar citi ca o placa de sticla.
func _update_film() -> void:
	if _film == null:
		_film = get_node_or_null("TideFilm") as MeshInstance3D
	if _film == null:
		return
	_film.visible = _level > 0.02
	_film.position.y = _level * rise_m


func _build_source() -> void:
	# Foaia de apa care urca. Materialul vine de la pista (`film_material` =
	# MATERIALUL MARII pe temele cu apa), deci nu costa niciun material in plus
	# — garda numara materialele per pista (CLAUDE.md).
	var mi := MeshInstance3D.new()
	mi.name = "TideFilm"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(lane_width, span_m)
	# Primitiva in cod: subdiviziunile se declara EXPLICIT (CLAUDE.md — un mesh
	# lasat la implicit sare cu zeci de mii de triunghiuri).
	mesh.subdivide_width = 1
	mesh.subdivide_depth = 3
	mi.mesh = mesh
	if film_material != null:
		mi.material_override = film_material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	add_child(mi)
	_film = mi


## Primeste materialul marii DUPA ce pista l-a construit (vezi
## `Track._wire_scene_water_hazards`): un nod declarat in .tscn nu trece prin
## `_build_wave`, deci n-ar avea de unde sa-l ia, si ar desena un albastru
## propriu — un material in plus la numaratoarea garzii.
func apply_film_material(mat: Material) -> void:
	if mat == null:
		return
	film_material = mat
	if _film == null:
		_film = get_node_or_null("TideFilm") as MeshInstance3D
	# Toate mesh-urile hazardului: foaia care urca (`TideFilm`) si balta pe care
	# o face `WaterHazard._build_wet_patch` in `_ready`. Amandoua trebuie sa fie
	# pe materialul marii, nu doar prima.
	for c in get_children():
		var mi := c as MeshInstance3D
		if mi != null:
			mi.material_override = mat


## Apa de maree taie grip-ul, dar NU imbranceste: nu e un val care trece, e o
## foaie care sta. (Valul de pe Okinawa impinge si franeaza — vezi
## `WaveSurge._touch_car`.)
func _touch_car(car: Car, _delta: float) -> void:
	car.apply_slip()


# ---------------------------------------------------------- poarta de banda

## Contractul cu `Track.branch_is_open`: banda de jos e deschisa in toate fazele
## IN AFARA de apa plina.
##
## Faza URCA si faza COBOARA o lasa deschisa CU APA PE EA, deliberat: acolo sta
## riscul asumat (brief §3.1.3 — „decizie, nu taxa"). Doar SUS o inchide.
func shortcut_open() -> bool:
	return _phase != Phase.SUS


# ---------------------------------------------------------- pentru sonde

func tide_phase() -> Phase:
	return _phase


func tide_level() -> float:
	return _level


func water_y_offset() -> float:
	return _level * rise_m


## Faza la un moment dat, fara sa avansezi ceasul (sonde, capturi).
func phase_at(t: float) -> Phase:
	var sum := low_frac + rise_frac + high_frac + fall_frac
	var u := fposmod(t / maxf(period, 0.1) + phase, 1.0) * sum
	if u < rise_frac:
		return Phase.URCA
	if u < rise_frac + high_frac:
		return Phase.SUS
	if u < rise_frac + high_frac + fall_frac:
		return Phase.COBOARA
	return Phase.JOS


## Cat timp (s) rămâne banda inchisa per ciclu, si cat e deschisa. Contractul
## gimmickului se verifica pe cifrele astea, nu pe senzatie.
func closed_seconds() -> float:
	var sum := low_frac + rise_frac + high_frac + fall_frac
	return period * high_frac / sum


func open_seconds() -> float:
	return period - closed_seconds()


func set_clock(t: float) -> void:
	_time = t
