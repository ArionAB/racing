extends Node
## Cat de APROAPE de DRUM ajunge panza malului opus?
##
## Capturile de la 0.196 arata peretele lipit de bot, la orice offset lateral
## (46 sau 78 m) — semn ca punctul de sprijin al unei coloane cade langa ALT
## tronson al pistei, nu doar in vale. Cornisa e o serpentina: lateralul de la
## o fractie trece peste drumul de la alta fractie.
##
## Sonda ia fiecare vertex al panzei si masoara distanta 2D pana la cel mai
## apropiat punct de traseu — orice sub (half_width + margine) e panza IN drum.

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	var root := _track.find_child("CliffFaces", true, false)
	var route := _track.route_at(0)
	var n := route.count()
	for ch in root.get_children():
		var mi := ch as MeshInstance3D
		if mi == null:
			continue
		var arrs: Array = (mi.mesh as ArrayMesh).surface_get_arrays(0)
		var vs: PackedVector3Array = arrs[Mesh.ARRAY_VERTEX]
		var worst := 1e9
		var worst_frac := 0.0
		var worst_y := 0.0
		var road_y := 0.0
		var bad := 0
		for k in vs.size():
			var w: Vector3 = mi.global_transform * vs[k]
			var bd := 1e9
			var bi := 0
			for i in n:
				var pp := _track.point_at(i)
				var d2 := (pp.x - w.x) * (pp.x - w.x) + (pp.z - w.z) * (pp.z - w.z)
				if d2 < bd:
					bd = d2
					bi = i
			var d := sqrt(bd)
			var ry := _track.point_at(bi).y
			# conteaza doar ce e la INALTIMEA masinii (sub 6 m peste asfalt)
			if w.y < ry - 4.0 or w.y > ry + 6.0:
				continue
			if d < 9.0:
				bad += 1
			if d < worst:
				worst = d
				worst_frac = float(bi) / float(n)
				worst_y = w.y
				road_y = ry
		print("%-34s  cel mai aproape de ax: %.1f m (frac %.3f, y=%.1f vs drum %.1f)  vertecsi in gabarit: %d"
			% [mi.name, worst, worst_frac, worst_y, road_y, bad])
	get_tree().quit(0)
