extends Node
## Candidatii de soclu pentru pinten, evaluati pe TOATE cele patru criterii
## deodata, fiindca separat fiecare minte:
##   1. TEREN SOLID sub soclu (raycast doar pe TerrainBody)
##   2. distanta de la ochiul capturii 0,2400
##   3. pozitia pe ECRAN (criticul a cerut dreapta = semn +1)
##   4. inaltimea necesara ca varful sa fie 3 grade peste orizontala
## Plus: cu ce inaltime varful ajunge la un procent dat din cadru.

const D := 12.5
const H := 10.0
const LA := 5.0
const LH := 0.40
const FOV := 68.0
const ASPECT := 1280.0 / 720.0

var _track: Node
var _rid: RID

func _ready() -> void:
	var ps := load("res://scenes/tracks/Track15.tscn") as PackedScene
	_track = ps.instantiate()
	add_child(_track)
	await get_tree().process_frame
	for c in _track.get_children():
		if str(c.name) == "TerrainBody":
			_rid = (c as StaticBody3D).get_rid()
	var n: int = _track.baked.size()
	var ci := int(0.2400 * float(n)) % n
	var focus: Vector3 = _track.baked[ci]
	var dir := ((_track.baked[(ci + 12) % n] as Vector3) - focus).normalized()
	var eye := focus - dir * D + Vector3.UP * H
	var look := focus + dir * LA + Vector3.UP * LH
	var fwd := (look - eye).normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd).normalized()
	print("; ochi (%.1f, %.1f, %.1f)" % [eye.x, eye.y, eye.z])
	print("; frac  semn  off  y_teren  dy_drum  dist  ecranX%  H_3grade  |  varf la H=16m: ecranY%")
	var f := 0.242
	while f <= 0.268:
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var s: Vector3 = _track._side_at(i)
		var half: float = _track.width_at_index(i)
		for sg: float in [-1.0, 1.0]:
			for off: float in [-3.0, -2.0, -1.0]:
				var q: Vector3 = p + s * sg * (half + off)
				var gy := _sol(q.x, q.z)
				if gy < -900.0:
					continue
				if p.y - gy > 3.0:
					continue   # nu e soclu, e perete
				var base := Vector3(q.x, gy, q.z)
				var d := eye.distance_to(base)
				var v := base - eye
				var z := v.dot(fwd)
				if z < 0.5:
					continue
				var ex := (v.dot(right) / z / (tan(deg_to_rad(FOV * 0.5)) * ASPECT) + 1.0) * 50.0
				var horiz := Vector2(q.x - eye.x, q.z - eye.z).length()
				var h3 := eye.y + horiz * tan(deg_to_rad(3.0)) - gy
				var tip := Vector3(q.x, gy + 16.0, q.z) - eye
				var tz := tip.dot(fwd)
				var ey := (1.0 - (tip.dot(up) / tz) / tan(deg_to_rad(FOV * 0.5))) * 50.0
				print("; %.4f  %+2.0f  %4.1f  %7.2f  %+6.2f  %5.1f   %5.1f    %5.1f      %5.1f" % [
					f, sg, off, gy, gy - p.y, d, ex, h3, ey])
		f += 0.0027
	get_tree().quit(0)

func _sol(x: float, z: float) -> float:
	var space := (_track as Node3D).get_world_3d().direct_space_state
	var par := PhysicsRayQueryParameters3D.create(Vector3(x, 400.0, z), Vector3(x, -600.0, z))
	par.collide_with_areas = false
	par.exclude = []
	var hit := space.intersect_ray(par)
	var g := 0
	while not hit.is_empty() and hit["rid"] != _rid and g < 24:
		par.exclude = par.exclude + [hit["rid"]]
		hit = space.intersect_ray(par)
		g += 1
	return -999.0 if hit.is_empty() else (hit["position"] as Vector3).y
