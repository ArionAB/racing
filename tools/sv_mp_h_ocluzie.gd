extends Node
## Cat din fata golului se VEDE din camera de joc pe POI H.
##
## Nu masoara ca piesele exista (lectia efecte-invizibile-nu-se-numara), ci
## plimba raza din ochiul soferului catre fiecare cota de pe fata si spune
## unde o opreste umarul propriu al drumului.
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track
var _sus := 0.0
var _rid: RID = RID()
var _blocker := ""

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus = hi + 150.0
	var n := _track.baked.size()
	print("; OCLUZIE pe partea golului. Ochi la +2,6 m peste sosea, 8 m in spate.")
	print("; frac | lateral -> cota sol | unghi sub orizontala | vizibil?")
	for f: float in [0.9300, 0.9400, 0.9500, 0.9550, 0.9600]:
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var s := _track._side_at(i) * _gap_side(i)
		var tang := (_track.baked[(i + 3) % n] - _track.baked[(i - 3 + n) % n]).normalized()
		# ochiul camerei de urmarire
		var eye := p - tang * 8.0 + Vector3(0.0, 2.6, 0.0)
		var linii: Array[String] = []
		for lat: float in [6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 20.0, 26.0]:
			var q := p + s * lat
			var gy := _sol(q.x, q.z)
			var tgt := Vector3(q.x, gy, q.z)
			var vaz := _liber(eye, tgt)
			var d := tgt - eye
			var ang := rad_to_deg(atan2(-d.y, Vector2(d.x, d.z).length()))
			linii.append("%4.0fm:%+6.1f/%4.1f/%s" % [lat, gy - p.y, ang, "DA" if vaz else _blocker.substr(0,12)])
		print("; %.4f  %s" % [f, "  ".join(linii)])
		# Cat de sus trebuie sa fie ochiul ca sa vada piciorul fetei (16 m)?
		var q16 := p + s * 16.0
		var t16 := Vector3(q16.x, _sol(q16.x, q16.z), q16.z)
		var h := 2.6
		while h < 30.0:
			var e2 := p - tang * 8.0 + Vector3(0.0, h, 0.0)
			if _liber(e2, t16):
				break
			h += 0.5
		# Si cat de departe lateral trebuie mutat ochiul, la inaltimea reala?
		var lat2 := 0.0
		while lat2 < 14.0:
			var e3 := p - tang * 8.0 + s * lat2 + Vector3(0.0, 2.6, 0.0)
			if _liber(e3, t16):
				break
			lat2 += 0.5
		# FEREASTRA VIZIBILA: la fiecare lateral, care e cea mai JOASA cota
		# care inca se vede din ochiul real. Asta e banda in care decorul
		# poate schimba captura.
		var w: Array[String] = []
		for lat3: float in [7.0, 9.0, 11.0, 13.0, 16.0, 20.0]:
			var q3 := p + s * lat3
			var gy3 := _sol(q3.x, q3.z)
			var y := p.y + 3.0
			var jos := NAN
			while y > gy3 - 0.5:
				if _liber(eye, Vector3(q3.x, y, q3.z)):
					jos = y - p.y
				else:
					break
				y -= 0.25
			w.append("%4.0fm:%s" % [lat3, ("%+.1f" % jos) if not is_nan(jos) else "  --"])
		print(";        FEREASTRA (cea mai joasa cota vizibila, fata de sosea): %s" % "  ".join(w))
		print(";        ca sa vezi piciorul (16 m, %.1f m sub sosea): ochiul la +%.1f m inaltime SAU %.1f m lateral" % [t16.y - p.y, h, lat2])
	get_tree().quit(0)

func _liber(a: Vector3, b: Vector3) -> bool:
	var dir := (b - a).normalized()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(a, b - dir * 0.35)
	q.collide_with_areas = false
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return true
	var c = hit.get("collider")
	_blocker = str(c.name) if c != null else "?"
	return false

func _gap_side(i: int) -> float:
	var p: Vector3 = _track.baked[i]
	var s := _track._side_at(i)
	var dl := 0.0
	var dr := 0.0
	for off: float in [15.0, 25.0]:
		dl += _sol((p + s * -off).x, (p + s * -off).z) - p.y
		dr += _sol((p + s * off).x, (p + s * off).z) - p.y
	return -1.0 if dl < dr else 1.0

func _sol(x: float, z: float) -> float:
	if _rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, _sus, z), Vector3(x, _sus - 1200.0, z))
	q.collide_with_areas = false
	var hit := space.intersect_ray(q)
	var guard := 0
	while not hit.is_empty() and hit["rid"] != _rid and guard < 24:
		q.exclude = q.exclude + [hit["rid"]]
		hit = space.intersect_ray(q)
		guard += 1
	if not hit.is_empty() and hit["rid"] == _rid:
		return float(hit["position"].y)
	return 0.0
