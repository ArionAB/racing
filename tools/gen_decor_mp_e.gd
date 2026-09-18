extends Node
## Generator de decor MANUAL pentru POI E — PODUL DE FRANGHIE (Track15,
## Machu Picchu, frac 0.56-0.64). Nu e sonda: calculeaza transformarile care
## se lipesc in Track15.tscn sub `DecorManual/ZoneE_Pod`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMpE.tscn -- \
##       --out=C:/cale/zoneE.part [--survey]
##
## Cu `--survey` scrie doar profilul terenului masurat si nu genereaza nimic.
##
## CE SE VEDE IN BARA (bara_poi_E.png, deschisa inainte de asezare):
## scanduri pe cabluri intre DOUA TURNURI de piatra gri; autobuzul galben pe
## tablier; sub el DEFILEUL — doi pereti de STANCA PALIDA aproape verticali,
## cu vegetatie inchisa doar pe umeri si pe coama; in fund, jos, un fir de
## APA ALBA cu spuma printre pietre; departe, munti albastri in ceata.
## Materia: piatra gri deschisa + verde inchis dens pe coame + alb in gorja.
##
## CAPCANA CARE M-A ADUS AICI: POI-ul E **nu construieste podul**. Tablierul,
## cablurile si cele patru turnuri sunt facute IN COD
## (`rope_bridge_hazard.gd:_build_visual` / `_build_towers`), hazardul e cablat
## in Track15.tscn:93 cu `deck_width = 11.0` si capetele la ±17.12 m.
## Eu construiesc CE E IN JURUL lui.

const TRACK := "res://scenes/tracks/Track15.tscn"
const ZONE := "DecorManual/ZoneE_Pod"

const F_IN := 0.545
const F_OUT := 0.655

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
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
	for i in 4:
		await get_tree().process_frame
	_sampler = _track._sampler
	var nd: int = _track.baked.size()
	if _track._dists.size() > nd:
		_total_len = float(_track._dists[nd])
	print("; lungime traseu %.1f m, %d puncte" % [_total_len, nd])
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 200.0
	_rng.seed = 560064
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
		print("; soare: rot %s, lumina merge spre (%.2f, %.2f, %.2f), umbra pe XZ -> (%.3f, %.3f), elevatie %.1f deg" % [
			str(sun.rotation_degrees), dir.x, dir.y, dir.z,
			_shadow.x, _shadow.z, rad_to_deg(asin(-dir.y))])
	# Unde e podul, in fractii, si ce cota are solul REAL sub el.
	var pod := _track.find_child("PodFranghie", true, false) as Node3D
	if pod != null:
		var ne: Vector3 = pod.global_transform * (pod.get("near_end") as Vector3)
		var fe: Vector3 = pod.global_transform * (pod.get("far_end") as Vector3)
		var mid := (ne + fe) * 0.5
		print("; POD: near %s  far %s  mid %s  latime %.1f" % [
			str(ne.round()), str(fe.round()), str(mid.round()),
			float(pod.get("deck_width"))])
		for nm: String in ["near", "mid", "far"]:
			var w: Vector3 = ne if nm == "near" else (fe if nm == "far" else mid)
			print(";   %-5s frac %.4f  y_tablier %+.2f  SOL_REAL %+.2f  => GOL %.2f m" % [
				nm, _frac_of(w.x, w.z), w.y, _sol_real(w.x, w.z),
				w.y - _sol_real(w.x, w.z)])
	var n := _track.baked.size()
	print("; frac      ax(x,z)          y_drum  half  side(x,z)      sol la -60 -40 -25 -15 -8 -3 | +3 +8 +15 +25 +40 +60")
	var f := F_IN
	while f <= F_OUT + 0.001:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-60.0, -40.0, -25.0, -15.0, -8.0, -3.0,
				3.0, 8.0, 15.0, 25.0, 40.0, 60.0]:
			var q := p + s * off
			cols.append("%+6.1f" % (_sol_real(q.x, q.z) - p.y))
		print("; %.3f  (%7.1f,%7.1f)  %6.1f  %4.1f  (%+.2f,%+.2f)  %s" % [
			f, p.x, p.z, p.y, half, s.x, s.z, " ".join(cols)])
		f += 0.005
	# UNGHIUL DIN OCHIUL CAMEREI, nu panta pe harta (lectia valului 2): cat de
	# jos trebuie sa privesti de la 10 m peste ax ca sa vezi solul la N metri
	# lateral. Sub ~12 grade nu se citeste cadere, oricat de adanca ar fi.
	print("; unghi de coborare din ochiul soferului (y_ax + 10 m) spre sol lateral:")
	f = F_IN
	while f <= F_OUT + 0.001:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var eye := p + Vector3(0.0, 10.0, 0.0)
		var line := "; %.3f " % f
		for sgn: float in [-1.0, 1.0]:
			var best := 0.0
			for off: float in [4.0, 6.0, 8.0, 12.0, 18.0, 25.0, 35.0, 50.0]:
				var q := p + s * (sgn * off)
				var gy := _sol_real(q.x, q.z)
				var ang := rad_to_deg(atan2(eye.y - gy, off))
				best = maxf(best, ang)
			line += " %s max %5.1f deg " % ["st" if sgn < 0.0 else "dr", best]
		print(line)
		f += 0.01


func _frac_of(x: float, z: float) -> float:
	var n := _track.baked.size()
	var best := 0
	var bd := 1e9
	for j in n:
		var d: float = Vector2(_track.baked[j].x - x, _track.baked[j].z - z).length_squared()
		if d < bd:
			bd = d
			best = j
	return float(best) / float(n)


func _step(meters: float) -> float:
	return meters / _total_len


func _build() -> void:
	pass


func _write() -> void:
	print("; asezate %d piese, ~%d triunghiuri" % [_n, _tri])
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


## Cota SOLULUI din coliziunea reala a TERENULUI, nu din campul neted
## (memoria terrain-mesh-y-extrapoleaza) si nu de pe PLACILE PODULUI.
##
## CAPCANA LUI E, verificata de lead inainte sa pornesc: o raza verticala sub
## tablier loveste `Plate3`/`Plate7` (AnimatableBody3D ale hazardului) si
## raporteaza „gol 0". Filtrul e pe RID-ul lui TerrainBody: se continua sub
## orice alt corp pana se atinge terenul.
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1400.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		q.collide_with_bodies = true
		q.exclude = []
		var hit: Dictionary = space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 48:
			q.exclude = q.exclude + [hit["rid"]]
			hit = space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	print("; ATENTIE fara sol la (%.1f, %.1f): se cade pe camp" % [x, z])
	return _sampler.ground_y(x, z)
