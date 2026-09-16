extends Node
## Sonda de PROFIL TRANSVERSAL peste albia POI-ului F (Machu Picchu).
##
## Intrebarea la care raspunde, si care a decis runda 3: exista un CANAL in
## teren, sau apa sta pe un raft plat? Criticul orb a spus „raul nu e sapat in
## teren, e pictat peste el"; asta masoara premisa.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeMpfProfil.tscn
##
## Taie perpendicular pe firul albiei la cativa `t` si tipareste cota reala
## (raycast pe TerrainBody, nu campul neted) de la -40 la +40 m lateral.

const TRACK := "res://scenes/tracks/Track15.tscn"
const CH_A := Vector2(-250.0, -188.0)
const CH_B := Vector2(-206.0, -186.0)

var _track: Track
var _terrain_rid: RID = RID()
var _sus_y := 0.0


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	var dir := (CH_B - CH_A).normalized()
	var per := Vector2(-dir.y, dir.x)
	var chlen := CH_A.distance_to(CH_B)
	print("; fir (%.0f,%.0f) -> (%.0f,%.0f), lungime %.1f m" % [
		CH_A.x, CH_A.y, CH_B.x, CH_B.y, chlen])
	print("; PROFIL TRANSVERSAL (cota reala; o = metri pe perpendiculara)")
	var offs: Array[float] = []
	var o := -40.0
	while o <= 40.0:
		offs.append(o)
		o += 4.0
	var head: Array[String] = []
	for oo in offs:
		head.append("%+6.0f" % oo)
	print(";   t     %s" % " ".join(head))
	for t: float in [-6.0, 0.0, 8.0, 16.0, 24.0, 32.0, 40.0, 46.0, 52.0]:
		var row: Array[String] = []
		for oo in offs:
			var q := CH_A + dir * t + per * oo
			row.append("%+6.1f" % _sol(q.x, q.y))
		print("; %+5.1f  %s" % [t, " ".join(row)])
	# Cat de adanc e canalul fata de umerii lui? Asta e cifra pe care o cere
	# criticul: „coboara luciul cu 2-3 m fata de drum".
	print("; ADANCIME fata de umeri (min pe |o|<=6 vs. media pe |o| in 14..26)")
	for t: float in [0.0, 8.0, 16.0, 24.0, 32.0, 40.0, 46.0]:
		var fund := INF
		var oa := -6.0
		while oa <= 6.0:
			var q := CH_A + dir * t + per * oa
			fund = minf(fund, _sol(q.x, q.y))
			oa += 1.0
		var um := 0.0
		var nu := 0
		for sgn: float in [-1.0, 1.0]:
			var ob := 14.0
			while ob <= 26.0:
				var q := CH_A + dir * t + per * (ob * sgn)
				um += _sol(q.x, q.y)
				nu += 1
				ob += 2.0
		um /= float(nu)
		print("; t=%+5.1f  fund %+6.2f  umeri %+6.2f  adancime %+5.2f m" % [
			t, fund, um, um - fund])

	# Cat de departe e drumul de fir? Hollow-ul nu are voie sa ajunga sub el.
	print("; DISTANTA PANA LA CAROSABIL de-a lungul firului")
	for t in [-8.0, -4.0, 0.0, 6.0, 12.0, 18.0, 24.0, 30.0, 36.0, 42.0, 48.0, 54.0]:
		var q := CH_A + dir * t
		var lo := INF
		var loy := 0.0
		for j in _track.baked.size():
			var bp := _track.baked[j]
			var d := Vector2(bp.x - q.x, bp.z - q.y).length() - _track.width_at_index(j)
			if d < lo:
				lo = d
				loy = bp.y
		print("; t=%+5.1f  (%7.1f,%7.1f)  drum la %6.1f m, cota drum %+6.1f, sol %+6.1f" % [
			t, q.x, q.y, lo, loy, _sol(q.x, q.y)])
	get_tree().quit(0)


func _sol(x: float, z: float) -> float:
	if _terrain_rid == RID():
		var tb := _track.find_child("TerrainBody", true, false)
		if tb != null and tb is CollisionObject3D:
			_terrain_rid = (tb as CollisionObject3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var p := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 600.0, z))
	p.collide_with_areas = false
	var hit := space.intersect_ray(p)
	if hit.is_empty():
		return -999.0
	return float((hit["position"] as Vector3).y)
