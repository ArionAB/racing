class_name ModulePlacer
extends Node3D
## PLACER DE MODULE PE CURBA (Kyoto, Track18: podurile, esafodajul scenei).
##
## Un GLB-MODUL are originea in centrul lui, pe axa drumului, puntea la y = 0,
## -Z inainte (sensul de mers) si lungimea `module_length` pe Z. Placerul il
## repeta de-a lungul benzii `route_index` intre doua FRACTII de tur, cu yaw din
## tangenta si cota din drum. Ce NU face: nu construieste puntea (asfaltul e cod),
## nu pune parapetul (`deck_rails` ramane procedural: fara el ProbeRace a repus 47
## de masini) si nu pune padure. E fratele generic al [ToriiTunnel], care face
## acelasi lucru pentru portile dintr-o scurtatura.
##
## [b]Cusaturile pe curba.[/b] Un modul drept pe o curba lasa o panglica de gol la
## exteriorul cusaturii (si o suprapunere la interior): `sagetile` modulelor
## succesive difera cu unghiul dintre ele. Fiecare modul se aseaza cu CAPETELE pe
## curba (centrul = mijlocul coardei, yaw = directia coardei), deci doua module
## vecine impart exact punctul de pe axa si difera doar prin unghiul dintre
## coarde; golul de la marginea `seam_half_width` se MASOARA (`max_seam_gap_m`) si
## se poate acoperi cu `seam_overlap_m` (modulele au capete plate, deci o
## suprapunere de zeci de centimetri nu se vede). Pe dreapta e zero.
##
## [b]Pasul.[/b] Modulele acopera INTREG intervalul: primul cu capatul pe
## `frac_from`, ultimul pe `frac_to`; numarul e cel mai mic pentru care pasul iese
## <= lungimea modulului (+ `seam_overlap_m`), deci lungimile care nu se impart
## exact se rezolva prin suprapunere, niciodata printr-un gol.
##
## Fractia e pe INDICE (ca [method TrackRoute.frac_at]): coapta e la pas uniform,
## deci coincide cu cea a CameraZone si a latimilor din generator.
##
## Piesele sunt [WorldProp] (aceleasi clase/sloturi ca restul decorului); coliziunea
## se impune per instanta prin metadata `coliziune` ("none" la punti acoperite,
## "mesh" la esafodaj), nu din tabelul global.

@export var model: PackedScene = null
@export var route_index: int = 0
@export_range(0.0, 1.0, 0.0001) var frac_from: float = 0.0
## `frac_to <= frac_from` = o SINGURA piesa, centrata pe `frac_from`.
@export_range(0.0, 1.0, 0.0001) var frac_to: float = 0.0
## Lungimea modulului pe Z (m), cum o da inventarul.
@export_range(0.5, 40.0, 0.01, "suffix:m") var module_length: float = 6.0
## Decalaje laterale (m, + = dreapta): un modul pe fiecare, in fiecare rand.
@export var lateral_offsets: PackedFloat32Array = PackedFloat32Array([0.0])
## Cota fata de axa drumului (m). Esafodajul atarna sub punte: negativ.
@export var y_offset: float = 0.0
## "none" | "mesh" | "hull" | "trunk" (vezi WorldProp.COLLISION_MODES).
@export var collision_mode: String = "none"
## Suprapunere voita intre module (m), pentru cusaturile de pe curba.
@export_range(0.0, 3.0, 0.01, "suffix:m") var seam_overlap_m: float = 0.0
## Semilatimea la care se masoara golul cusaturii (marginea exterioara a piesei).
@export_range(0.5, 15.0, 0.1, "suffix:m") var seam_half_width: float = 7.0
## Cat din interval poate ramane neacoperit (m) ca sa nu se adauge un modul
## intreg pentru o fractiune de centimetri (6,02 m / 6 m = 7 module, nu 6).
@export_range(0.0, 1.0, 0.01, "suffix:m") var span_tolerance_m: float = 0.2
## ESAFODAJ DE LA TEREN PANA SUB PUNTE: cand e pornit, fiecare modul isi ia baza
## din cel mai jos punct al terenului din amprenta lui (`ground_margin` sub el, ca
## nicio talpa sa nu pluteasca) si se scaleaza pe Y pana la `top_offset` fata de
## drum. Terenul de sub scena variaza cu +-4 m (adancime 12,5-16,3 m masurata cu
## ProbeKyotoRapa), iar un modul de 16 m fix ori plutea, ori intra in punte.
## Scara e pe modelul interior (nu pe nodul-corp), deci coliziunea `mesh` iese
## scalata corect fara corp fizic cu scara neuniforma.
@export var ground_fit: bool = false
## Latimea amprentei modulului pe X (m), pentru esantionarea terenului.
@export_range(0.5, 40.0, 0.01, "suffix:m") var module_width: float = 6.8
@export_range(1.0, 60.0, 0.01, "suffix:m") var module_height: float = 16.0
@export_range(-3.0, 3.0, 0.01, "suffix:m") var top_offset: float = -0.08
@export_range(0.0, 3.0, 0.05, "suffix:m") var ground_margin: float = 0.3
@export_range(0.2, 3.0, 0.05) var min_height_scale: float = 0.5
@export_range(0.2, 4.0, 0.05) var max_height_scale: float = 2.0
## Noduri din modul de ascuns (`visible = false`), dupa nume; ex. `Tsu_Rail`
## cand dubleaza parapetul procedural. Un nod ascuns nu se randeaza, deci nu e
## nici material, nici triunghi in garda.
@export var hide_nodes: PackedStringArray = PackedStringArray()
## Modulul urmareste panta drumului (pitch). Implicit nu: podurile sunt drepte
## si orizontale, esafodajul e vertical.
@export var follow_pitch: bool = false

var _track: Track = null
var module_count: int = 0
var max_seam_gap_m: float = 0.0
var max_seam_overlap_m: float = 0.0
var max_yaw_step_deg: float = 0.0
var built: bool = false
var min_scale_used: float = 1e9
var max_scale_used: float = 0.0


func _ready() -> void:
	_place.call_deferred()


func _find_track() -> Track:
	if _track != null:
		return _track
	var n: Node = get_parent()
	while n != null:
		if n is Track:
			_track = n as Track
			break
		n = n.get_parent()
	return _track


func _place() -> void:
	if not is_inside_tree() or built:
		return
	var track := _find_track()
	if track == null or track.routes.size() <= route_index \
			or track.route_at(route_index).baked.is_empty():
		if not Engine.is_editor_hint():
			get_tree().process_frame.connect(_place, CONNECT_ONE_SHOT)
		return
	if model == null:
		push_warning("ModulePlacer %s: fara model" % name)
		return
	var route := track.route_at(route_index)
	var total := route.length()
	var d0 := _dist_at_frac(route, frac_from)
	var d1 := _dist_at_frac(route, frac_to)
	var single := frac_to <= frac_from
	var centers: Array[float] = []
	if single:
		centers.append(d0)
	else:
		var span := d1 - d0
		var max_step := maxf(module_length - seam_overlap_m, 0.1)
		var n := 1
		if span > module_length:
			n = int(ceil((span - module_length - span_tolerance_m) / max_step)) + 1
		for k in n:
			var c := d0 + module_length * 0.5 if n == 1 \
					else d0 + module_length * 0.5 + (span - module_length) * float(k) / float(n - 1)
			centers.append(c)
	var prev_fwd := Vector3.ZERO
	var prev_front := Vector3.ZERO
	var prev_side := Vector3.ZERO
	var prev_c := Vector3.ZERO
	var half := module_length * 0.5
	for k in centers.size():
		var dc := centers[k]
		var a := _point_at(route, dc - half, total)
		var b := _point_at(route, dc + half, total)
		var mid := (a + b) * 0.5
		var fwd := b - a
		var pitch_fwd := fwd
		fwd.y = 0.0
		if fwd.length_squared() < 1e-8:
			fwd = Vector3.FORWARD
		fwd = fwd.normalized()
		var side := fwd.cross(Vector3.UP).normalized()
		var yaw := atan2(-fwd.x, -fwd.z)
		var basis := Basis(Vector3.UP, yaw)
		if follow_pitch:
			var pitch := atan2(pitch_fwd.y, maxf(Vector2(pitch_fwd.x, pitch_fwd.z).length(), 0.001))
			basis = basis * Basis(Vector3.RIGHT, pitch)
		# Cota: axa drumului la centrul modulului (nu la coarda: pe o rampa
		# coarda si arcul difera cu sub 1 cm la 6-10 m).
		var base_c := _point_at(route, dc, total)
		for lat in lateral_offsets:
			var pos := Vector3(mid.x, base_c.y + y_offset, mid.z) + side * lat
			var yscale := 1.0
			if ground_fit:
				var low := 1e9
				for ox: float in [-0.5, 0.0, 0.5]:
					for oz: float in [-0.5, 0.0, 0.5]:
						var q := pos + basis * Vector3(ox * module_width, 0.0, oz * module_length)
						low = minf(low, track._terrain_mesh_y(q.x, q.z))
				var top := base_c.y + top_offset
				var h := top - (low - ground_margin)
				yscale = clampf(h / module_height, min_height_scale, max_height_scale)
				pos.y = top - module_height * yscale
				min_scale_used = minf(min_scale_used, yscale)
				max_scale_used = maxf(max_scale_used, yscale)
			_spawn(basis, pos, "%s_%d_%d" % [name, k, int(round(lat * 10.0))], yscale)
		module_count += lateral_offsets.size()
		# Statistica cusaturii: la marginea exterioara a modulului k-1 fata de
		# marginea corespunzatoare a lui k, pe cele doua parti.
		if k > 0:
			var step_gap := 0.0
			var worst_over := 0.0
			for sgn: float in [-1.0, 1.0]:
				var prev_edge := prev_front + prev_side * seam_half_width * sgn
				var this_edge := mid - fwd * half + side * seam_half_width * sgn
				# Pozitia pe directia de mers: pozitiv = gol, negativ = suprapunere.
				var g := (this_edge - prev_edge).dot((fwd + prev_fwd).normalized())
				step_gap = maxf(step_gap, g)
				worst_over = maxf(worst_over, -g)
			max_seam_gap_m = maxf(max_seam_gap_m, step_gap)
			max_seam_overlap_m = maxf(max_seam_overlap_m, worst_over)
			max_yaw_step_deg = maxf(max_yaw_step_deg,
					rad_to_deg(absf(prev_fwd.signed_angle_to(fwd, Vector3.UP))))
		prev_fwd = fwd
		prev_side = side
		prev_c = mid
		prev_front = mid + fwd * half
	built = true


func _spawn(basis: Basis, pos: Vector3, nm: String, yscale: float = 1.0) -> void:
	var holder := WorldProp.new()
	holder.name = nm
	holder.transform = Transform3D(basis, pos)
	var inst := model.instantiate() as Node3D
	inst.set_meta(WorldProp.COLLISION_META, collision_mode)
	if yscale != 1.0:
		inst.scale = Vector3(1.0, yscale, 1.0)
	for hn in hide_nodes:
		var nd := inst.find_child(hn, true, false) as Node3D
		if nd != null:
			nd.visible = false
	holder.add_child(inst)
	add_child(holder)


## Distanta pe banda la o fractie de tur (pe INDICE, interpolat).
static func _dist_at_frac(route: TrackRoute, frac: float) -> float:
	var n := route.baked.size()
	var fi := clampf(frac, 0.0, 1.0) * float(n)
	var i0 := int(floor(fi))
	var t := fi - float(i0)
	var d_a := route.dists[mini(i0, n)]
	var d_b := route.dists[mini(i0 + 1, n)]
	return lerpf(d_a, d_b, t)


## Punct pe banda la distanta `d` (bucla se inchide, deschisa se opreste).
static func _point_at(route: TrackRoute, d: float, total: float) -> Vector3:
	var n := route.baked.size()
	var dd := d
	if route.closed:
		dd = fposmod(d, total)
	else:
		dd = clampf(d, 0.0, total)
	var lo := 0
	var hi := n - 1
	while lo < hi - 1:
		var mid := (lo + hi) / 2
		if route.dists[mid] <= dd:
			lo = mid
		else:
			hi = mid
	if route.closed and dd >= route.dists[n - 1]:
		lo = n - 1
		var span_c := maxf(total - route.dists[n - 1], 0.0001)
		return route.baked[n - 1].lerp(route.baked[0], clampf((dd - route.dists[n - 1]) / span_c, 0.0, 1.0))
	var span := maxf(route.dists[hi] - route.dists[lo], 0.0001)
	return route.baked[lo].lerp(route.baked[hi], clampf((dd - route.dists[lo]) / span, 0.0, 1.0))
