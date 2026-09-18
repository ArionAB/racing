extends Node
## Generator de decor MANUAL pentru POI B — DRUMUL INCAS (Track15,
## Machu Picchu, frac 0.04-0.20). Nu e sonda: calculeaza transformarile care
## se lipesc in Track15.tscn sub `DecorManual/ZoneB_DrumulIncas`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMpB.tscn -- \
##       --out=C:/cale/zoneB.part [--survey]
##
## Cu `--survey` scrie doar profilul terenului masurat si nu genereaza nimic.
##
## CE SE VEDE IN BARA (bara_poi_B.png, deschisa inainte de asezare):
## drum de pamant tan taiat intr-o CREASTA DE STANCA — fete cenusii plane,
## fatetate, care cad de AMANDOUA partile imediat de langa asfalt; pe fete
## stau smocuri de copaci verde-inchis, agatati; o gura de tunel cu arc de
## piatra si un parapet de blocuri deasupra; trepte de piatra langa portal;
## nori albi in vale dedesubt. Materia dominanta e PIATRA, nu iarba: drumul e
## o panglica pe o coama de roca, nu o poteca pe pajiste.
##
## CIFRELE DE SURVEY se scriu aici dupa prima rulare cu --survey.

const TRACK := "res://scenes/tracks/Track15.tscn"
const ZONE := "DecorManual/ZoneB_DrumulIncas"

const F_IN := 0.040
const F_OUT := 0.210

const RES := {
	"moss_boulder_a": "s_moss_boulder_a",
	"moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c",
	"bromeliad": "s_bromeliad",
	"tree_fern": "s_tree_fern",
	"orchid_cluster": "s_orchid_cluster",
	"inca_stair_a": "s_inca_stair_a",
	"inca_stair_b": "s_inca_stair_b",
	"trail_marker": "s_trail_marker",
	"inca_wall_a": "s_inca_wall_a",
	"inca_wall_b": "s_inca_wall_b",
	"inca_wall_c": "s_inca_wall_c",
	"polylepis_a": "s_polylepis_a",
	"polylepis_b": "s_polylepis_b",
}

## Inaltimea AABB masurata (docs/asset_briefs/machu_picchu_masuratori.md §1).
const HEIGHT := {
	"moss_boulder_a": 0.741, "moss_boulder_b": 1.957, "moss_boulder_c": 3.069,
	"bromeliad": 0.377, "tree_fern": 3.306, "orchid_cluster": 0.390,
	"inca_stair_a": 2.500, "inca_stair_b": 5.000,
	"trail_marker": 1.200,
	"inca_wall_a": 2.487, "inca_wall_b": 2.487, "inca_wall_c": 2.432,
	"polylepis_a": 4.190, "polylepis_b": 6.798,
}
## Raza de degajare la baza (m) — coloana "raza baza" din inventar.
const BASE_R := {
	"moss_boulder_a": 0.37, "moss_boulder_b": 0.94, "moss_boulder_c": 1.73,
	"bromeliad": 0.46, "tree_fern": 0.30, "orchid_cluster": 0.17,
	"inca_stair_a": 3.16, "inca_stair_b": 6.08,
	"trail_marker": 0.29,
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"polylepis_a": 0.61, "polylepis_b": 1.10,
}
## SEMI-GROSIMEA laterala (m) pentru testul de banda: amprenta reala, nu raza
## pe diagonala (lectia POI D).
const SIDE_R := {
	"inca_wall_a": 0.42, "inca_wall_b": 0.43, "inca_wall_c": 0.43,
	"inca_stair_a": 1.30, "inca_stair_b": 1.30,
}
const TRI := {
	"moss_boulder_a": 200, "moss_boulder_b": 242, "moss_boulder_c": 238,
	"bromeliad": 248, "tree_fern": 768, "orchid_cluster": 410,
	"inca_stair_a": 422, "inca_stair_b": 798,
	"trail_marker": 76,
	"inca_wall_a": 208, "inca_wall_b": 296, "inca_wall_c": 152,
	"polylepis_a": 598, "polylepis_b": 1098,
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _warn := 0
var _lane_reject := 0
var _tri := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false
var _total_len := 1.0
var _shadow := Vector3.ZERO


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
	print("; lungime traseu %.1f m, %d puncte, %.3f m intre puncte" % [
		_total_len, nd, _total_len / float(nd)])
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 140.0
	_rng.seed = 40205
	_survey()
	if not _survey_only:
		_build()
		_write()
	get_tree().quit(0)


func _find_sun(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node as DirectionalLight3D
	for c in node.get_children():
		var r := _find_sun(c)
		if r != null:
			return r
	return null


## Profilul real al terenului pe intervalul meu. Cifrele din antet vin de aici.
func _survey() -> void:
	var sun := _find_sun(_track)
	if sun != null:
		var dir: Vector3 = -sun.global_transform.basis.z
		_shadow = Vector3(dir.x, 0.0, dir.z).normalized()
		print("; soare: rot %s, lumina spre (%.2f,%.2f,%.2f), umbra XZ (%.3f,%.3f), elev %.1f deg" % [
			str(sun.rotation_degrees), dir.x, dir.y, dir.z,
			_shadow.x, _shadow.z, rad_to_deg(asin(-dir.y))])
	var n := _track.baked.size()
	print("; --- PROFIL LATERAL (cote fata de drum) ---")
	print("; frac      ax(x,z)          y_drum  half   sol la -40 -25 -15 -8 -4 -2 | +2 +4 +8 +15 +25 +40")
	var f := F_IN - 0.005
	while f <= F_OUT + 0.006:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-40.0, -25.0, -15.0, -8.0, -4.0, -2.0,
				2.0, 4.0, 8.0, 15.0, 25.0, 40.0]:
			var q := p + s * (half + absf(off)) * signf(off)
			cols.append("%+6.1f" % (_sol_real(q.x, q.z) - p.y))
		print("; %.3f  (%7.1f,%7.1f)  %6.1f  %4.1f  %s" % [
			f, p.x, p.z, p.y, half, " ".join(cols)])
		f += 0.005
	print("; --- UNGHIUL DIN OCHIUL CAMEREI (ochi la 10 m peste drum) ---")
	print("; frac   |  dr: unghi_sub_orizontala la 4/8/15 m  |  st: idem")
	f = F_IN
	while f <= F_OUT + 0.001:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var line := "; %.3f " % f
		for sgn: float in [1.0, -1.0]:
			line += " |"
			for off: float in [4.0, 8.0, 15.0]:
				var q := p + s * sgn * (half + off)
				var dy := _sol_real(q.x, q.z) - p.y
				line += " %5.1f" % rad_to_deg(atan2(-dy, off))
		print(line)
		f += 0.01
	print("; --- PANTA LONGITUDINALA (coama de la 0.186) ---")
	f = 0.16
	while f <= 0.215:
		var i := int(f * float(n)) % n
		var j := int((f + 0.004) * float(n)) % n
		var p := _track.baked[i]
		var q := _track.baked[j]
		var d := Vector2(q.x - p.x, q.z - p.z).length()
		print("; %.3f  y %7.2f  panta %+6.2f %%" % [
			f, p.y, 100.0 * (q.y - p.y) / maxf(d, 0.01)])
		f += 0.004


func _step(meters: float) -> float:
	return meters / _total_len


func _build() -> void:
	pass


func _scale_for(model: String, meters: float) -> float:
	var h: float = HEIGHT.get(model, 1.0)
	return meters / h if h > 0.001 else 1.0


const LANE_MARGIN := 2.2


func _lane_free(pos: Vector3, r: float, h: float) -> bool:
	var n := _track.baked.size()
	for i in n:
		var p: Vector3 = _track.baked[i]
		var dy := pos.y - p.y
		if dy + h < 0.0:
			continue
		var dx := pos.x - p.x
		var dz := pos.z - p.z
		var need: float = _track.width_at_index(i) + LANE_MARGIN + r
		if dx * dx + dz * dz < need * need:
			return false
	return true


## Pozitia + latura + semi-latimea INTERPOLATE intre punctele coapte — pasul
## sub 1,79 m altfel da grupuri suprapuse (nota 8bis a lui POI D).
func _at(frac: float) -> Dictionary:
	var n := _track.baked.size()
	var t := fposmod(frac, 1.0) * float(n)
	var i := int(t) % n
	var j := (i + 1) % n
	var u := t - float(int(t))
	var p: Vector3 = _track.baked[i].lerp(_track.baked[j], u)
	var s: Vector3 = _track._side_at(i).lerp(_track._side_at(j), u).normalized()
	var half: float = lerpf(_track.width_at_index(i), _track.width_at_index(j), u)
	return {"p": p, "s": s, "half": half}


## Aseaza la `frac`, pe partea `side_sign`, la `gap` metri de MUCHIA drumului
## pana la marginea piesei. Cota din raycast pe TerrainBody-ul real.
func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "",
		dy: float = 0.0) -> void:
	var a := _at(frac)
	var p: Vector3 = a["p"]
	var s: Vector3 = (a["s"] as Vector3) * side_sign
	var half: float = a["half"]
	var r: float = BASE_R.get(model, 0.6) * scl
	var d := half + gap + r
	var q := p + s * d
	var g := _sol_real(q.x, q.z)
	if d - r < half + 0.3:
		_warn += 1
		print("; ATENTIE %s la frac %.4f: marginea la %.2f m de ax, banda %.2f" % [
			model, frac, d - r, half])
	if mode != "none":
		var hh: float = HEIGHT.get(model, 1.0) * scl
		var lr: float = float(SIDE_R.get(model, BASE_R.get(model, 0.6))) * scl
		if not _lane_free(Vector3(q.x, g + dy, q.z), lr, hh):
			_lane_reject += 1
			return
	_raw(model, base, Vector3(q.x, g + dy, q.z), yaw, scl, mode)


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	_raw_h(model, base, pos, yaw, scl, scl, mode)


func _raw_h(model: String, base: String, pos: Vector3, yaw: float,
		scl_xz: float, scl_y: float, mode: String) -> void:
	_n += 1
	_tri += int(TRI.get(model, 0))
	var c := cos(yaw) * scl_xz
	var s := sin(yaw) * scl_xz
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, s, scl_y, -s, c, pos.x, pos.y, pos.z])
	if mode != "":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _write() -> void:
	print("; asezate %d piese, %d refuzate de garda de banda, %d avertismente, ~%d triunghiuri" % [
		_n, _lane_reject, _warn, _tri])
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
	print("; ATENTIE fara sol la (%.1f, %.1f): se cade pe camp" % [x, z])
	return _sampler.ground_y(x, z)
