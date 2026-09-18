extends Node
## Generator de decor MANUAL pentru POI C — POARTA SOARELUI SI CREASTA
## (Track15, Machu Picchu, frac 0.22-0.40, coborare 35 -> 5 m pe muchie).
##
## Ca la POI G (gen_decor_mp_g.gd) si la Serengeti: nu e sonda, e unealta care
## CALCULEAZA transformarile ce se lipesc in Track15.tscn sub
## `DecorManual/ZoneC_PoartaSoarelui`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMpC.tscn -- \
##       --out=C:/cale/zoneC.part [--survey]
##
## ------------------------------------------------------------------------
## CE CERE BARA (docs/track_briefs/img/bar_machu/bara_poi_C.png)
##
## Citit din decupaj, in ordinea in care sare in ochi:
##  1. O POARTA/CONSTRUCTIE DE PIATRA pe creasta, cu acoperis de paie langa ea
##     (Casa Paznicului) — masa de zidarie deschisa la culoare pe muchie.
##  2. CONDORUL pe o stanca alaturata, aripile desfacute, silueta neagra pe cer.
##  3. DRUMUL PE MUCHIE: fasie ingusta de pamant care serpuieste, cu NOR ALB
##     DEDESUBT DE AMBELE PARTI. Nu e drum pe deal, e drum pe creasta.
##  4. Coroane verzi dese INCLINATE PE VERSANT, sub cota drumului — se vad
##     varfurile de sub buza, nu trunchiurile.
##  5. Flancul muntelui pe fundal, in dreapta, cu ceata intre el si creasta.
##
## Bara e LOOK, nu LAYOUT: nu se redeseneaza traseul.
##
## ------------------------------------------------------------------------
## CAPCANA CENTRALA (memoria umarul-ingust-ascunde-caderea)
##
## Ochiul e la 10 m si camera priveste INAINTE. Ce face creasta sa citeasca
## drept creasta nu e adancimea finala a rapei, ci UNGHIUL din primii metri de
## la piatra. Un umar plat de 3 m urmat de o cadere de 40 m citeste ca pajiste.
##
## Terenul de aici E deja taiat: `custom_ravines` 0 (0.0734-0.3556, latime 200,
## planseu -40, cornisa) pe partea +1 si `custom_ravines` 1 (0.2215-0.3556,
## latime 70, side -1) pe partea -1. Deci rapa exista pe AMBELE parti pe
## 0.2215-0.3556. Survey-ul de mai jos MASOARA unghiul, nu il presupune.
##
## ------------------------------------------------------------------------
## SURVEY (se completeaza dupa prima rulare cu --survey)
##
## <<SURVEY>>

const TRACK := "res://scenes/tracks/Track15.tscn"
const ZONE := "DecorManual/ZoneC_PoartaSoarelui"

const F_IN := 0.220
const F_OUT := 0.400

## id-urile ext_resource din Track15.tscn (fundatia).
const RES := {
	"inti_punku": "s_inti_punku",
	"condor": "s_condor",
	"guardhouse": "s_guardhouse",
	"inca_house_b": "s_inca_house_b",
	"inca_wall_a": "s_inca_wall_a",
	"inca_wall_b": "s_inca_wall_b",
	"inca_wall_c": "s_inca_wall_c",
	"moss_boulder_a": "s_moss_boulder_a",
	"moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c",
	"polylepis_a": "s_polylepis_a",
	"polylepis_b": "s_polylepis_b",
	"tree_fern": "s_tree_fern",
	"bromeliad": "s_bromeliad",
	"orchid_cluster": "s_orchid_cluster",
	"rope_rail": "s_rope_rail",
	"trail_marker": "s_trail_marker",
}

## Inaltimea AABB masurata (docs/asset_briefs/machu_picchu_masuratori.md §1).
const HEIGHT := {
	"inti_punku": 5.000, "condor": 1.156, "guardhouse": 7.878,
	"inca_house_b": 2.833,
	"inca_wall_a": 2.487, "inca_wall_b": 2.487, "inca_wall_c": 2.432,
	"moss_boulder_a": 0.741, "moss_boulder_b": 1.957, "moss_boulder_c": 3.069,
	"polylepis_a": 4.190, "polylepis_b": 6.798, "tree_fern": 3.306,
	"bromeliad": 0.377, "orchid_cluster": 0.390,
	"rope_rail": 1.045, "trail_marker": 1.200,
}

## Raza de DEGAJARE la sol (m) la scara 1 (masuratori §1, coloana "raza baza"
## pentru trunk, jumatatea laturii mari a AABB pentru hull).
const BASE_R := {
	"inti_punku": 12.16, "condor": 0.73, "guardhouse": 4.01,
	"inca_house_b": 3.00,
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"moss_boulder_a": 0.43, "moss_boulder_b": 1.24, "moss_boulder_c": 2.11,
	"polylepis_a": 0.61, "polylepis_b": 1.10, "tree_fern": 0.54,
	"bromeliad": 0.46, "orchid_cluster": 0.17,
	"rope_rail": 2.07, "trail_marker": 0.29,
}

## Raza COROANEI (m) la scara 1 — testul de silueta peste banda.
const CROWN_R := {
	"inti_punku": 12.60, "condor": 0.68, "guardhouse": 4.74,
	"inca_house_b": 3.65,
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"moss_boulder_a": 0.43, "moss_boulder_b": 1.24, "moss_boulder_c": 2.11,
	"polylepis_a": 1.39, "polylepis_b": 2.27, "tree_fern": 2.07,
	"bromeliad": 0.46, "orchid_cluster": 0.17,
	"rope_rail": 2.07, "trail_marker": 0.29,
}

const TRI := {
	"inti_punku": 1092, "condor": 986, "guardhouse": 504, "inca_house_b": 496,
	"inca_wall_a": 208, "inca_wall_b": 296, "inca_wall_c": 152,
	"moss_boulder_a": 200, "moss_boulder_b": 242, "moss_boulder_c": 238,
	"polylepis_a": 598, "polylepis_b": 1098, "tree_fern": 768,
	"bromeliad": 248, "orchid_cluster": 410,
	"rope_rail": 92, "trail_marker": 76,
}

const EDGE_KEEP := 0.8
const WALL_HALF_THICK := 0.43

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _warn := 0
var _skipped := 0
var _tri := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false
var _total_len := 1.0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--survey":
			_survey_only = true
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	var nd: int = _track.baked.size()
	if _track._dists.size() > nd:
		_total_len = float(_track._dists[nd])
	print("; lungime traseu %.1f m, %d puncte" % [_total_len, nd])
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	_rng.seed = 220400
	_survey()
	if not _survey_only:
		_gate()
		_condor_rock()
		_guardhouse()
		_ridge_punctuation()
		_downhill_canopy()
		_uphill_side()
		_markers()
		_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ masuratori

func _survey() -> void:
	var sun := _find_sun(_track)
	if sun != null:
		var dir: Vector3 = -sun.global_transform.basis.z
		print("; soare: rot %s, lumina spre (%.2f, %.2f, %.2f), elevatie %.1f deg" % [
			str(sun.rotation_degrees), dir.x, dir.y, dir.z,
			rad_to_deg(asin(-dir.y))])
	var n := _track.baked.size()
	print("; UNGHIUL e ce conteaza: pentru fiecare parte se da caderea la 3, 8, 15,")
	print("; 25, 40 m si UNGHIUL mediu pe primii 3 m de la muchie (grade sub orizontala).")
	print("; frac    y_drum  half  |  -3   -8  -15  -25  -40  ungh- |  +3   +8  +15  +25  +40  ungh+   curb")
	var f := F_IN - 0.01
	while f <= F_OUT + 0.01:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		var angs: Array[float] = []
		for sg: float in [-1.0, 1.0]:
			var y0 := _sol_real((p + s * sg * half).x, (p + s * sg * half).z)
			for off: float in [3.0, 8.0, 15.0, 25.0, 40.0]:
				var q := p + s * sg * (half + off)
				cols.append("%+6.1f" % (_sol_real(q.x, q.z) - p.y))
			var q3 := p + s * sg * (half + 3.0)
			var drop := y0 - _sol_real(q3.x, q3.z)
			angs.append(rad_to_deg(atan2(maxf(drop, 0.0), 3.0)))
		print("; %.4f  %6.1f  %4.1f | %s %5.1f | %s %5.1f  %+8.4f" % [
			f, p.y, half,
			" ".join(cols.slice(0, 5)), angs[0],
			" ".join(cols.slice(5, 10)), angs[1], _curv(i)])
		f += 0.005


func _curv(i: int) -> float:
	var n := _track.baked.size()
	var a: Vector3 = _track.baked[(i - 3 + n) % n]
	var b: Vector3 = _track.baked[i]
	var c: Vector3 = _track.baked[(i + 3) % n]
	var t0 := Vector3(b.x - a.x, 0.0, b.z - a.z)
	var t1 := Vector3(c.x - b.x, 0.0, c.z - b.z)
	var l := t0.length() + t1.length()
	if l < 0.01:
		return 0.0
	var s := _track._side_at(i)
	var dth := t1.normalized().angle_to(t0.normalized())
	var sgn := signf(t1.normalized().dot(s))
	return sgn * absf(dth) / (l * 0.5)


func _find_sun(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node as DirectionalLight3D
	for c in node.get_children():
		var r := _find_sun(c)
		if r != null:
			return r
	return null


# ------------------------------------------------------------------ compozitia
# (se completeaza dupa survey)

func _gate() -> void:
	pass


func _condor_rock() -> void:
	pass


func _guardhouse() -> void:
	pass


func _ridge_punctuation() -> void:
	pass


func _downhill_canopy() -> void:
	pass


func _uphill_side() -> void:
	pass


func _markers() -> void:
	pass


# ------------------------------------------------------------------ asezarea

func _step(meters: float) -> float:
	return meters / _total_len


func _scale_for(model: String, meters: float) -> float:
	var h: float = HEIGHT.get(model, 1.0)
	return meters / h if h > 0.001 else 1.0


func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "hull",
		dy: float = 0.0, pitch: float = 0.0) -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var r: float = BASE_R.get(model, 0.6) * scl
	var d := half + gap + r
	var q := p + s * d
	var g := _sol_real(q.x, q.z) + dy
	if mode != "none" and d - r < half + EDGE_KEEP:
		_warn += 1
		print("; ATENTIE %s la frac %.4f: corpul la %.2f m de ax, muchia la %.2f" % [
			model, frac, d - r, half])
	var cr: float = CROWN_R.get(model, 0.6) * scl
	if d - cr < half - 1.0:
		_warn += 1
		print("; ATENTIE silueta %s la frac %.4f ajunge la %.2f m de ax (banda %.2f)" % [
			model, frac, d - cr, half])
	if mode != "none" and _on_any_road(q, i, r):
		_skipped += 1
		return
	var smooth := _sampler.ground_y(q.x, q.z)
	var sink := smooth - (g - dy)
	var piece_h: float = float(HEIGHT.get(model, 1.0)) * scl
	var zvelt: bool = model.begins_with("polylepis") or model == "tree_fern"
	var max_sink: float = 0.8 if zvelt else maxf(0.5 * piece_h, 1.0)
	if sink > max_sink:
		_skipped += 1
		return
	_raw(model, base, Vector3(q.x, g, q.z), yaw, scl, mode, pitch)


const NEAR_WINDOW_FRAC := 0.012
const OTHER_ROAD_KEEP := 1.2

func _on_any_road(p: Vector3, home_i: int, body_r: float) -> bool:
	var n := _track.baked.size()
	var skip := int(round(float(n) * NEAR_WINDOW_FRAC))
	for i in n:
		var di := absi(i - home_i)
		di = mini(di, n - di)
		if di <= skip:
			continue
		var b: Vector3 = _track.baked[i]
		var dx := b.x - p.x
		var dz := b.z - p.z
		var clear: float = _track.width_at_index(i) + OTHER_ROAD_KEEP + body_r
		if dx * dx + dz * dz < clear * clear:
			return true
	return false


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String, pitch: float = 0.0) -> void:
	_n += 1
	_tri += int(TRI.get(model, 0))
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	var b := Basis.from_euler(Vector3(pitch, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _write() -> void:
	print("; asezate %d piese, %d refuzate, %d avertismente, ~%d triunghiuri" % [
		_n, _skipped, _warn, _tri])
	if _out_path.is_empty():
		for line in _out:
			print(line)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	if fa == null:
		push_error("nu pot scrie %s" % _out_path)
		return
	for line in _out:
		fa.store_line(line)
	fa.close()
	print("; scris %s" % _out_path)


## Cota SOLULUI din coliziunea reala (TerrainBody), nu din campul neted
## (memoria terrain-mesh-y-extrapoleaza).
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1200.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		q.collide_with_bodies = true
		q.exclude = []
		var hit: Dictionary = space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	return _sampler.ground_y(x, z)
