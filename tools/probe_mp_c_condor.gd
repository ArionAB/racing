extends SceneTree
## Profilul fin al umarului in jurul Portii Soarelui, ca sa se afle UNDE mai e
## teren solid pentru stanca condorului.
##
## Motivul: `gen_decor_mp_c.gd` a incercat doua pozitii si amandoua au iesit in
## gol (-35 m intai, apoi refuz). Ghicitul s-a terminat; se masoara.
##
##   godot --headless --fixed-fps 60 --path . --script res://tools/probe_mp_c_condor.gd

const TRACK := "res://scenes/tracks/Track15.tscn"

var _t: Node = null
var _frames := 0
var _rid: RID = RID()
var _sus := 0.0


func _process(_d: float) -> bool:
	if _t == null:
		_t = (load(TRACK) as PackedScene).instantiate()
		root.add_child(_t)
		return false
	_frames += 1
	if _frames < 3:
		return false
	_report()
	quit(0)
	return true


func _report() -> void:
	var tr = _t
	var hi := -INF
	for bp in tr.baked:
		hi = maxf(hi, bp.y)
	_sus = hi + 150.0
	var n: int = tr.baked.size()
	print("frac    y_drum  half |  cota SOLULUI la offset fata de MUCHIE (m):")
	print("                     | -2.0  -1.0  -0.5   0.0  +0.5  +1.0  +1.5  +2.0  +3.0   (partea -1 / partea +1)")
	for f: float in [0.2200, 0.2250, 0.2300, 0.2320, 0.2350, 0.2400, 0.3300]:
		var i := int(f * float(n)) % n
		var p: Vector3 = tr.baked[i]
		var s: Vector3 = tr._side_at(i)
		var half: float = tr.width_at_index(i)
		for sg: float in [-1.0, 1.0]:
			var cols: Array[String] = []
			for off: float in [-2.0, -1.0, -0.5, 0.0, 0.5, 1.0, 1.5, 2.0, 3.0]:
				var q := p + s * sg * (half + off)
				cols.append("%+6.2f" % (_sol(q.x, q.z) - p.y))
			print("%.4f  %6.1f  %4.1f | %s   side %+.0f" % [
				f, p.y, half, " ".join(cols), sg])


func _sol(x: float, z: float) -> float:
	var tr = _t
	if _rid == RID():
		for c in tr.get_children():
			if str(c.name) == "TerrainBody":
				_rid = (c as StaticBody3D).get_rid()
	var space: PhysicsDirectSpaceState3D = tr.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus, z), Vector3(x, _sus - 1200.0, z))
	q.collide_with_areas = false
	var hit: Dictionary = space.intersect_ray(q)
	var guard := 0
	while not hit.is_empty() and hit["rid"] != _rid and guard < 24:
		q.exclude = q.exclude + [hit["rid"]]
		hit = space.intersect_ray(q)
		guard += 1
	if not hit.is_empty() and hit["rid"] == _rid:
		return float(hit["position"].y)
	return -999.0
