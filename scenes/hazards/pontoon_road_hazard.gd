@tool # vizibil si in preview-ul din editor
class_name PontoonRoadHazard
extends Node3D
## DRUMUL DE PONTOANE (Ha Long, Track22, brief §3): primul carosabil din joc
## care PLUTESTE. Nu e o platforma care te duce (telecabina, podul rotitor) —
## e drum normal, pe care conduci, si care CEDEAZA si SE LEAGANA sub masa
## masinii.
##
## [b]De ce nu moşteneste RopeBridgeHazard[/b] (decizia, cu motiv). Modelul
## fizic e acelasi si e luat de acolo, dar:
##  1. `snapshot.gd:1748/1763` si `probe_machu_pod.gd` caută podul cu
##     `find_children("*", "RopeBridgeHazard", true, false)`, iar in Godot o
##     SUBCLASA se potriveste la numele clasei de baza — pontoanele de pe Ha
##     Long ar fi fost "gasite" de uneltele Machu Picchu, si `--rope-load` ar fi
##     asezat masina pe un ponton crezand ca e podul (memoria
##     `subclasa-prinsa-de-find-children`);
##  2. din cele 604 linii ale podului, ~36 de referinte sunt vizual de pod
##     (scanduri, cabluri portante, balustrade de franghie, turnuri de piatra)
##     iar fizica comuna e ~80 de linii. Un strat comun extras ar fi atins o
##     clasa pe care Track15 o foloseste, pentru un castig mic.
## Deci: cod propriu, model matematic imprumutat, iar podul rămâne NEATINS.
##
## [b]Cum se declara in Track22.tscn[/b] (acelasi tipar ca RopeBridgeHazard si
## CablewayHazard — un nod cu scriptul asta, direct sub radacina pistei, NU
## prin HazardMarker):
##
##   [node name="Ponton1" type="Node3D" parent="."]
##   script = ExtResource("pontoon")
##   near_end = Vector3(x0, y0, z0)   # buza de plecare, LOCAL fata de nod
##   far_end = Vector3(x1, y1, z1)    # buza de sosire
##   deck_width = 6.0
##
## sau un copil Path3D numit „Route" cu DOUA puncte, care bate exporturile.
## GOLUL din carosabil il cere pontonul singur: `road_hole_span()` (acelasi
## contract ca RotatingSpanHazard si RopeBridgeHazard, vezi
## Track._resolve_span_holes), deci nodul se pune PE punctul copt din mijloc,
## iar capetele pe punctele copte de la ±k pasi.
##
## [b]CE E DIFERIT FATA DE POD[/b] — cele trei schimbari din brief §5.3:
##
##  1. [b]CAPETELE SUNT LIBERE.[/b] La pod, forma modului e `P(u) = 4u(1-u)`,
##     care e ZERO la ambele capete: franghia e ancorata in turnuri. Un ponton
##     nu are capete fixe — pluteste pe toata lungimea, iar la buze e doar
##     legat de insulita. Deci forma devine
##       `P_pont(u) = free_ends + (1 - free_ends) · 4u(1-u)`
##     cu `free_ends > 0`: cedeaza si la capat, doar mai putin decat la mijloc.
##     Consecinta care CONSTRANGE scena: pragul de la insulita fixa la ponton
##     nu are voie sa treaca 0.3 m (memoria `suprafete-cu-goluri-si-praguri`:
##     peste atat e zid), de-aia `rest_sag` si `free_ends` se tin mici si de-aia
##     exista `edge_clamp` (mai jos), care stinge cedarea pe ultimii metri.
##
##  2. [b]TANGAJUL.[/b] A treia ecuatie, pe acelasi tipar ca balansul: un
##     pendul amortizat pe axa LONGITUDINALA, excitat de masa descentrata pe
##     lungime (si de accelerare/franare, prin pozitia ei care se muta). Podul
##     n-are nevoie: capetele lui sunt fixe, deci nu se poate inclina pe lung.
##     Un ponton da. E ce face diferenta intre "drum moale" si "drum care
##     pluteste".
##
##  3. [b]FORTAREA EXTERNA[/b] din valul joncilor: un termen sinusoidal cu faza
##     proprie, care ridica si coboara tot tronsonul chiar si cand nu e nimeni
##     pe el. Pontonul e VIU cand pista e goala — podul, nu.
##
## [b]Modelul fizic[/b] (identic in structura cu al podului, vezi acolo pentru
## de ce NU un lant de RigidBody3D cu joint-uri):
##  - SAGEATA globala `_sag`: arc+amortizor spre tinta data de incarcari, cu
##    legea `a(m) = gain · m^exp` calibrata din `sag_bus`/`sag_sport` IN METRI;
##  - BALANSUL lateral `_sway`: pendul amortizat spre echilibrul dat de masa
##    descentrata lateral; tablierul se muta SPRE partea grea;
##  - TANGAJUL `_pitch`: pendul amortizat spre echilibrul dat de masa
##    descentrata pe LUNGIME (nou);
##  - VALUL `_wave_phase`: ceas propriu, forteaza sageata (nou);
##  - TABLIERUL FIZIC: `plate_count` placi AnimatableBody3D cu sync_to_physics,
##    PERMANENTE (memoria `corp-cinematic-aparut-in-masina`), asezate O DATA pe
##    tick pe coarda dintre doua puncte consecutive (global_transform INTREG —
##    memoria `jolt-sync-transform-o-singura-scriere`). Fiecare publica
##    `platform_velocity` (mecanismul telecabinei), deci valul RIDICA masina
##    usoara si balansul o impinge, fara cuplu si fara apply_torque_impulse
##    (yaw-ul masinii e rescris pe tick; memoria `yaw-ul-masinii-e-rescris-pe-tick`).
##
## [b]Capcane inchise[/b] (tools/probe_ponton.gd):
##  - amplitudinile sunt CONTINUE (arc+amortizor): o placa nu sare sub masina;
##  - pragul la insulite < 0.3 m, verificat cu `edge_drop()`;
##  - `_drop` din GDScript si `deck_drop` din shader sunt ACEEASI formula — daca
##    le desparti, masina merge pe o suprafata pe care n-o vezi (aceeasi regula
##    pe care o scrie antetul shaderului podului);
##  - masina „pe ponton" = in zona Deck, cu roti pe sol si la < 1.5 m de curba.

## Sloturi: lemn de apa sarata pentru bambus, metal vopsit pentru butoaiele
## albastre de flotor (accentul pistei, brief §4).
const WOOD_SLOT: int = 9
const DRUM_SLOT: int = 11
## Masele de referinta din calibrare (CarData: sport 0.9, autobuz 2.6).
const MASS_SPORT: float = 0.9
const MASS_BUS: float = 2.6
const PLATE_THICKNESS: float = 0.3
const PLANK_WIDTH: float = 0.55
const PLANK_GAP: float = 0.05
const PLANK_THICKNESS: float = 0.18
## Butoaiele de flotor: perechi sub margini, la pasul asta.
const DRUM_STEP: float = 2.4
const DRUM_RADIUS: float = 0.32
const SHADER_PATH: String = "res://assets/shaders/pontoon_road.gdshader"

@export_group("Capete")
## Buzele tronsonului, LOCAL fata de nod (un copil Path3D „Route" le bate).
@export var near_end: Vector3 = Vector3.ZERO
@export var far_end: Vector3 = Vector3(0.0, 0.0, -60.0)
## Latimea tablierului (m). Brief §2: pontoanele la 6 m.
@export_range(3.0, 12.0, 0.1) var deck_width: float = 6.0

@export_group("Afundare")
## Sageata de REPAUS la mijloc (m), fara nimeni pe ponton. Un ponton incarcat
## cu propria greutate sta deja putin in apa.
@export_range(0.0, 1.0, 0.05) var rest_sag: float = 0.12
## Cat coboara mijlocul sub autobuz (2.6) si sub sport (0.9), fata de repaus.
## Brief §3: ~0.45 m autobuz, ~0.18 m sport. Din ele ies gain-ul si exponentul.
@export_range(0.1, 2.0, 0.05) var sag_bus: float = 0.45
@export_range(0.05, 1.0, 0.05) var sag_sport: float = 0.18
## Cat din amplitudine e afundarea LOCALA de sub masina (restul e mod global).
## Mai mare decat la pod: un ponton cedeaza mai ales sub roti, nu pe toata
## lungimea — e o plută, nu o coarda intinsa.
@export_range(0.0, 1.0, 0.05) var dip_ratio: float = 0.55
## Latimea afundarii locale (m, sigma gaussiana).
@export_range(1.0, 10.0, 0.1) var dip_sigma: float = 4.0
## [b]CAPETE LIBERE[/b] (schimbarea 1 fata de pod): cat din forma modului
## rămâne la buze. 0 = capete ancorate, adica exact podul. 0.35 = la capat
## cedeaza 35% din cat cedeaza la mijloc.
@export_range(0.0, 0.8, 0.05) var free_ends: float = 0.35
## Pe cati metri de la fiecare buza se stinge cedarea.
##
## Are DOUA roluri, si al doilea l-am descoperit tarziu:
##  1. tine PRAGUL spre insulita fixa sub 0.3 m (masurat 0.042 m);
##  2. tine PANTA DE INTRARE pe ponton sub pragul pistei (13%).
##
## Al doilea e cel care conteaza cu plutonul pe el. La `edge_clamp = 5` (prima
## valoare), tablierul cobora de la 0.042 la 0.458 m sub drum pe primii 4 m —
## adica o rampa de **13.4%**, care apare BRUSC cand plutonul urca pe tronson.
## Pragul izolat era in regula; panta nu. Masurat, cu sag_max 0.70:
##    edge_clamp  5 m -> 13.4%   (peste pragul pistei)
##    edge_clamp 10 m ->  7.9%
##    edge_clamp 14 m ->  5.0%   <- ales
##    edge_clamp 18 m ->  3.5%
## 14 m pe un tronson de 43 m lasa 15 m de tablier "plin" la mijloc, deci
## legănarea se simte in continuare.
@export_range(0.0, 24.0, 0.5) var edge_clamp: float = 14.0
## Frecventa (Hz) si amortizarea modului global.
@export_range(0.2, 4.0, 0.05) var sag_freq: float = 0.9
@export_range(0.05, 1.5, 0.05) var sag_damping: float = 0.45

@export_group("Balans")
## Cuplajul masei descentrate in echilibrul balansului.
@export_range(0.0, 3.0, 0.05) var sway_gain: float = 0.9
## Masa efectiva a tablierului, in unitati de mass_factor (tine coeficientul
## sub 1 pentru autobuz).
@export_range(0.5, 10.0, 0.1) var deck_mass: float = 2.2
@export_range(0.1, 2.0, 0.01) var sway_freq: float = 0.38
@export_range(0.05, 1.5, 0.01) var sway_damping: float = 0.30
## Limita moale a deplasarii laterale la mijloc (m).
@export_range(0.2, 3.0, 0.05) var sway_max: float = 0.9

@export_group("Flotabilitate")
## [b]PLAFONUL AFUNDARII[/b] (m). Un ponton are FLOTABILITATE: butoaiele
## deplaseaza un volum finit, deci afundarea se SATUREAZA — nu creste liniar cu
## numarul de masini, cum ar face o coarda.
##
## Fara plafon, afundarea e liniara in incarcare si grila de start o sparge:
## 8 masini pe acelasi tronson dau `_sag_target` ~2.3 m (calculat: 8 x a(2.6) =
## 8 x 0.29), deci tablierul de la +0.60 ajunge la **-1.84 m** — adica SUB plasa
## de repunere a marii (-1.20) si sub apa (0.00). Masurat pe Track22 inainte de
## plafon: 41-56 repuneri per cursa, toate in primul tur, toate pe primul
## tronson, cu autobuzul de doua ori mai des decat restul.
##
## Podul de franghie n-are nevoie de plafon: are 35 m, trece pe el o masina sau
## doua, iar `net_ceiling_drop` ii coboara plasa. Un ponton de pe grila de start
## primeste tot plutonul deodata.
##
## Plafonul e MOALE (tanh), ca sa nu existe un punct in care tablierul se
## opreste brusc: la incarcare mica raspunsul rămâne liniar (deci cifrele de
## calibrare pentru o masina NU se schimba), iar pe masura ce se adauga masini
## se apropie asimptotic de `sag_max`.
@export_range(0.2, 3.0, 0.05) var sag_max: float = 0.70
## Bratul ruliului (m): roll = atan(x / roll_arm). Vezi nota din pod — un brat
## scurt face o masina PARCATA sa alunece spre centru.
@export_range(2.0, 40.0, 0.5) var roll_arm: float = 18.0

@export_group("Tangaj")
## [b]SCHIMBAREA 2 fata de pod.[/b] Cuplajul masei descentrate PE LUNGIME in
## inclinarea longitudinala. 0 stinge tangajul complet (si atunci pontonul e
## podul cu capete libere).
@export_range(0.0, 3.0, 0.05) var pitch_gain: float = 0.8
@export_range(0.1, 2.0, 0.01) var pitch_freq: float = 0.5
@export_range(0.05, 1.5, 0.01) var pitch_damping: float = 0.35
## Limita moale a inclinarii longitudinale (radiani la capat / brat).
@export_range(0.05, 1.5, 0.05) var pitch_max: float = 0.5
## Bratul tangajului (m): pitch = atan(p / pitch_arm).
@export_range(4.0, 60.0, 0.5) var pitch_arm: float = 26.0

@export_group("Valul joncilor")
## [b]SCHIMBAREA 3 fata de pod.[/b] Amplitudinea valului care trece pe sub
## ponton (m). 0 = pontonul e viu doar sub masini, ca podul.
@export_range(0.0, 0.6, 0.01) var wave_amp: float = 0.10
## Perioada valului (s).
@export_range(1.0, 20.0, 0.1) var wave_period: float = 6.5
## Defazaj 0..1: trei tronsoane cu aceeasi faza s-ar mişca la unison si ar citi
## „mecanism", nu „apa" (aceeasi regula ca `phase` la SlidingHazard).
@export_range(0.0, 1.0, 0.01) var wave_phase: float = 0.0
## Cat din val e o unda care CALATORESTE pe lungime (restul e ridicare in bloc).
@export_range(0.0, 1.0, 0.05) var wave_travel: float = 0.6

@export_group("Constructie")
## Incarcari FANTOMA (fractie u, lateral x, mass_factor): apasa tablierul ca
## niste masini care nu exista. Pentru capturi si pentru editor.
@export var preview_loads: Array[Vector3] = []
@export_range(4, 24) var plate_count: int = 12
@export_range(0.0, 0.5, 0.05) var plate_overlap: float = 0.2

var _frame: Transform3D = Transform3D.IDENTITY
var _length: float = 60.0
var _plates: Array[AnimatableBody3D] = []
var _plate_prev: Array[Vector3] = []
var _deck_area: Area3D
var _visual: MeshInstance3D
## Starea celor TREI ecuatii (podul are doua) plus ceasul valului.
var _sag: float = 0.0
var _sag_vel: float = 0.0
var _sway: float = 0.0
var _sway_vel: float = 0.0
var _pitch: float = 0.0
var _pitch_vel: float = 0.0
var _clock: float = 0.0
## Afundarile locale ale tick-ului curent: [u, amplitudine].
var _dips: Array[Vector2] = []
var _sag_gain: float = 0.0
var _sag_exp: float = 1.0
var _sag_target: float = 0.0
var _sway_target: float = 0.0
var _pitch_target: float = 0.0
var _on_deck: Array[Car] = []
var last_tick_usec: int = 0
static var _deck_material: ShaderMaterial


func _ready() -> void:
	_resolve_ends()
	_calibrate()
	_build_plates()
	_build_deck_area()
	_build_visual()
	_place_plates(0.0)
	_push_shader_params()
	# Atlasul DUPA `_ready` (vezi `deck_material`): cerut aici, randarea nu e
	# gata si `Palette.world_material()` pica la crearea texturii.
	_attach_atlas.call_deferred()


## Capetele: copilul „Route" (primul si ultimul punct) sau exporturile.
func _resolve_ends() -> void:
	var route := get_node_or_null("Route") as Path3D
	if route == null:
		for c in get_children():
			if c is Path3D:
				route = c as Path3D
				break
	var a := near_end
	var b := far_end
	if route != null and route.curve != null and route.curve.point_count >= 2:
		a = to_local(route.to_global(route.curve.get_point_position(0)))
		b = to_local(route.to_global(
			route.curve.get_point_position(route.curve.point_count - 1)))
	var chord := b - a
	_length = maxf(chord.length(), 1.0)
	var fwd := chord / _length
	var right := fwd.cross(Vector3.UP)
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	right = right.normalized()
	var up := right.cross(fwd).normalized()
	# Cadrul coardei: -Z de-a lungul tronsonului, +X dreapta, +Y sus.
	_frame = Transform3D(Basis(right, up, -fwd), a)


## a(m) = gain · m^exp prin cele doua puncte de calibrare, cu afundarea locala
## inclusa: o masina la mijloc coboara mijlocul cu a·(1+dip_ratio).
func _calibrate() -> void:
	_sag_exp = log(sag_bus / sag_sport) / log(MASS_BUS / MASS_SPORT)
	_sag_gain = sag_bus / pow(MASS_BUS, _sag_exp) / (1.0 + dip_ratio)


func amplitude_for(mass_factor: float) -> float:
	return _sag_gain * pow(maxf(mass_factor, 0.01), _sag_exp)


# ---------------------------------------------------------------- curba

## Forma modului. [b]SCHIMBAREA 1[/b]: nu moare la capete (podul are 4u(1-u),
## care e zero la u = 0 si u = 1). Oglinda lui `mode_shape` din shader.
func _p(u: float) -> float:
	return free_ends + (1.0 - free_ends) * 4.0 * u * (1.0 - u)


## Stingerea cedarii pe ultimii metri, ca pragul spre insulita fixa sa rămâna
## sub 0.3 m. Oglinda lui `edge_fade` din shader.
func _edge_fade(u: float) -> float:
	if edge_clamp <= 0.0:
		return 1.0
	var m := minf(u, 1.0 - u) * _length
	return smoothstep(0.0, edge_clamp, m)


## Valul joncilor. [b]SCHIMBAREA 3[/b]. Oglinda lui `wave_at` din shader.
func _wave(u: float) -> float:
	if wave_amp <= 0.0:
		return 0.0
	var t := _clock / maxf(wave_period, 0.05) + wave_phase
	# O parte calatoreste pe lungime (unda), restul ridica in bloc (hula).
	var travelling := sin(TAU * (t - u * wave_travel))
	var bulk := sin(TAU * t)
	return wave_amp * lerpf(bulk, travelling, wave_travel)


## Cat coboara linia mediana la fractia u (pozitiv = in jos). Oglinda lui
## deck_drop din pontoon_road.gdshader.
func _drop(u: float) -> float:
	var p := _p(u)
	var fade := _edge_fade(u)
	var d := rest_sag * p + _sag * p * fade - _wave(u) * fade
	for dip in _dips:
		var dz := (u - dip.x) * _length / dip_sigma
		d += dip.y * exp(-dz * dz) * fade
	return d


## Inclinarea longitudinala la fractia u, in metri de ridicare/coborare.
## Pozitiv la u = 1 inseamna capatul departat URCA.
func _pitch_at(u: float) -> float:
	return _pitch * (u - 0.5) * 2.0


## Punctul de pe linia mediana, in cadrul coardei.
func _point(u: float) -> Vector3:
	return Vector3(_sway * sin(PI * u), -_drop(u) + _pitch_at(u), -u * _length)


## Baza unei placi: inainte de-a lungul coardei placii, plus ruliul de leagan
## (deplasat la dreapta, dreapta urca) — acelasi semn ca in shader.
func _plate_basis(fwd: Vector3, u_mid: float) -> Basis:
	var right0 := fwd.cross(Vector3.UP).normalized()
	var up0 := right0.cross(fwd).normalized()
	var phi := atan(_sway * sin(PI * u_mid) / roll_arm)
	var right := right0 * cos(phi) + up0 * sin(phi)
	var up := -right0 * sin(phi) + up0 * cos(phi)
	return Basis(right, up, -fwd)


# ---------------------------------------------------------------- constructie

func _build_plates() -> void:
	_plates.clear()
	_plate_prev.clear()
	for k in plate_count:
		var body := AnimatableBody3D.new()
		body.name = "Plate%d" % k
		body.sync_to_physics = true
		body.set_meta(&"platform_velocity", Vector3.ZERO)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(deck_width, PLATE_THICKNESS,
			_length / float(plate_count) + plate_overlap)
		shape.shape = box
		body.add_child(shape)
		add_child(body)
		_plates.append(body)
		_plate_prev.append(Vector3.ZERO)


## Zona in care cautam masinile: un paralelipiped pe coarda, destul de larg si
## de inalt ca sa cuprinda tablierul in orice stare.
func _build_deck_area() -> void:
	_deck_area = Area3D.new()
	_deck_area.name = "Deck"
	_deck_area.monitoring = true
	_deck_area.monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(deck_width + 2.0 * sway_max + 2.0, 8.0, _length)
	shape.shape = box
	shape.position = Vector3(0.0, 0.5, -_length * 0.5)
	_deck_area.add_child(shape)
	add_child(_deck_area)
	_deck_area.transform = _frame


## Materialul tablierului. Shaderul se leagă acum, dar ATLASUL se cere AMANAT:
## `Palette.world_material()` construieste un `StandardMaterial3D` cu texturi, si
## chemat din `_ready` (adica inainte ca randarea sa fie pregatita) pica cu
## „CreateResource failed" / „Attempting to use an uninitialized RID" — masurat
## la prima captura cu `Snapshot`, care randeaza imediat dupa construirea pistei.
## Podul de franghie nu da eroarea fiindca `Track` il construieste mai tarziu;
## pontonul e declarat ca nod in .tscn, deci `_ready` ii vine primul.
## Acelasi tipar ca memoria `decor-ready-inaintea-temei`.
static func deck_material() -> ShaderMaterial:
	if _deck_material == null:
		_deck_material = ShaderMaterial.new()
		_deck_material.shader = load(SHADER_PATH)
	return _deck_material


## Pune atlasul pe materialul tablierului. Se cheama AMANAT (vezi
## `deck_material`), deci o singura data pe material, nu per ponton.
static func _attach_atlas() -> void:
	if _deck_material == null:
		return
	if _deck_material.get_shader_parameter(&"atlas") != null:
		return
	# ACEEASI textura ca materialul lumii: niciun asset nou, niciun material in
	# plus la numaratoarea garzii.
	_deck_material.set_shader_parameter(&"atlas",
		Palette.world_material().albedo_texture)


## Un singur mesh in cadrul coardei: scanduri de bambus + butoaie de flotor
## sub margini. FARA balustrade si FARA turnuri (brief §3: cazi in apa,
## RespawnZone te repune) — si fara ele nu exista nimic de care sa se agate
## ochiul ca „pod".
func _build_visual() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := deck_width * 0.5
	var pitch_step := PLANK_WIDTH + PLANK_GAP
	var n_planks := int(floor(_length / pitch_step))
	var start := (_length - n_planks * pitch_step) * 0.5
	for k in n_planks:
		var z := -(start + (float(k) + 0.5) * pitch_step)
		# Variatie de valoare intre scanduri (doar intuneca: vertex color).
		var shade := 0.80 + 0.20 * fmod(float(k) * 0.618, 1.0)
		_box(st, Vector3(0.0, -PLANK_THICKNESS * 0.5, z),
			Vector3(deck_width, PLANK_THICKNESS, PLANK_WIDTH), WOOD_SLOT, shade)
	# Butoaiele albastre de flotor, perechi sub margini. Cutii, nu cilindri: la
	# scara asta se citesc la fel si costa 12 triunghiuri in loc de sute (vezi
	# CLAUDE.md despre primitive la rezolutia implicita).
	var n_drums := maxi(2, int(floor(_length / DRUM_STEP)))
	for k in n_drums:
		var z := -(_length * (float(k) + 0.5) / float(n_drums))
		for side: float in [-1.0, 1.0]:
			_box(st, Vector3(side * (hw - DRUM_RADIUS - 0.1),
				-PLANK_THICKNESS - DRUM_RADIUS, z),
				Vector3(DRUM_RADIUS * 2.0, DRUM_RADIUS * 2.0, DRUM_RADIUS * 2.2),
				DRUM_SLOT, 0.95)
	_visual = MeshInstance3D.new()
	_visual.name = "DeckVisual"
	_visual.mesh = st.commit()
	_visual.material_override = deck_material()
	# Deformarea muta vertecsii: AABB-ul static ar culla pontonul cand doar
	# mijlocul lui e in cadru.
	var aabb: AABB = _visual.mesh.get_aabb()
	_visual.custom_aabb = aabb.grow(3.0)
	add_child(_visual)
	_visual.transform = _frame
	_visual.set_instance_shader_parameter(&"deck_length", _length)
	_visual.set_instance_shader_parameter(&"rest_sag", rest_sag)
	_visual.set_instance_shader_parameter(&"free_ends", free_ends)
	_visual.set_instance_shader_parameter(&"edge_clamp", edge_clamp)
	_visual.set_instance_shader_parameter(&"roll_arm", roll_arm)
	_visual.set_instance_shader_parameter(&"dip_sigma", dip_sigma)


## Cutie axata, 12 triunghiuri, UV pe centrul slotului, vertex color = AO.
## (Aceeasi forma ca `RopeBridgeHazard._box`; e copiata deliberat, ca pontonul
## sa nu depinda de clasa podului — vezi antetul.)
static func _box(st: SurfaceTool, center: Vector3, size: Vector3, slot: int,
		shade: float) -> void:
	var h := size * 0.5
	var uv := Palette.uv(slot)
	var col := Color(shade, shade, shade)
	var faces := [
		[Vector3.UP, Vector3(-1, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, -1), Vector3(-1, 1, -1)],
		[Vector3.DOWN, Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, -1, 1), Vector3(-1, -1, 1)],
		[Vector3.RIGHT, Vector3(1, -1, 1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1)],
		[Vector3.LEFT, Vector3(-1, -1, -1), Vector3(-1, -1, 1), Vector3(-1, 1, 1), Vector3(-1, 1, -1)],
		[Vector3.BACK, Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)],
		[Vector3.FORWARD, Vector3(1, -1, -1), Vector3(-1, -1, -1), Vector3(-1, 1, -1), Vector3(1, 1, -1)],
	]
	for f: Array in faces:
		var normal: Vector3 = f[0]
		var pts: Array[Vector3] = []
		for k in range(1, 5):
			pts.append(center + (f[k] as Vector3) * h)
		for tri: Array in [[0, 1, 2], [0, 2, 3]]:
			for k: int in tri:
				st.set_normal(normal)
				st.set_uv(uv)
				st.set_color(col)
				st.add_vertex(pts[k])


# ---------------------------------------------------------------- tick

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _plates.is_empty():
		return
	var t0 := Time.get_ticks_usec()
	_clock += delta
	_gather_loads()
	_integrate(delta)
	_place_plates(delta)
	_push_shader_params()
	last_tick_usec = Time.get_ticks_usec() - t0


## Masinile de pe ponton si incarcarile lor: tinta sagetii, a balansului si
## (nou) a tangajului.
func _gather_loads() -> void:
	_on_deck.clear()
	_dips.clear()
	_sag_target = 0.0
	var moment_lat := 0.0
	var moment_long := 0.0
	var load := 0.0
	var inv := _frame.affine_inverse()
	for b in _deck_area.get_overlapping_bodies():
		var car := b as Car
		if car == null or not car.is_on_floor():
			continue
		var local := inv * to_local(car.global_position)
		var u := -local.z / _length
		if u < 0.0 or u > 1.0 or absf(local.x) > deck_width * 0.5 + 1.0:
			continue
		if absf(local.y + _drop(u)) > 1.5:
			continue
		_on_deck.append(car)
		var a := amplitude_for(car.mass_factor)
		var p := _p(u)
		_sag_target += a * p
		moment_lat += car.mass_factor * local.x * p
		# TANGAJ: bratul e distanta fata de mijloc, pe lungime.
		moment_long += car.mass_factor * (u - 0.5) * _length * p
		load += car.mass_factor * p
		_dips.append(Vector2(u, a * dip_ratio))
	for ph in preview_loads:
		var a := amplitude_for(ph.z)
		var uu := clampf(ph.x, 0.0, 1.0)
		var p := _p(uu)
		_sag_target += a * p
		moment_lat += ph.z * ph.y * p
		moment_long += ph.z * (uu - 0.5) * _length * p
		load += ph.z * p
		_dips.append(Vector2(uu, a * dip_ratio))
	# FLOTABILITATE: plafon moale pe afundare (vezi `sag_max`). `tanh` pastreaza
	# raspunsul liniar la incarcare mica — pentru o singura masina `tanh(x) ≈ x`
	# pana la ~0.3, iar a(2.6)/sag_max = 0.41, deci cifrele de calibrare se
	# schimba cu < 6% — si satureaza cand se adauga mai multe.
	if sag_max > 0.0:
		_sag_target = sag_max * tanh(_sag_target / sag_max)
	_sway_target = sway_gain * moment_lat / (deck_mass + load)
	# Tangajul se normalizeaza pe LUNGIME, altfel un tronson lung ar da un
	# echilibru de zeci de metri. Rezultatul e in metri de ridicare la capat.
	#
	# SEMNUL MINUS e esential, si l-am avut invers la prima scriere (prins de
	# `probe_ponton` garda 6): `_pitch_at(u) = _pitch·(u-0.5)·2` se ADUNA la
	# cota in `_point`, deci un `_pitch` POZITIV ridica capatul departat. Masa
	# pusa spre capatul departat da `moment_long > 0` — iar ea trebuie sa
	# COBOARE capatul pe care sta, nu sa-l ridice. Deci tinta e negata.
	_pitch_target = -pitch_gain * moment_long / ((deck_mass + load) * maxf(_length, 1.0))
	if _dips.size() > 4:
		_dips.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y > b.y)
		_dips.resize(4)
	# Afundarile LOCALE trec si ele prin plafon, altfel patru masini lipite ar
	# aduna patru gaussiene in acelasi punct si ar scufunda tablierul pe lângă
	# saturatia modului global. Suma lor se limiteaza la jumatate din `sag_max`:
	# restul plafonului rămâne pentru modul global.
	if sag_max > 0.0 and not _dips.is_empty():
		var dip_sum := 0.0
		for d in _dips:
			dip_sum += d.y
		var cap := sag_max * 0.5
		if dip_sum > cap:
			var k := cap / dip_sum
			for i in _dips.size():
				_dips[i] = Vector2(_dips[i].x, _dips[i].y * k)


func _integrate(delta: float) -> void:
	var ws := TAU * sag_freq
	var acc := ws * ws * (_sag_target - _sag) - 2.0 * sag_damping * ws * _sag_vel
	_sag_vel += acc * delta
	_sag += _sag_vel * delta
	var wl := TAU * sway_freq
	var acc_l := wl * wl * (_sway_target - _sway) - 2.0 * sway_damping * wl * _sway_vel
	var excess := absf(_sway) - sway_max
	if excess > 0.0:
		acc_l -= wl * wl * 8.0 * excess * signf(_sway)
	_sway_vel += acc_l * delta
	_sway += _sway_vel * delta
	# TANGAJ (schimbarea 2): acelasi tipar, pe axa longitudinala.
	var wp := TAU * pitch_freq
	var acc_p := wp * wp * (_pitch_target - _pitch) - 2.0 * pitch_damping * wp * _pitch_vel
	var excess_p := absf(_pitch) - pitch_max
	if excess_p > 0.0:
		acc_p -= wp * wp * 8.0 * excess_p * signf(_pitch)
	_pitch_vel += acc_p * delta
	_pitch += _pitch_vel * delta


## O SINGURA scriere de transform per placa pe tick; viteza placii din
## deplasarea centrului ei (delta 0 = asezarea initiala, viteza zero).
func _place_plates(delta: float) -> void:
	var n := plate_count
	var half_t := Vector3.UP * (PLATE_THICKNESS * 0.5)
	for k in n:
		var u0 := float(k) / float(n)
		var u1 := float(k + 1) / float(n)
		var p0 := _point(u0)
		var p1 := _point(u1)
		var fwd := (p1 - p0).normalized()
		var basis := _plate_basis(fwd, (u0 + u1) * 0.5)
		var center := (p0 + p1) * 0.5 - basis * half_t
		var xf := global_transform * _frame * Transform3D(basis, center)
		var body := _plates[k]
		var vel := Vector3.ZERO
		if delta > 0.0:
			vel = (xf.origin - _plate_prev[k]) / delta
		_plate_prev[k] = xf.origin
		body.global_transform = xf
		body.set_meta(&"platform_velocity", vel)


func _push_shader_params() -> void:
	if _visual == null:
		return
	_visual.set_instance_shader_parameter(&"sag", _sag)
	_visual.set_instance_shader_parameter(&"sway", _sway)
	_visual.set_instance_shader_parameter(&"pitch", _pitch)
	_visual.set_instance_shader_parameter(&"wave_amp", wave_amp)
	_visual.set_instance_shader_parameter(&"wave_t",
		_clock / maxf(wave_period, 0.05) + wave_phase)
	_visual.set_instance_shader_parameter(&"wave_travel", wave_travel)
	var du := Vector4(-1.0, -1.0, -1.0, -1.0)
	var da := Vector4.ZERO
	for i in mini(_dips.size(), 4):
		du[i] = _dips[i].x
		da[i] = _dips[i].y
	_visual.set_instance_shader_parameter(&"dip_u", du)
	_visual.set_instance_shader_parameter(&"dip_a", da)


# ---------------------------------------------------------------- pentru sonde

func sag_amplitude() -> float:
	return _sag


func sway() -> float:
	return _sway


## Inclinarea longitudinala (metri de ridicare la capatul departat).
func pitch() -> float:
	return _pitch


## Cat e coborata linia mediana la fractia u FATA DE REPAUS (m).
func sag_at(u: float) -> float:
	return _drop(u) - rest_sag * _p(u)


## Coborarea totala (cu repaus si val) la fractia u.
func drop_at(u: float) -> float:
	return _drop(u)


## [b]PRAGUL LA INSULITA[/b]: cat coboara tablierul la buza, adica treapta pe
## care o simte masina intrand de pe piatra fixa. Contractul: < 0.3 m (memoria
## `suprafete-cu-goluri-si-praguri`). Sonda `probe_ponton` o verifica in starea
## cea mai defavorabila (autobuz pe buza).
func edge_drop() -> float:
	return maxf(absf(_drop(0.0)), absf(_drop(1.0)))


func deck_length() -> float:
	return _length


func deck_width_m() -> float:
	return deck_width


func cars_on_deck() -> Array[Car]:
	return _on_deck


## Pozitia globala -> (x lateral fata de coarda, y fata de LINIA MEDIANA in
## starea curenta, u fractia). y ≈ 0 = pe scanduri.
func deck_coords(global_pos: Vector3) -> Vector3:
	var local := _frame.affine_inverse() * to_local(global_pos)
	var u := clampf(-local.z / _length, 0.0, 1.0)
	return Vector3(local.x - _sway * sin(PI * u), local.y + _drop(u), u)


## Punctul global de pe linia mediana la fractia u (starea curenta).
func deck_point_global(u: float) -> Vector3:
	return global_transform * (_frame * _point(u))


func plates() -> Array[AnimatableBody3D]:
	return _plates


## Sare peste dinamica: starea = tinta incarcarilor curente (capturi, sonde).
func settle_now() -> void:
	_gather_loads()
	_sag = _sag_target
	_sag_vel = 0.0
	_sway = _sway_target
	_sway_vel = 0.0
	_pitch = _pitch_target
	_pitch_vel = 0.0
	_place_plates(0.0)
	_push_shader_params()


## Ceasul valului, pentru sonde si capturi (faza forțată).
func set_clock(t: float) -> void:
	_clock = t


# ---------------------------------------------------------------- pentru Track

## Contractul gaurii de carosabil (Track._resolve_span_holes): cati metri de
## sosea lipsesc, centrati pe pozitia nodului.
func road_hole_span() -> float:
	if _length <= 1.0:
		_resolve_ends()
	return _length


## Fara rampa de serviciu: peretele pistei (daca exista) nu se degajeaza.
func wall_clear_span() -> float:
	return 0.0


## Cu cat trebuie coborat plafonul plasei de repunere de sub ponton fata de cota
## soselei.
##
## Se socoteste din PLAFONUL de afundare (`sag_max`), nu din `sag_bus`: cu
## flotabilitate, cat de jos poate ajunge tablierul nu mai depinde de cate
## masini sunt pe el, ci de saturatie. Plus repausul, plus valul (de doua ori
## amplitudinea: hula coboara si urca), plus o marja de 0.3 m — altfel masina
## de pe ponton e „cazuta" exact in clipa in care valul o duce jos.
func net_ceiling_drop() -> float:
	return rest_sag + sag_max + wave_amp * 2.0 + 0.3
