extends Node
## CAT DIN CADRU umple peretele, si TAIE el orizontul PE ECRAN?
##
## Sondele de pana acum au masurat unghiuri fata de directia de MERS. Camera de
## captura insa nu se uita pe directia de mers: ia punctul de la 12 indici in
## fata (`snapshot.gd`), deci in serpentina cadrul e rotit fata de tangenta. De-aia
## o masuratoare care spunea "15 din 15 azimuturi taie orizontul" putea sa stea
## langa o captura cu dreapta goala: masurau doua directii diferite.
##
## Aici se reproduce EXACT camera din --driver (aceeasi pozitie, acelasi look_at,
## acelasi fov), se trag raze prin grila de pixeli si se raporteaza, pe jumatatea
## DREAPTA a cadrului si peste linia orizontului, cate raze lovesc geometrie.
## Linia orizontului = randul de pixeli unde raza e orizontala.

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const FRACS: Array[float] = [0.20, 0.28, 0.32]
const W: int = 64
const H: int = 36
const REACH: float = 400.0
const CAM_H: float = 2.2
const DIST: float = 7.5
const LOOK_AHEAD: float = 14.0
const LOOK_H: float = 1.6
const FOV: float = 70.0

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("=== CADRUL DE SOFER: ce e pe dreapta, peste orizont ===")
	for f in FRACS:
		_frame(f)
	get_tree().quit(0)


func _names() -> PackedStringArray:
	var out := PackedStringArray()
	var root := _track.find_child("CliffFaces", true, false)
	if root == null:
		return out
	for ch in root.get_children():
		var mi := ch as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		out.append(mi.name)
	return out


func _tris() -> Array[PackedVector3Array]:
	var out: Array[PackedVector3Array] = []
	var root := _track.find_child("CliffFaces", true, false)
	if root == null:
		return out
	for ch in root.get_children():
		var mi := ch as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf := mi.global_transform
		var arrs: Array = (mi.mesh as ArrayMesh).surface_get_arrays(0)
		var vs: PackedVector3Array = arrs[Mesh.ARRAY_VERTEX]
		var t := PackedVector3Array()
		for k in vs.size():
			t.append(xf * vs[k])
		out.append(t)
	return out


func _frame(frac: float) -> void:
	var route := _track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var idx := int(frac * float(n)) % n
	var focus: Vector3 = pts[idx]
	var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
	var dir := (ahead - focus).normalized()
	var eye := focus - dir * DIST + Vector3.UP * CAM_H
	var target := focus + dir * LOOK_AHEAD + Vector3.UP * LOOK_H
	var fwd := (target - eye).normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd).normalized()
	var tris := _tris()
	var names := _names()
	var per := {}
	for nm in names:
		per[nm] = 0
	var aspect := float(W) / float(H)
	var th := tan(deg_to_rad(FOV) * 0.5)
	var hit_r := 0
	var tot_r := 0
	var hit_sky_r := 0
	var tot_sky_r := 0
	for py in H:
		for px in W:
			var sx := (float(px) + 0.5) / float(W) * 2.0 - 1.0
			var sy := 1.0 - (float(py) + 0.5) / float(H) * 2.0
			var d := (fwd + right * (sx * th * aspect) + up * (sy * th)).normalized()
			var is_right := sx > 0.0
			# "peste orizont" = raza urca (componenta verticala pozitiva)
			var above := d.y > 0.0
			if not is_right:
				continue
			tot_r += 1
			var who := -1
			var h := _hit_who(tris, eye, d)
			who = int(h.y)
			if h.x > 0.0:
				hit_r += 1
			if above:
				tot_sky_r += 1
				if h.x > 0.0:
					hit_sky_r += 1
					if who >= 0 and who < names.size():
						per[names[who]] = int(per[names[who]]) + 1
	print("  frac %.2f: dreapta cadrului %d/%d raze pe stanca (%.0f%%) | PESTE ORIZONT %d/%d (%.0f%%)"
		% [frac, hit_r, tot_r, 100.0 * float(hit_r) / float(maxi(tot_r, 1)),
		hit_sky_r, tot_sky_r, 100.0 * float(hit_sky_r) / float(maxi(tot_sky_r, 1))])
	for nm in names:
		if int(per[nm]) > 0:
			print("        peste orizont, din care %-40s %d raze (%.0f%% din cadru sus)"
				% [nm, int(per[nm]), 100.0 * float(per[nm]) / float(maxi(tot_sky_r, 1))])


## x = distanta, y = indicele panzei lovite (-1 = nimic)
func _hit_who(tris: Array[PackedVector3Array], from: Vector3, dir: Vector3) -> Vector2:
	var best := -1.0
	var who := -1
	var ti := 0
	for t in tris:
		var i := 0
		while i + 2 < t.size():
			var r = Geometry3D.ray_intersects_triangle(from, dir, t[i], t[i + 1], t[i + 2])
			if r != null:
				var d := from.distance_to(r as Vector3)
				if d <= REACH and (best < 0.0 or d < best):
					best = d
					who = ti
			i += 3
		ti += 1
	return Vector2(best, float(who))


func _hit(tris: Array[PackedVector3Array], from: Vector3, dir: Vector3) -> float:
	var best := -1.0
	for t in tris:
		var i := 0
		while i + 2 < t.size():
			var r = Geometry3D.ray_intersects_triangle(from, dir, t[i], t[i + 1], t[i + 2])
			if r != null:
				var d := from.distance_to(r as Vector3)
				if d <= REACH and (best < 0.0 or d < best):
					best = d
			i += 3
	return best
