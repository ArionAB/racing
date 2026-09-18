extends Node
## Unde se poate ASEZA un pinten inalt (stanca + condor) ca sa cada in cadrul
## capturii de la 0.24, pe partea faleza, la 15-30 m in fata camerei.
##
## Cere: teren solid sub piesa (nu podeaua rapei), pozitie DINCOLO de banda
## (ProbeLaneClear) si varf peste cota ochiului camerei.

const D := 12.5
const H := 10.0
const LA := 5.0
const LH := 0.40

var _track: Node

func _ready() -> void:
	var ps := load("res://scenes/tracks/Track15.tscn") as PackedScene
	_track = ps.instantiate()
	add_child(_track)
	await get_tree().process_frame
	var n: int = _track.baked.size()
	# camera pentru captura 0.24 (fractia judecata)
	for cf: float in [0.2400]:
		var ci := int(cf * float(n)) % n
		var focus: Vector3 = _track.baked[ci]
		var ahead: Vector3 = _track.baked[(ci + 12) % n]
		var dir := (ahead - focus).normalized()
		var eye := focus - dir * D + Vector3.UP * H
		print("\n; ===== captura %.4f, ochi (%.1f, %.1f, %.1f) =====" % [cf, eye.x, eye.y, eye.z])
		print("; frac  dist  parte  off  y_sol  dy_drum  H_pt_ochi  H_pt_3grade")
		var k := 6
		while k <= 40:
			var j := (ci + k) % n
			var p: Vector3 = _track.baked[j]
			var s: Vector3 = _track._side_at(j)
			var half: float = _track.width_at_index(j)
			for sg: float in [-1.0, 1.0]:
				for off: float in [-2.0, 0.0, 1.0]:
					var q: Vector3 = p + s * sg * (half + off)
					var gy := _sol(q.x, q.z)
					var d := eye.distance_to(Vector3(q.x, gy, q.z))
					if d > 60.0:
						continue
					var horiz := Vector2(q.x - eye.x, q.z - eye.z).length()
					var h_eye := eye.y - gy
					var h3 := eye.y + horiz * tan(deg_to_rad(3.0)) - gy
					print("; %.4f %5.1f  %+2.0f  %4.1f  %7.2f  %+6.2f   %5.1f   %5.1f" % [
						float(j) / float(n), d, sg, off, gy, gy - p.y, h_eye, h3])
			k += 6
	get_tree().quit(0)

## TERENUL, nu prima coliziune: umarul de la +1 m dincolo de muchie e dala de
## drum, nu sol. Vezi probe_mp_c_lip.gd.
var _rid: RID

func _sol(x: float, z: float) -> float:
	if _rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_rid = (c as StaticBody3D).get_rid()
	var space := (_track as Node3D).get_world_3d().direct_space_state
	var par := PhysicsRayQueryParameters3D.create(
		Vector3(x, 400.0, z), Vector3(x, -600.0, z))
	par.collide_with_areas = false
	par.exclude = []
	var hit := space.intersect_ray(par)
	var g := 0
	while not hit.is_empty() and hit["rid"] != _rid and g < 24:
		par.exclude = par.exclude + [hit["rid"]]
		hit = space.intersect_ray(par)
		g += 1
	if hit.is_empty():
		return -999.0
	return (hit["position"] as Vector3).y
