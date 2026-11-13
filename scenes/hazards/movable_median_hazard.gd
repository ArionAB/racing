class_name MovableMedianHazard
extends Node3D
## DESPARTITORUL MOBIL de pe podul rosu (San Francisco, brief
## docs/track_briefs/san_francisco.md §7 pasul 1d): un rand de blocuri de beton
## intre cele doua sensuri ale tablierului, pe care un camion lent il muta pe
## diagonala — ca masinile care muta despartitorul pe podurile reale. In fata
## camionului bariera e pe pozitia veche, in spate pe cea noua, cu o tranzitie
## in S sub el. Deci banda ta se ingusteaza sau se largeste dupa unde e camionul.
##
## GEOMETRIA (cadrul local al nodului): +X = de-a lungul tablierului (s, de la 0
## la `deck_length`), +Z = lateral (z), Y = suprafata de rulare. Bariera e o
## FUNCTIE DE POZITIA CAMIONULUI, nu o stare ascunsa:
##
##   offset(s) = offset_m * taper(s) * (2 * smoothstep((s - s_t + L/2) / L) - 1)
##
## cu s_t pozitia camionului si L = `transition_m`. La stanga camionului (s mic)
## bariera e la -offset_m, la dreapta la +offset_m; camionul face naveta intre
## capete, deci de fiecare data cand trece, intoarce bariera dupa el. `taper`
## o aduce la 0 (axa, unde continua despartitorul fix) pe `taper_m` la ambele
## capete; camionul nu intra in zona de racord (s_t intre taper + L/2 si
## deck_length - taper - L/2), ca S-ul sa nu se suprapuna peste racord.
##
## FIZICA: blocurile sunt `AnimatableBody3D` separate (perete VERTICAL: o cutie
## de 0,95 m, nu profil de rampa — memoria cu pragurile: o bariera in panta
## arunca masinile peste ea). Intr-un tick se misca doar blocurile din fereastra
## S-ului (~12 din ~100), cu o singura scriere de transform fiecare (memoria
## `jolt-sync-transform-o-singura-scriere`); restul stau. Vizual: un singur
## MultiMesh. Camionul e un corp cinematic cu meta `soft_hit_crush` (corp greu,
## nu zid de beton: lovitura nu ejecteaza soferul), fara frecare.
##
## AI ONEST (`ai_reads_corridor`, implicit STINS): AI-ul citeste culoarul liber
## de pe banda lui ACUM — unde e bariera (si camionul) in fereastra pe care o
## vede in fata, ca jucatorul — niciodata faza sau unde va fi. Vezi
## `AIController._median_line` si `corridor()`. Cu flagul stins nodul nu intra in
## grup, deci AI-ul nu face nimic in plus (pistele existente nu au nodul deloc).

## Lungimea tablierului acoperit de bariera mobila (m, de-a lungul +X local).
@export var deck_length: float = 300.0
## Cat de departe de axa sta bariera in cele doua pozitii (m). 3,5 m pe o
## jumatate de tablier de 12,2 m: o banda de ~8,4 m si cealalta de ~15,4 m.
@export_range(0.0, 6.0, 0.1) var offset_m: float = 3.5
## Lungimea tranzitiei in S de sub camion (m).
@export_range(10.0, 60.0, 1.0) var transition_m: float = 30.0
## Racordul fix la capete, de la axa (despartitorul fix) la pozitia mobila (m).
@export_range(5.0, 60.0, 1.0) var taper_m: float = 30.0
## Blocul de beton: lungime de pas (m), latime, inaltime.
@export var block_len: float = 3.0
@export var block_width: float = 0.6
@export var block_height: float = 0.95
## Despartitor FIX pe pamant, la axa, inainte si dupa tablier (m): aceleasi
## blocuri, statice (unde se largeste soseaua spre tablier, AI-ul trebuie sa-l
## vada si el).
@export var approach_m: float = 36.0
## Semilatimea tablierului pana la fata interioara a parapetului exterior (m).
## Doar pentru culoarul AI-ului: soseaua de pe tablier e mai lata (benzile se
## suprapun la mijloc), parapetul e marginea reala.
@export var deck_half_width: float = 12.2
## Pe ce latura (+1 = +Z local, -1 = -Z) circula sensul care merge spre +X.
@export_enum("Plus:1", "Minus:-1") var plus_dir_side: int = 1

@export_group("Camion")
## Camionul care muta bariera. Stins = bariera inghetata (vezi `static_center`).
@export var truck_enabled: bool = true
@export_range(1.0, 10.0, 0.1) var truck_speed: float = 4.0
## Cat sta pe loc la fiecare capat (s).
@export_range(0.0, 30.0, 0.5) var truck_dwell_s: float = 6.0
## Gabarit (latime, inaltime, lungime).
@export var truck_size: Vector3 = Vector3(2.6, 3.2, 10.0)
## Faza de start, fractie din ciclul complet (dus + asteptare + intors + asteptare).
## 0 = la capatul dinspre s=0, gata sa porneasca spre +X.
@export_range(0.0, 1.0, 0.001) var phase: float = 0.0
## A/B: bariera FIXA la axa pe tot tablierul, fara camion (despartitorul clasic).
@export var static_center: bool = false
@export var soft_crush_s: float = 1.0

@export_group("AI")
## AI-ul citeste culoarul liber curent. Implicit stins.
@export var ai_reads_corridor: bool = false
## SABOTAJ: AI-ul citeste bariera de la incarcare (fotografia de la t=0), nu pe
## cea de acum. Are sens doar cu `ai_reads_corridor`.
@export var ai_static_read: bool = false

const AI_GROUP: StringName = &"ai_median_corridor"

## Pozitia camionului (s) si sensul (+1 / -1), pentru sonde.
var truck_s: float = 0.0
var truck_dir: float = 1.0
## Costul ultimului tick (us), pentru sonde.
var last_tick_usec: int = 0
## Cate blocuri s-au mutat in ultimul tick (pentru sonde / bugetul de fizica).
var last_moved: int = 0

var _time: float = 0.0
var _blocks: Array[AnimatableBody3D] = []
var _block_z: PackedFloat32Array = PackedFloat32Array()
var _block_yaw: PackedFloat32Array = PackedFloat32Array()
var _mm: MultiMesh = null
var _mm_fixed_first: int = 0
var _truck: AnimatableBody3D = null
var _static_s_t: float = 0.0
var _prev_win := Vector2i(0, -1)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_static_s_t = _truck_s_at(_cycle_time(0.0))
	truck_s = _static_s_t
	_build()
	if ai_reads_corridor:
		add_to_group(AI_GROUP)


# ------------------------------------------------------------------ legea

func _s_lo() -> float:
	return taper_m + transition_m * 0.5


func _s_hi() -> float:
	return maxf(deck_length - taper_m - transition_m * 0.5, _s_lo())


## Durata unui ciclu complet (s).
func cycle_s() -> float:
	var run := (_s_hi() - _s_lo()) / maxf(truck_speed, 0.01)
	return 2.0 * (run + truck_dwell_s)


func _cycle_time(t: float) -> float:
	return fposmod(t + phase * cycle_s(), cycle_s())


## Pozitia camionului la timpul de ciclu `ct` (si sensul in `truck_dir`).
func _truck_s_at(ct: float) -> float:
	var run := (_s_hi() - _s_lo()) / maxf(truck_speed, 0.01)
	if ct < run:
		truck_dir = 1.0
		return _s_lo() + ct * truck_speed
	ct -= run
	if ct < truck_dwell_s:
		truck_dir = -1.0
		return _s_hi()
	ct -= truck_dwell_s
	if ct < run:
		truck_dir = -1.0
		return _s_hi() - ct * truck_speed
	truck_dir = 1.0
	return _s_lo()


func _taper(s: float) -> float:
	if s <= 0.0 or s >= deck_length:
		return 0.0
	return smoothstep(0.0, taper_m, s) * smoothstep(0.0, taper_m, deck_length - s)


## Lateralul centrului barierei (z local) la distanta `s`, cu camionul la `s_t`.
func offset_at(s: float, s_t: float = INF) -> float:
	if static_center:
		return 0.0
	if s_t == INF:
		s_t = truck_s
	var g := smoothstep(s_t - transition_m * 0.5, s_t + transition_m * 0.5, s)
	return offset_m * _taper(s) * (2.0 * g - 1.0)


func _slope_at(s: float, s_t: float) -> float:
	var h := 0.5
	return (offset_at(s + h, s_t) - offset_at(s - h, s_t)) / (2.0 * h)


# --------------------------------------------------------------- constructie

func _block_count() -> int:
	return int(ceil(deck_length / block_len))


func _build() -> void:
	var n := _block_count()
	var n_fixed := int(ceil(approach_m / block_len)) * 2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.62, 0.6)
	var bm := BoxMesh.new()
	bm.size = Vector3(block_len + 0.1, block_height, block_width)
	bm.material = mat
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.mesh = bm
	_mm.instance_count = n + n_fixed
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Blocuri"
	mmi.multimesh = _mm
	add_child(mmi)
	var pmat := PhysicsMaterial.new()
	pmat.friction = 0.1
	pmat.bounce = 0.0
	var shape := BoxShape3D.new()
	shape.size = Vector3(block_len + 0.15, block_height, block_width)
	_block_z.resize(n)
	_block_yaw.resize(n)
	for k in n:
		var s := (float(k) + 0.5) * block_len
		var body := AnimatableBody3D.new()
		body.name = "Bloc%d" % k
		body.sync_to_physics = true
		body.physics_material_override = pmat
		var cs := CollisionShape3D.new()
		cs.shape = shape
		body.add_child(cs)
		add_child(body)
		_blocks.append(body)
		_block_z[k] = INF
		_place_block(k, s, _static_s_t, true)
	# despartitorul fix de pe pamant: un singur corp static, cutii la axa
	_mm_fixed_first = n
	var fixed := StaticBody3D.new()
	fixed.name = "DespartitorFix"
	fixed.physics_material_override = pmat
	add_child(fixed)
	var nf := n_fixed / 2
	for side in [-1.0, 1.0]:
		for k in nf:
			var s: float = -approach_m + (float(k) + 0.5) * block_len if side < 0.0 \
				else deck_length + (float(k) + 0.5) * block_len
			var cs := CollisionShape3D.new()
			cs.shape = shape
			cs.position = Vector3(s, block_height * 0.5 - 0.05, 0.0)
			fixed.add_child(cs)
			var idx := n + (0 if side < 0.0 else nf) + k
			_mm.set_instance_transform(idx, Transform3D(Basis.IDENTITY, cs.position))
	if truck_enabled and not static_center:
		_build_truck()
		_place_truck()


func _block_xform(s: float, z: float, yaw: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw), Vector3(s, block_height * 0.5 - 0.05, z))


func _place_block(k: int, s: float, s_t: float, force: bool) -> bool:
	var z := offset_at(s, s_t)
	var yaw := -atan(_slope_at(s, s_t))
	if not force and absf(z - _block_z[k]) < 1e-4 and absf(yaw - _block_yaw[k]) < 1e-5:
		return false
	_block_z[k] = z
	_block_yaw[k] = yaw
	var xf := _block_xform(s, z, yaw)
	_blocks[k].transform = xf
	_mm.set_instance_transform(k, xf)
	return true


func _build_truck() -> void:
	_truck = AnimatableBody3D.new()
	_truck.name = "Camion"
	_truck.sync_to_physics = true
	var pmat := PhysicsMaterial.new()
	pmat.friction = 0.0
	pmat.bounce = 0.0
	_truck.physics_material_override = pmat
	_truck.set_meta(&"soft_hit_crush", soft_crush_s)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(truck_size.z, truck_size.y, truck_size.x)
	cs.shape = box
	cs.position = Vector3(0.0, truck_size.y * 0.5 + 0.05, 0.0)
	_truck.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.52)
	bm.material = mat
	mi.mesh = bm
	mi.position = cs.position
	_truck.add_child(mi)
	# cabina, ca sa se vada incotro merge (doar vizual)
	var cab := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(2.2, 1.2, truck_size.x - 0.2)
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.38, 0.38, 0.4)
	cm.material = cmat
	cab.mesh = cm
	cab.name = "Cabina"
	cab.position = Vector3(truck_size.z * 0.5 - 1.1, truck_size.y + 0.6, 0.0)
	_truck.add_child(cab)
	add_child(_truck)


func _truck_yaw() -> float:
	return -atan(_slope_at(truck_s, truck_s))


func _place_truck() -> void:
	if _truck == null:
		return
	var yaw := _truck_yaw()
	if truck_dir < 0.0:
		yaw += PI
	_truck.transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(truck_s, 0.0, 0.0))


# ------------------------------------------------------------------- tick

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _blocks.is_empty():
		return
	var t0 := Time.get_ticks_usec()
	_time += delta
	last_moved = 0
	if truck_enabled and not static_center:
		truck_s = _truck_s_at(_cycle_time(_time))
		_place_truck()
		var half := transition_m * 0.5 + block_len
		var lo := maxi(int(floor((truck_s - half) / block_len)), 0)
		var hi := mini(int(ceil((truck_s + half) / block_len)), _block_count() - 1)
		var a := mini(lo, _prev_win.x)
		var b := maxi(hi, _prev_win.y)
		for k in range(a, b + 1):
			if _place_block(k, (float(k) + 0.5) * block_len, truck_s, false):
				last_moved += 1
		_prev_win = Vector2i(lo, hi)
	last_tick_usec = int(Time.get_ticks_usec() - t0)


# --------------------------------------------------------------- pentru AI

## Fata obstacolului dinspre latura `side` (+1 / -1) la distanta `s`, in z local:
## marginea barierei (sau a camionului, daca e acolo) spre banda de pe `side`.
## `s_t` = pozitia camionului de folosit (INF = acum).
func obstacle_face(s: float, side: float, s_t: float = INF) -> float:
	if s_t == INF:
		s_t = truck_s
	var face := side * offset_at(s, s_t) + block_width * 0.5
	if _truck != null and not static_center:
		# Colturile camionului (cutie rotita) proiectate pe latura ceruta, cand
		# `s` cade in lungul lui.
		var yaw := -atan(_slope_at(s_t, s_t))
		var fwd := Vector2(cos(yaw), -sin(yaw))     # (s, z) din Basis(UP, yaw)
		var right := Vector2(sin(yaw), cos(yaw))
		var hl := truck_size.z * 0.5
		var hw := truck_size.x * 0.5
		var smin := INF
		var smax := -INF
		var zmax := -INF
		for a in [-1.0, 1.0]:
			for b in [-1.0, 1.0]:
				var c: Vector2 = Vector2(s_t, 0.0) + fwd * hl * a + right * hw * b
				smin = minf(smin, c.x)
				smax = maxf(smax, c.x)
				zmax = maxf(zmax, side * c.y)
		if s >= smin and s <= smax:
			face = maxf(face, zmax)
	return face


## Culoarul liber (z local, [lo, hi], lo < hi) pentru un punct din lume aflat pe
## latura `side`, peste fereastra [s - back_m, s + ahead_m] in sensul de mers
## `dir_s` (+1 spre +X). Fata cea mai stransa din fereastra castiga. Pe latura
## + culoarul e [fata + marja, parapet - marja]; pe latura - simetric.
## Intoarce Vector2.INF in afara despartitorului (fix + mobil).
func corridor(local: Vector3, side: float, dir_s: float, ahead_m: float,
		back_m: float = 3.0) -> Vector2:
	var s0 := local.x
	if s0 < -approach_m - 5.0 or s0 > deck_length + approach_m + 5.0:
		return Vector2.INF
	var s_t := _static_s_t if ai_static_read else truck_s
	var face := -INF
	var a := s0 - back_m * dir_s
	var b := s0 + ahead_m * dir_s
	var lo_s := minf(a, b)
	var hi_s := maxf(a, b)
	var step := 1.5
	var s := lo_s
	while s <= hi_s + 0.01:
		face = maxf(face, obstacle_face(s, side, s_t))
		s += step
	if side > 0.0:
		return Vector2(face, deck_half_width)
	return Vector2(-deck_half_width, -face)


## Latimea libera a benzii de pe latura `side` la `s` (m), pentru sonde.
func lane_width_at(s: float, side: float) -> float:
	return deck_half_width - obstacle_face(s, side)


## In ce latura e un punct (local) fata de bariera de acum: +1 / -1.
func side_of(local: Vector3) -> float:
	return 1.0 if local.z >= offset_at(local.x) else -1.0


## Corpul camionului (pentru sonde), sau null.
func truck_body() -> AnimatableBody3D:
	return _truck


func is_block(body: Object) -> bool:
	return body is AnimatableBody3D and _blocks.has(body) \
		or (body is StaticBody3D and (body as Node).get_parent() == self \
			and String((body as Node).name) == "DespartitorFix")
